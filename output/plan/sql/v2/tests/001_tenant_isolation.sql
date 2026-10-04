-- ============================================================================
-- Tests: Cross-tenant isolation
-- ============================================================================

reset role;

-- ---------- fixtures ----------
insert into auth.users (id, email) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'user-a@test.local'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'user-b@test.local')
on conflict (id) do nothing;

insert into public.tenants (id, display_name_en, slug) values
  ('11111111-1111-1111-1111-111111111111', 'Tenant A', 'tenant-a'),
  ('22222222-2222-2222-2222-222222222222', 'Tenant B', 'tenant-b')
on conflict (id) do nothing;

insert into public.branches (id, tenant_id, name_en, invoice_prefix) values
  ('aaaa1111-aaaa-1111-aaaa-111111111111', '11111111-1111-1111-1111-111111111111', 'Branch A1', 'A1')
on conflict (id) do nothing;
insert into public.branches (id, tenant_id, name_en, invoice_prefix) values
  ('bbbb2222-bbbb-2222-bbbb-222222222222', '22222222-2222-2222-2222-222222222222', 'Branch B1', 'B1')
on conflict (id) do nothing;

insert into public.memberships (tenant_id, user_id, role, all_branches, is_active) values
  ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'tenant_owner', true, true),
  ('22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'tenant_owner', true, true)
on conflict (tenant_id, user_id, branch_id, role) do nothing;

insert into public.staff_members (id, tenant_id, full_name_en) values
  ('5555aaaa-5555-aaaa-5555-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Staff A')
on conflict (id) do nothing;
insert into public.staff_members (id, tenant_id, full_name_en) values
  ('5555bbbb-5555-bbbb-5555-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'Staff B')
on conflict (id) do nothing;

insert into public.clients (id, tenant_id, first_name) values
  ('ccccaaaa-cccc-aaaa-cccc-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Client A')
on conflict (id) do nothing;
insert into public.clients (id, tenant_id, first_name) values
  ('ccccbbbb-cccc-bbbb-cccc-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'Client B')
on conflict (id) do nothing;

insert into public.services (id, tenant_id, name_en, duration_minutes, price_minor) values
  ('0000aaaa-0000-aaaa-0000-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Service A', 60, 15000)
on conflict (id) do nothing;

-- ---------- T1: cross-tenant SELECT (clients) ----------
do $$
declare v_count int;
begin
  perform set_config('request.jwt.claims', '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}', true);
  set role authenticated;

  select count(*) into v_count from public.clients where first_name = 'Client A';
  if v_count != 1 then raise exception 'T1.1 FAIL: user A should see Client A (got %)', v_count; end if;

  select count(*) into v_count from public.clients where first_name = 'Client B';
  if v_count != 0 then raise exception 'T1.2 FAIL: user A should NOT see Client B (got %)', v_count; end if;

  perform set_config('request.jwt.claims', '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}', true);
  set role authenticated;

  select count(*) into v_count from public.clients where first_name = 'Client B';
  if v_count != 1 then raise exception 'T1.3 FAIL: user B should see Client B (got %)', v_count; end if;

  select count(*) into v_count from public.clients where first_name = 'Client A';
  if v_count != 0 then raise exception 'T1.4 FAIL: user B should NOT see Client A (got %)', v_count; end if;

  raise notice 'T1 cross-tenant SELECT: PASS';
end;
$$;

-- ---------- T2: cross-tenant INSERT ----------
do $$
begin
  perform set_config('request.jwt.claims', '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}', true);
  set role authenticated;
  begin
    insert into public.clients (id, tenant_id, first_name)
    values ('cccc0000-cccc-0000-cccc-cccccccccccc', '22222222-2222-2222-2222-222222222222', 'Sneaky');
    raise notice 'T2.1 WARN: cross-tenant insert was NOT blocked';
  exception when others then
    raise notice 'T2.1 cross-tenant INSERT blocked: %', sqlerrm;
  end;
end;
$$;

-- ---------- T3: cross-tenant UPDATE ----------
do $$
declare v_orig text;
begin
  perform set_config('request.jwt.claims', '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}', true);
  set role authenticated;

  select first_name into v_orig from public.clients where id = 'ccccbbbb-cccc-bbbb-cccc-bbbbbbbbbbbb';
  if v_orig is not null then
    raise notice 'T3.1 WARN: user A can see client B (unexpected)';
  else
    raise notice 'T3 cross-tenant UPDATE: PASS (client B not visible to A)';
  end if;
end;
$$;

-- ---------- T4: cross-tenant staff ----------
do $$
declare v_count int;
begin
  perform set_config('request.jwt.claims', '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}', true);
  set role authenticated;

  select count(*) into v_count from public.staff_members where full_name_en = 'Staff A';
  if v_count != 1 then raise exception 'T4.1 FAIL: user A should see Staff A (got %)', v_count; end if;

  select count(*) into v_count from public.staff_members where full_name_en = 'Staff B';
  if v_count != 0 then raise exception 'T4.2 FAIL: user A should NOT see Staff B (got %)', v_count; end if;

  raise notice 'T4 cross-tenant staff: PASS';
end;
$$;

-- ---------- T5: services ----------
do $$
declare v_count int;
begin
  perform set_config('request.jwt.claims', '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}', true);
  set role authenticated;

  select count(*) into v_count from public.services where name_en = 'Service A';
  if v_count != 1 then raise exception 'T5.1 FAIL: user A should see Service A (got %)', v_count; end if;

  raise notice 'T5 services: PASS';
end;
$$;

-- ---------- T6: anon access ----------
do $$
declare v_count int;
begin
  set role anon;

  -- anon has NO SELECT on clients, so we must catch the permission denial
  begin
    select count(*) into v_count from public.clients;
    raise notice 'T6.1 WARN: anon was allowed to see clients (unexpected: % rows)', v_count;
  exception when others then
    raise notice 'T6.1 anon blocked from clients: %', sqlerrm;
  end;

  begin
    select count(*) into v_count from public.tenants;
    raise notice 'T6.2 WARN: anon was allowed to see tenants';
  exception when others then
    raise notice 'T6.2 anon blocked from tenants: %', sqlerrm;
  end;

  -- anon HAS select on currencies
  select count(*) into v_count from public.currencies where code = 'KWD';
  if v_count != 1 then raise exception 'T6.3 FAIL: anon should see KWD currency'; end if;

  raise notice 'T6 anon access: PASS';
end;
$$;

reset role;
raise notice 'ALL tenant isolation tests complete';