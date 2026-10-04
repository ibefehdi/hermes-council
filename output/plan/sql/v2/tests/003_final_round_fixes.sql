-- ============================================================================
-- Tests: final-round chair fixes
--   F-final-db-5: opening-hours equality semantics (zero-length rejected)
--   F-final-db-3: idempotency key scoped to (tenant_id, key, function_name)
-- ============================================================================

reset role;

-- ---------- F1: zero-length opening interval is rejected ----------
do $$
begin
  insert into public.branch_opening_hours
    (branch_id, tenant_id, day_of_week, seq, opens_at, closes_at, is_closed)
  values
    ('aaaa1111-aaaa-1111-aaaa-111111111111', '11111111-1111-1111-1111-111111111111', 1, 90, '10:00', '10:00', false);
  raise exception 'F1 FAIL: zero-length opening interval (opens_at = closes_at, is_closed = false) was accepted';
exception when check_violation then
  raise notice 'F1 zero-length opening interval rejected: PASS';
end;
$$;

-- ---------- F2: equality is allowed only on is_closed rows ----------
do $$
begin
  insert into public.branch_opening_hours
    (branch_id, tenant_id, day_of_week, seq, opens_at, closes_at, is_closed)
  values
    ('aaaa1111-aaaa-1111-aaaa-111111111111', '11111111-1111-1111-1111-111111111111', 2, 90, '00:00', '00:00', true);
  raise notice 'F2 is_closed row with equal times accepted: PASS';
exception when check_violation then
  raise exception 'F2 FAIL: is_closed row with opens_at = closes_at was rejected';
end;
$$;

-- ---------- F3: overnight interval (closes_at < opens_at) is accepted ----------
do $$
begin
  insert into public.branch_opening_hours
    (branch_id, tenant_id, day_of_week, seq, opens_at, closes_at, is_closed)
  values
    ('aaaa1111-aaaa-1111-aaaa-111111111111', '11111111-1111-1111-1111-111111111111', 3, 90, '22:00', '02:00', false);
  raise notice 'F3 overnight interval accepted: PASS';
exception when check_violation then
  raise exception 'F3 FAIL: overnight interval (closes_at < opens_at) was rejected';
end;
$$;

-- ---------- F4: same key under two different functions is allowed ----------
do $$
begin
  insert into public.idempotency_keys (tenant_id, key, function_name) values
    ('11111111-1111-1111-1111-111111111111', 'final-round-key-1', 'sales');
  insert into public.idempotency_keys (tenant_id, key, function_name) values
    ('11111111-1111-1111-1111-111111111111', 'final-round-key-1', 'appointments');
  raise notice 'F4 same key under different function_name accepted: PASS';
exception when unique_violation then
  raise exception 'F4 FAIL: idempotency key reuse across different functions was rejected; the unique scope must be (tenant_id, key, function_name)';
end;
$$;

-- ---------- F5: same key under the same function is rejected (replay path) ----------
do $$
begin
  insert into public.idempotency_keys (tenant_id, key, function_name) values
    ('11111111-1111-1111-1111-111111111111', 'final-round-key-1', 'sales');
  raise exception 'F5 FAIL: duplicate (tenant_id, key, function_name) was accepted';
exception when unique_violation then
  raise notice 'F5 duplicate key for same function rejected: PASS';
end;
$$;
