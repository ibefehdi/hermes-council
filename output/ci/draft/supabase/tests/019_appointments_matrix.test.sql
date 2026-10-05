-- Appointments and appointment_items (Phase 4 pull-forward from Phase 5,
-- ADR-24, ADR-28, ADR-7, ADR-20): schema and grants, constraints,
-- the read matrix per role (owner, all-branches manager, manager of A1,
-- manager of A2, receptionist, staff, cross-tenant owner, outsider, anon),
-- and the ADR-28 absence of direct-write policies (write through RPCs only).
-- appointment_items inherits branch scope through the parent appointment.
-- Fixtures: 000_harness.sql (seed_clients_matrix creates the appointments: appt_a1
-- and appt_a4 at A2, appt_a2 at A1, appt_b1 at B1). This file adds one item per
-- appointment so the item matrix is proven with real rows.
begin;
select plan(40);
select tests.seed_tenancy_matrix();
select tests.seed_staff_matrix();
select tests.seed_clients_matrix();

create function tests.visible_appts() returns text[] language sql
as $$ select coalesce(array_agg(id::text order by scheduled_start), '{}') from public.appointments $$;

create function tests.visible_appt_items() returns text[] language sql
as $$ select coalesce(array_agg(id::text order by id), '{}') from public.appointment_items $$;

insert into public.appointment_items (id, tenant_id, appointment_id, effective_start, effective_end) values
  ('73000000-0000-0000-0000-0000000000a1', tests.fixture('tenant_a'), tests.fixture('appt_a1'),
   '2026-12-01 09:00+03', '2026-12-01 10:00+03'),
  ('73000000-0000-0000-0000-0000000000a2', tests.fixture('tenant_a'), tests.fixture('appt_a2'),
   '2026-12-01 11:00+03', '2026-12-01 12:00+03'),
  ('73000000-0000-0000-0000-0000000000a4', tests.fixture('tenant_a'), tests.fixture('appt_a4'),
   '2026-12-01 13:00+03', '2026-12-01 14:00+03'),
  ('73000000-0000-0000-0000-0000000000b1', tests.fixture('tenant_b'), tests.fixture('appt_b1'),
   '2026-12-01 09:00+03', '2026-12-01 10:00+03');

-- Schema and grants ----------------------------------------------------------------------
select ok(to_regclass('public.appointments') is not null
      and to_regclass('public.appointment_items') is not null,
  'appointments and appointment_items exist (ADR-24, ADR-7 names)');

select ok((select bool_and(relrowsecurity) from pg_class
            where oid in ('public.appointments'::regclass, 'public.appointment_items'::regclass)),
  'RLS is enabled on appointments and appointment_items');

select ok(not has_table_privilege('anon', 'public.appointments', 'select')
      and not has_table_privilege('anon', 'public.appointment_items', 'select'),
  'anon has no access to appointments or appointment_items');

-- No direct-write policies exist on appointments (ADR-28: write via Edge Function only)
select is_empty(
  $$select policyname from pg_policies
    where tablename = 'appointments' and cmd IN ('INSERT', 'UPDATE', 'DELETE')$$,
  'no INSERT/UPDATE/DELETE policies on appointments (ADR-28 direct-write prohibited)'
);

select is_empty(
  $$select policyname from pg_policies
    where tablename = 'appointment_items' and cmd IN ('INSERT', 'UPDATE', 'DELETE')$$,
  'no INSERT/UPDATE/DELETE policies on appointment_items (ADR-28)'
);

-- Constraints ---------------------------------------------------------------------------
select ok(exists (select 1 from pg_constraint
                   where conrelid = 'public.appointments'::regclass and contype = 'f'
                     and pg_get_constraintdef(oid) like 'FOREIGN KEY (tenant_id)%'),
  'appointments has tenant FK (ADR-20 rule 1)');

select ok(exists (select 1 from pg_constraint
                   where conrelid = 'public.appointments'::regclass and contype = 'f'
                     and pg_get_constraintdef(oid) like 'FOREIGN KEY (branch_id, tenant_id)%'),
  'appointments has composite branch FK (ADR-20 rule 5)');

select ok(exists (select 1 from pg_constraint
                   where conrelid = 'public.appointments'::regclass and contype = 'c'
                     and pg_get_constraintdef(oid) like '%scheduled_end > scheduled_start%'),
  'appointments has valid_range check');

select ok(exists (select 1 from pg_constraint
                   where conrelid = 'public.appointment_items'::regclass and contype = 'f'
                     and pg_get_constraintdef(oid) like 'FOREIGN KEY (appointment_id, tenant_id)%'),
  'appointment_items has composite appointment FK');

select ok(exists (select 1 from pg_constraint
                   where conrelid = 'public.appointment_items'::regclass and contype = 'c'
                     and pg_get_constraintdef(oid) like '%effective_end > effective_start%'),
  'appointment_items has valid_range check');

select ok((select is_nullable = 'YES' from information_schema.columns
            where table_schema = 'public' and table_name = 'appointments' and column_name = 'client_id'),
  'appointments.client_id is nullable (walk-ins)');

-- Triggers ------------------------------------------------------------------------------
select ok(exists (select 1 from information_schema.triggers
                   where event_object_table = 'appointments' and trigger_name = 'audit_appointments'),
  'appointments has audit trigger (ADR-22)');

select ok(exists (select 1 from information_schema.triggers
                   where event_object_table = 'appointment_items' and trigger_name = 'audit_appointment_items'),
  'appointment_items has audit trigger (ADR-22)');

select ok(exists (select 1 from information_schema.triggers
                   where event_object_table = 'appointment_items' and trigger_name = 'set_busy_range_appointment_items'),
  'appointment_items has busy_range trigger');

-- 1. Appointments SELECT matrix ---------------------------------------------------------
-- Owner A sees all A appointments (A1 and A2 branches).
select tests.login_as('owner_a');
select is(
  (select count(*) from public.appointments where tenant_id = tests.fixture('tenant_a')),
  3::bigint,
  'owner_a sees all 3 tenant A appointments'
);
select is_empty(
  $$select id::text from public.appointments where tenant_id = tests.fixture('tenant_b')$$,
  'owner_a cannot see tenant B appointments'
);

-- Manager A1 (manager of A1 only) sees A1 appointments only.
select tests.login_as('manager_a1');
select is(
  (select count(*) from public.appointments
    where tenant_id = tests.fixture('tenant_a') and branch_id = tests.fixture('branch_a1')),
  1::bigint,
  'manager_a1 sees the A1 appointment'
);
select is_empty(
  $$select id::text from public.appointments where branch_id = tests.fixture('branch_a2')$$,
  'manager_a1 cannot see A2 appointments'
);

-- Manager A2 (manager of A2 only) sees A2 appointments only.
select tests.login_as('manager_a2');
select is(
  (select count(*) from public.appointments
    where tenant_id = tests.fixture('tenant_a') and branch_id = tests.fixture('branch_a2')),
  2::bigint,
  'manager_a2 sees the A2 appointments'
);
select is_empty(
  $$select id::text from public.appointments where branch_id = tests.fixture('branch_a1')$$,
  'manager_a2 cannot see A1 appointments'
);

-- All-branches manager sees all A appointments.
select tests.login_as('manager_a_all');
select is(
  (select count(*) from public.appointments where tenant_id = tests.fixture('tenant_a')),
  3::bigint,
  'manager_a_all sees all 3 tenant A appointments'
);

-- Receptionist A1 sees A1 appointments.
select tests.login_as('reception_a1');
select is(
  (select count(*) from public.appointments
    where tenant_id = tests.fixture('tenant_a') and branch_id = tests.fixture('branch_a1')),
  1::bigint,
  'reception_a1 sees the A1 appointment (receptionist)'
);

-- Staff A2 cannot see appointments (staff role excluded from appointments RLS).
select tests.login_as('staff_a2');
select is_empty(
  $$select id::text from public.appointments$$,
  'staff_a2 sees no appointments (staff not in RLS policy)'
);

-- Owner B sees only B appointments.
select tests.login_as('owner_b');
select is(
  (select count(*) from public.appointments where tenant_id = tests.fixture('tenant_b')),
  1::bigint,
  'owner_b sees the tenant B appointment'
);
select is_empty(
  $$select id::text from public.appointments where tenant_id = tests.fixture('tenant_a')$$,
  'owner_b cannot see tenant A appointments'
);

-- Outsider sees nothing (no memberships -> no tenant scope -> RLS filters all).
select tests.login_as('outsider');
select is_empty(
  $$select id::text from public.appointments$$,
  'outsider sees no appointments'
);

-- Anon gets permission denied (no table-level grant).
select tests.login_as_anon();
select throws_ok(
  $$select id::text from public.appointments$$,
  '42501', null,
  'anon gets permission denied on appointments'
);

select tests.logout();

-- 2. Appointment_items SELECT matrix ----------------------------------------------------
-- An item is visible exactly when its appointment is (branch scope through the parent).
select tests.login_as('owner_a');
select is(tests.visible_appt_items(),
  array['73000000-0000-0000-0000-0000000000a1', '73000000-0000-0000-0000-0000000000a2',
        '73000000-0000-0000-0000-0000000000a4'],
  'owner_a sees the three tenant A items and not the tenant B item');

select tests.login_as('manager_a_all');
select is(tests.visible_appt_items(),
  array['73000000-0000-0000-0000-0000000000a1', '73000000-0000-0000-0000-0000000000a2',
        '73000000-0000-0000-0000-0000000000a4'],
  'manager_a_all sees the three tenant A items');

select tests.login_as('manager_a1');
select is(tests.visible_appt_items(), array['73000000-0000-0000-0000-0000000000a2'],
  'manager_a1 sees only the item of the A1 appointment (no cross-branch items)');

select tests.login_as('manager_a2');
select is(tests.visible_appt_items(),
  array['73000000-0000-0000-0000-0000000000a1', '73000000-0000-0000-0000-0000000000a4'],
  'manager_a2 sees only the items of the A2 appointments');

select tests.login_as('reception_a1');
select is(tests.visible_appt_items(), array['73000000-0000-0000-0000-0000000000a2'],
  'reception_a1 sees only the item of the A1 appointment');

select tests.login_as('staff_a2');
select is(tests.visible_appt_items(), '{}'::text[],
  'staff_a2 sees no items (staff cannot see appointments)');

select tests.login_as('owner_b');
select is(tests.visible_appt_items(), array['73000000-0000-0000-0000-0000000000b1'],
  'owner_b sees only the tenant B item (no cross-tenant items)');

select tests.login_as('outsider');
select is(tests.visible_appt_items(), '{}'::text[], 'outsider sees no appointment_items');

select tests.login_as_anon();
select throws_ok(
  $$select id::text from public.appointment_items$$,
  '42501', null,
  'anon gets permission denied on appointment_items'
);

select tests.logout();

-- 3. Direct write denial (integration via role switching) --------------------------------
-- Verify that INSERT is blocked by RLS for roles that would normally have create
-- authority (simulates someone trying to bypass the Edge Function).
select tests.login_as('owner_a');
select throws_ok(
  $$insert into public.appointments (tenant_id, branch_id, client_id, scheduled_start, scheduled_end)
    values (tests.fixture('tenant_a'), tests.fixture('branch_a1'), tests.fixture('client_a1'),
            '2026-12-01 09:00+03', '2026-12-01 10:00+03')$$,
  '42501', null,
  'owner_a cannot INSERT appointments directly (no INSERT policy)'
);

-- Same for appointment_items.
select tests.login_as('owner_a');
select throws_ok(
  $$insert into public.appointment_items (tenant_id, appointment_id, effective_start, effective_end)
    values (tests.fixture('tenant_a'), tests.fixture('appt_a1'),
            '2026-12-01 09:00+03', '2026-12-01 10:00+03')$$,
  '42501', null,
  'owner_a cannot INSERT appointment_items directly (no INSERT policy)'
);

-- Update denial for appointments.
select tests.login_as('owner_a');
select throws_ok(
  $$update public.appointments set notes = 'trying to bypass' where id = tests.fixture('appt_a1')$$,
  '42501', null,
  'owner_a cannot UPDATE appointments directly (no UPDATE policy)'
);

-- Delete denial for appointments.
select tests.login_as('owner_a');
select throws_ok(
  $$delete from public.appointments where id = tests.fixture('appt_a1')$$,
  '42501', null,
  'owner_a cannot DELETE appointments directly (no DELETE policy)'
);

select tests.logout();

select * from finish();
rollback;