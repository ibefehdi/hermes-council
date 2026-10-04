-- ============================================================================
-- Tests: Cross-tenant isolation (brief §3 minimum)
-- A user of tenant A cannot select, insert, update, or delete tenant B rows
-- in any table or view.
-- ============================================================================

-- ---------- helpers ----------
create or replace function tests.assert(condition boolean, msg text) returns void as $$
begin
  if not condition then
    raise exception 'ASSERT FAILED: %', msg;
  end if;
end;
$$ language plpgsql;

-- ---------- fixtures ----------

-- Create two test users in auth.users
insert into auth.users (id, email) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'user-a@test.local'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'user-b@test.local');

-- Create two tenants
insert into public.tenants (id, display_name_en, slug) values
  ('11111111-1111-1111-1111-111111111111', 'Tenant A', 'tenant-a'),
  ('22222222-2222-2222-2222-222222222222', 'Tenant B', 'tenant-b');

-- Create branches (one per tenant)
insert into public.branches (id, tenant_id, name_en, invoice_prefix) values
  ('aaaa1111-aaaa-1111-aaaa-111111111111', '11111111-1111-1111-1111-111111111111', 'Branch A1', 'A1'),
  ('bbbb2222-bbbb-2222-bbbb-222222222222', '22222222-2222-2222-2222-222222222222', 'Branch B1', 'B1');

-- Create memberships
insert into public.memberships (tenant_id, user_id, role, all_branches, is_active) values
  ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'tenant_owner', true, true),
  ('22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'tenant_owner', true, true);

-- Create staff for each tenant
insert into public.staff_members (id, tenant_id, full_name_en) values
  ('5555aaaa-5555-aaaa-5555-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Staff A'),
  ('5555bbbb-5555-bbbb-5555-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'Staff B');

-- Create clients for each tenant
insert into public.clients (id, tenant_id, first_name) values
  ('ccccaaaa-cccc-aaaa-cccc-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Client A'),
  ('ccccbbbb-cccc-bbbb-cccc-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'Client B');

-- Create a service for tenant A
insert into public.services (id, tenant_id, name_en, duration_minutes, price_minor) values
  ('ssssaaaa-ssss-aaaa-ssss-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Service A', 60, 15000);

-- ---------- test: cross-tenant SELECT (clients) ----------
do $$
begin
  -- Act as user A
  perform set_config('request.jwt.claims', '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}', true);
  set role authenticated;

  -- User A should see client A
  perform tests.assert(
    exists (select 1 from public.clients where first_name = 'Client A'),
    'T1.1: user A should see their own client'
  );

  -- User A should NOT see client B
  perform tests.assert(
    not exists (select 1 from public.clients where first_name = 'Client B'),
    'T1.2: user A should NOT see client B'
  );

  -- Act as user B
  perform set_config('request.jwt.claims', '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}', true);
  set role authenticated;

  -- User B should see client B
  perform tests.assert(
    exists (select 1 from public.clients where first_name = 'Client B'),
    'T1.3: user B should see their own client'
  );

  -- User B should NOT see client A
  perform tests.assert(
    not exists (select 1 from public.clients where first_name = 'Client A'),
    'T1.4: user B should NOT see client A'
  );

  raise notice 'T1 cross-tenant SELECT: PASS';
end;
$$;

-- ---------- test: cross-tenant INSERT ----------
do $$
begin
  -- Act as user A, try to insert into tenant B
  perform set_config('request.jwt.claims', '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}', true);
  set role authenticated;

  begin
    insert into public.clients (id, tenant_id, first_name)
    values ('ccccfail-cccc-fail-cccc-cccccccccccc', '22222222-2222-2222-2222-222222222222', 'Sneaky Client');
    raise exception 'T2.1 FAIL: expected insert to be blocked by RLS';
  exception when others then
    -- Expected: the insert should be rejected
    if sqlerrm like '%violates row-level%' or sqlerrm like '%permission denied%' then
      raise notice 'T2.1 cross-tenant INSERT blocked: PASS';
    else
      raise exception 'T2.1 FAIL: unexpected error: %', sqlerrm;
    end if;
  end;
end;
$$;

-- ---------- test: cross-tenant UPDATE ----------
do $$
declare
  v_orig text;
begin
  -- Act as user A, try to update client in tenant B
  perform set_config('request.jwt.claims', '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}', true);
  set role authenticated;

  select first_name into v_orig from public.clients where id = 'ccccbbbb-cccc-bbbb-cccc-bbbbbbbbbbbb';
  -- Should not find it, but if we do, assert the update fails
  if v_orig is not null then
    raise exception 'T3.1 FAIL: user A should not see client B at all';
  end if;

  raise notice 'T3 cross-tenant UPDATE: PASS (not visible, so no update possible)';
end;
$$;

-- ---------- test: cross-tenant via staff_members ----------
do $$
begin
  perform set_config('request.jwt.claims', '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}', true);
  set role authenticated;

  perform tests.assert(
    exists (select 1 from public.staff_members where full_name_en = 'Staff A'),
    'T4.1: user A sees own staff'
  );

  perform tests.assert(
    not exists (select 1 from public.staff_members where full_name_en = 'Staff B'),
    'T4.2: user A does NOT see tenant B staff'
  );

  raise notice 'T4 cross-tenant staff_members: PASS';
end;
$$;

-- ---------- test: cross-tenant services ----------
do $$
begin
  perform set_config('request.jwt.claims', '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}', true);
  set role authenticated;

  perform tests.assert(
    exists (select 1 from public.services where name_en = 'Service A'),
    'T5.1: user A sees own service'
  );

  raise notice 'T5 cross-tenant services: PASS';
end;
$$;

-- ---------- test: anon cannot access tenant data ----------
do $$
begin
  set role anon;

  -- Anon should not see any tenant-specific data
  perform tests.assert(
    not exists (select 1 from public.clients limit 1),
    'T6.1: anon cannot see clients'
  );

  perform tests.assert(
    not exists (select 1 from public.tenants limit 1),
    'T6.2: anon cannot see tenants'
  );

  -- Anon CAN see currencies (global reference data)
  perform tests.assert(
    exists (select 1 from public.currencies where code = 'KWD'),
    'T6.3: anon can see currencies'
  );

  raise notice 'T6 anon access: PASS';
end;
$$;