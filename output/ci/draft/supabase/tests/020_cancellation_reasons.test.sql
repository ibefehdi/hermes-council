-- Cancellation reasons (CONVENTIONS §3.2, §7): schema and grants,
-- the read matrix per role (tenant-scoped table, all roles with access see theirs),
-- and absence of direct-write policies (mutation through upsert RPCs only).
-- Fixtures: 000_harness.sql.
begin;
select plan(15);
select tests.seed_tenancy_matrix();

-- Schema and grants ----------------------------------------------------------------------
select ok(to_regclass('public.cancellation_reasons') is not null,
  'cancellation_reasons table exists');

select ok((select relrowsecurity from pg_class
            where oid = 'public.cancellation_reasons'::regclass),
  'RLS is enabled on cancellation_reasons');

select ok(not has_table_privilege('anon', 'public.cancellation_reasons', 'select')
      and not has_table_privilege('anon', 'public.cancellation_reasons', 'insert')
      and not has_table_privilege('anon', 'public.cancellation_reasons', 'update')
      and not has_table_privilege('anon', 'public.cancellation_reasons', 'delete'),
  'anon has no access to cancellation_reasons');

-- No direct-write policies exist on cancellation_reasons
select is_empty(
  $$select policyname from pg_policies
    where tablename = 'cancellation_reasons' and cmd IN ('INSERT', 'UPDATE', 'DELETE')$$,
  'no INSERT/UPDATE/DELETE policies on cancellation_reasons (upsert RPC only)'
);

-- Constraints ---------------------------------------------------------------------------
select ok(exists (select 1 from pg_constraint
                   where conrelid = 'public.cancellation_reasons'::regclass and contype = 'f'
                     and pg_get_constraintdef(oid) like 'FOREIGN KEY (tenant_id)%'),
  'cancellation_reasons has tenant FK');

-- Triggers ------------------------------------------------------------------------------
select ok(exists (select 1 from information_schema.triggers
                   where event_object_table = 'cancellation_reasons'
                     and trigger_name = 'audit_cancellation_reasons'),
  'cancellation_reasons has audit trigger (ADR-22)');

select ok(exists (select 1 from information_schema.triggers
                   where event_object_table = 'cancellation_reasons'
                     and trigger_name = 'set_updated_at_cancellation_reasons'),
  'cancellation_reasons has updated_at trigger');

-- Seed a fixture row for the read tests
insert into public.cancellation_reasons (tenant_id, name_en) values
  (tests.fixture('tenant_a'), 'Changed mind'),
  (tests.fixture('tenant_a'), 'Duplicate booking'),
  (tests.fixture('tenant_b'), 'Schedule conflict');

-- SELECT matrix --------------------------------------------------------------------------
-- Owner A sees only tenant A cancellation reasons.
select tests.login_as('owner_a');
select is(
  (select count(*) from public.cancellation_reasons),
  2::bigint,
  'owner_a sees 2 tenant A cancellation reasons'
);
select is_empty(
  $$select id::text from public.cancellation_reasons where tenant_id = tests.fixture('tenant_b')$$,
  'owner_a cannot see tenant B cancellation reasons'
);

-- Manager A1 sees tenant A cancellation reasons.
select tests.login_as('manager_a1');
select is(
  (select count(*) from public.cancellation_reasons),
  2::bigint,
  'manager_a1 sees tenant A cancellation reasons (tenant-scoped)'
);

-- Receptionist A1 sees tenant A cancellation reasons.
select tests.login_as('reception_a1');
select is(
  (select count(*) from public.cancellation_reasons),
  2::bigint,
  'reception_a1 sees tenant A cancellation reasons'
);

-- Staff A2 sees tenant A cancellation reasons (tenant-scoped table, all roles see theirs).
select tests.login_as('staff_a2');
select is(
  (select count(*) from public.cancellation_reasons),
  2::bigint,
  'staff_a2 sees tenant A cancellation reasons'
);

-- Owner B sees only tenant B cancellation reasons.
select tests.login_as('owner_b');
select is(
  (select count(*) from public.cancellation_reasons),
  1::bigint,
  'owner_b sees 1 tenant B cancellation reason'
);

-- Outsider sees nothing.
select tests.login_as('outsider');
select is_empty(
  $$select id::text from public.cancellation_reasons$$,
  'outsider (no memberships) sees no cancellation reasons'
);

-- Anon gets permission denied.
select tests.login_as_anon();
select throws_ok(
  $$select id::text from public.cancellation_reasons$$,
  '42501', null,
  'anon gets permission denied on cancellation_reasons'
);

select tests.logout();

select * from finish();
rollback;