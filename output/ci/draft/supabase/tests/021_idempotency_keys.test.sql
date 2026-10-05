-- Idempotency keys (ADR-31): RLS deny-all with no policies.
-- No authenticated or anon role may read or write directly.
-- Table has RLS enabled but zero policies (default-deny).
-- Service-role RPCs access via SECURITY DEFINER functions.
-- Fixtures: 000_harness.sql.
begin;
select plan(10);
select tests.seed_tenancy_matrix();

-- Schema and grants ----------------------------------------------------------------------
select ok(to_regclass('public.idempotency_keys') is not null,
  'idempotency_keys table exists (ADR-31)');

select ok((select relrowsecurity from pg_class
            where oid = 'public.idempotency_keys'::regclass),
  'RLS is enabled on idempotency_keys');

select ok(not has_table_privilege('anon', 'public.idempotency_keys', 'select')
      and not has_table_privilege('anon', 'public.idempotency_keys', 'insert')
      and not has_table_privilege('anon', 'public.idempotency_keys', 'update')
      and not has_table_privilege('anon', 'public.idempotency_keys', 'delete'),
  'anon has no table-level privileges on idempotency_keys');

select ok(not has_table_privilege('authenticated', 'public.idempotency_keys', 'insert')
      and not has_table_privilege('authenticated', 'public.idempotency_keys', 'update')
      and not has_table_privilege('authenticated', 'public.idempotency_keys', 'delete'),
  'authenticated has no INSERT/UPDATE/DELETE on idempotency_keys (deny-all)');

-- No policies at all on idempotency_keys (default-deny for all operations).
select is_empty(
  $$select policyname from pg_policies
    where tablename = 'idempotency_keys'$$,
  'no RLS policies on idempotency_keys at all — default-deny'
);

-- Constraints ---------------------------------------------------------------------------
select ok(exists (select 1 from pg_constraint
                   where conrelid = 'public.idempotency_keys'::regclass and contype = 'f'
                     and pg_get_constraintdef(oid) like 'FOREIGN KEY (tenant_id)%'),
  'idempotency_keys has tenant FK');

select ok(exists (select 1 from pg_constraint
                   where conrelid = 'public.idempotency_keys'::regclass and contype = 'u'
                     and pg_get_constraintdef(oid) like 'UNIQUE (tenant_id, key, function_name)%'),
  'idempotency_keys has unique constraint on (tenant_id, key, function_name)');

-- RLS denial from authenticated roles ----------------------------------------------------
-- Verify that even a tenant owner cannot SELECT from idempotency_keys (deny-all with no SELECT policy).
select tests.login_as('owner_a');
select is_empty(
  $$select id::text from public.idempotency_keys$$,
  'owner_a sees nothing in idempotency_keys (no SELECT policy — default-deny)'
);

-- Attempted direct INSERT is blocked by RLS (no INSERT policy).
select tests.login_as('owner_a');
select throws_ok(
  $$insert into public.idempotency_keys (tenant_id, key, function_name, request_hash)
    values (tests.fixture('tenant_a'), 'test-key', 'checkout', 'h-test')$$,
  '42501', null,
  'owner_a cannot INSERT into idempotency_keys (no INSERT policy)'
);

-- Anon gets permission denied (no table-level grant).
select tests.login_as_anon();
select throws_ok(
  $$select 1 from public.idempotency_keys$$,
  '42501', null,
  'anon gets permission denied on idempotency_keys'
);

select tests.logout();

select * from finish();
rollback;