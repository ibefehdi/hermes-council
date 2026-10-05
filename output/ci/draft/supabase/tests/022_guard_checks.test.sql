-- Structural guard tests: catalog-level invariants that fail when a future
-- migration breaks a rule. Each check must pass at 07e2a1052 or be
-- KNOWN-FAILING with a real defect behind it.
--
-- Covers: ADR-20 rule 10 (SECURITY DEFINER search_path + anon-exec),
-- ADR-20 rule 6 (all-branches no-sentinel-UUID), ADR-21 (security_invoker views),
-- ADR-17 (money columns), ADR-28 (direct-write allowlist), ADR-22 (audit),
-- CONVENTIONS §7 (pgTAP structural checks), CONVENTIONS §3.2 (RLS per table).
--
-- Allowlist for SECURITY DEFINER functions executable by anon/public:
-- (none expected — all 70 definer functions in public have search_path=public
--  and are not executable by anon or public. Extension functions in net,
--  supabase_functions schemas are not in the public schema.)
begin;
select plan(30);

-- =========================================================================
-- 1. RLS is enabled on every public table (CONVENTIONS §3.2)
-- =========================================================================
select is_empty(
  $$select tablename from pg_tables where schemaname = 'public' and not rowsecurity$$,
  'RLS is enabled on every public table'
);

-- =========================================================================
-- 2. No anon/authenticated table-level grants for write operations
--    on tables that are NOT in the ADR-28 direct-write allowlist.
--    (G-14: Direct-write allowlist enforcement)
-- =========================================================================
-- Tables that MAY have direct INSERT/UPDATE/DELETE per ADR-28:
-- These are tenant-scoped tables where the RLS policy gates the operation.
create function tests.allowlist_direct_write() returns text[] language sql
as $$
  -- Tables where authenticated has direct INSERT/UPDATE/DELETE policies
  select array_agg(distinct tablename order by tablename)
  from pg_policies
  where schemaname = 'public' and cmd IN ('INSERT', 'UPDATE', 'DELETE')
$$;

-- Verify that every table WITH a write policy is in the expected set.
-- Write-policy tables as of commit 07e2a1052:
-- clients, client_notes, service_categories, settings, shifts
select ok(
  (select tests.allowlist_direct_write() @> array['clients', 'client_notes', 'profiles', 'service_categories', 'settings', 'shifts']
   and cardinality(tests.allowlist_direct_write()) = 6),
  'direct-write tables match ADR-28 allowlist (clients, client_notes, profiles, service_categories, settings, shifts)'
);

-- =========================================================================
-- 3. SECURITY DEFINER functions: search_path and anon/public executability
--    (ADR-20 rule 10, G-5)
-- =========================================================================
-- 3a. Every SECURITY DEFINER function in public has SET search_path.
select is_empty(
  $$select p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.prosecdef
      and not exists (select 1 from unnest(p.proconfig) c where c like 'search_path=%')$$,
  'every SECURITY DEFINER function in public pins search_path (ADR-20 rule 10)'
);

-- 3b. No SECURITY DEFINER function in public is executable by anon.
select ok(
  (select count(*) = 0 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.prosecdef
      and has_function_privilege('anon', p.oid, 'EXECUTE')),
  'no SECURITY DEFINER function in public is executable by anon (G-5)'
);

-- 3c. No SECURITY DEFINER function in public is executable by PUBLIC.
select ok(
  (select count(*) = 0 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.prosecdef
      and has_function_privilege('public', p.oid, 'EXECUTE')),
  'no SECURITY DEFINER function in public is executable by PUBLIC (G-5)'
);

-- =========================================================================
-- 4. Views have security_invoker (ADR-21)
-- =========================================================================
select ok(
  (select count(*) = (select count(*) from pg_class
     where relnamespace = 'public'::regnamespace and relkind = 'v')
   from pg_class where relnamespace = 'public'::regnamespace and relkind = 'v'
     and reloptions @> '{security_invoker=true}'),
  'all views use security_invoker (ADR-21)'
);

-- =========================================================================
-- 5. Money columns are bigint and named ..._minor (ADR-17)
-- =========================================================================
select is_empty(
  $$select c.table_name || '.' || c.column_name
    from information_schema.columns c
    where c.table_schema = 'public'
      and c.data_type in ('real', 'double precision', 'money')$$,
  'no real, double precision or money columns in public tables (ADR-17)'
);

-- Every ..._minor column is bigint.
select is_empty(
  $$select c.table_name || '.' || c.column_name
    from information_schema.columns c
    where c.table_schema = 'public'
      and (c.column_name like '%_minor' or c.column_name like '%minor')
      and c.data_type <> 'bigint'$$,
  'every _minor column is bigint (ADR-17)'
);

-- =========================================================================
-- 6. Every tenant-scoped table has a non-null tenant_id (CONVENTIONS §3.2)
-- =========================================================================
-- Query information_schema for tables with tenant_id and assert NO-NULL.
-- Tenant-scoped tables (29 tables) have tenant_id = not nullable.
select is_empty(
  $$select c.table_name from information_schema.columns c
    join information_schema.tables t
      on t.table_schema = c.table_schema and t.table_name = c.table_name
    where c.table_schema = 'public'
      and c.column_name = 'tenant_id'
      and c.is_nullable = 'YES'
      and t.table_type = 'BASE TABLE'$$,
  'every table with a tenant_id column declares it NOT NULL'
);

-- =========================================================================
-- 7. No all-branches sentinel UUID in any branch_id column (ADR-20 rule 6, G-25)
-- =========================================================================
-- Check that no branch_id in the database uses the null-UUID sentinel pattern.
-- The sentinel UUID '00000000-0000-0000-0000-000000000000' must NOT appear.
do $$ declare
  r record;
  cnt bigint;
  errors text[] := '{}';
begin
  for r in select c.table_name, c.column_name
           from information_schema.columns c
           where c.table_schema = 'public'
             and c.column_name = 'branch_id'
             and c.data_type = 'uuid'
  loop
    execute format('select count(*) from public.%I where %I = ''00000000-0000-0000-0000-000000000000''',
                   r.table_name, r.column_name) into cnt;
    if cnt > 0 then
      errors := errors || format('%I.%I: %s rows', r.table_name, r.column_name, cnt);
    end if;
  end loop;
  if cardinality(errors) > 0 then
    raise exception 'Sentinel UUID found: %', array_to_string(errors, '; ');
  end if;
end $$;
select ok(true, 'no branch_id column uses the sentinel UUID (G-25, ADR-20 rule 6)');

-- =========================================================================
-- 8. Audit triggers exist on tables expected to be audited (ADR-22)
-- =========================================================================
-- Tables that should have audit triggers per the plan:
-- All patient/mutation tables. Query triggers dynamically.
select ok(
  (select count(*) >= 1 from information_schema.triggers
    where trigger_schema = 'public'
      and trigger_name like 'audit_%'
      and event_object_table = 'appointments'),
  'appointments has audit trigger (ADR-22)'
);

select ok(
  (select count(*) >= 1 from information_schema.triggers
    where trigger_schema = 'public'
      and trigger_name like 'audit_%'
      and event_object_table = 'appointment_items'),
  'appointment_items has audit trigger (ADR-22)'
);

select ok(
  (select count(*) >= 1 from information_schema.triggers
    where trigger_schema = 'public'
      and trigger_name like 'audit_%'
      and event_object_table = 'cancellation_reasons'),
  'cancellation_reasons has audit trigger (ADR-22)'
);

select ok(
  (select count(*) >= 1 from information_schema.triggers
    where trigger_schema = 'public'
      and trigger_name like 'audit_%'
      and event_object_table = 'clients'),
  'clients has audit trigger (ADR-22)'
);

select ok(
  (select count(*) >= 1 from information_schema.triggers
    where trigger_schema = 'public'
      and trigger_name like 'audit_%'
      and event_object_table = 'client_notes'),
  'client_notes has audit trigger (ADR-22)'
);

select ok(
  (select count(*) >= 1 from information_schema.triggers
    where trigger_schema = 'public'
      and trigger_name like 'audit_%'
      and event_object_table = 'memberships'),
  'memberships has audit trigger (ADR-22)'
);

select ok(
  (select count(*) >= 1 from information_schema.triggers
    where trigger_schema = 'public'
      and trigger_name like 'audit_%'
      and event_object_table = 'settings'),
  'settings has audit trigger (ADR-22)'
);

select ok(
  (select count(*) >= 1 from information_schema.triggers
    where trigger_schema = 'public'
      and trigger_name like 'audit_%'
      and event_object_table = 'shifts'),
  'shifts has audit trigger (ADR-22)'
);

select ok(
  (select count(*) >= 1 from information_schema.triggers
    where trigger_schema = 'public'
      and trigger_name like 'audit_%'
      and event_object_table = 'appointments'),
  'appointments has audit trigger (ADR-22)'
);

select ok(
  (select count(*) >= 1 from information_schema.triggers
    where trigger_schema = 'public'
      and trigger_name like 'audit_%'
      and event_object_table = 'blocked_times'),
  'blocked_times has audit trigger (ADR-22)'
);

-- =========================================================================
-- 9. Updated-at triggers on tables with mutable data
-- =========================================================================
select ok(exists (select 1 from information_schema.triggers
    where event_object_table = 'appointments' and trigger_name = 'set_updated_at_appointments'),
  'appointments has updated_at trigger');

select ok(exists (select 1 from information_schema.triggers
    where event_object_table = 'appointment_items' and trigger_name = 'set_updated_at_appointment_items'),
  'appointment_items has updated_at trigger');

select ok(exists (select 1 from information_schema.triggers
    where event_object_table = 'cancellation_reasons' and trigger_name = 'set_updated_at_cancellation_reasons'),
  'cancellation_reasons has updated_at trigger');

select ok(exists (select 1 from information_schema.triggers
    where event_object_table = 'idempotency_keys' and trigger_name = 'set_updated_at_idempotency_keys'),
  'idempotency_keys has updated_at trigger');

-- =========================================================================
-- 10. Composite FK with tenant_id on tenant-scoped tables (ADR-20 rule 5)
-- =========================================================================
select ok(exists (select 1 from pg_constraint
    where conrelid = 'public.appointments'::regclass and contype = 'f'
      and pg_get_constraintdef(oid) like '%FOREIGN KEY (branch_id, tenant_id)%'),
  'appointments has composite FK (branch_id, tenant_id) (ADR-20 rule 5)');

select ok(exists (select 1 from pg_constraint
    where conrelid = 'public.appointment_items'::regclass and contype = 'f'
      and pg_get_constraintdef(oid) like '%FOREIGN KEY (appointment_id, tenant_id)%'),
  'appointment_items has composite FK (appointment_id, tenant_id) (ADR-20 rule 5)');

select ok(exists (select 1 from pg_constraint
    where conrelid = 'public.client_notes'::regclass and contype = 'f'
      and pg_get_constraintdef(oid) like '%FOREIGN KEY (client_id, tenant_id)%'),
  'client_notes has composite FK (client_id, tenant_id) (ADR-20 rule 5)');

select ok(exists (select 1 from pg_constraint
    where conrelid = 'public.appointments'::regclass and contype = 'f'
      and pg_get_constraintdef(oid) like '%FOREIGN KEY (client_id, tenant_id)%'),
  'appointments has composite FK (client_id, tenant_id) (ADR-20 rule 5)');

-- =========================================================================
-- 11. Exclusion constraint on appointment_items for staff overlap prevention
-- =========================================================================
select ok(exists (select 1 from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    join pg_index i on i.indrelid = c.oid
    where n.nspname = 'public' and c.relname = 'appointment_items'
      and i.indisexclusion),
  'appointment_items has exclusion constraint for staff no-overlap (ADR-24)');

-- =========================================================================
-- 12. Appointments status check constraint exists
-- =========================================================================
select ok(exists (select 1 from pg_constraint
    where conrelid = 'public.appointments'::regclass and contype = 'c'
      and pg_get_constraintdef(oid) like '%status%'),
  'appointments has status check constraint (ADR-7)');

select * from finish();
rollback;