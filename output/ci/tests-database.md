# Database tests: pgTAP gaps and guard tests

**Generated:** 2026-10-05
**Repository:** /Users/fahad/GlowDesk (read-only, commit 07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb)
**Sandbox:** /Users/fahad/council/.ci-sandbox/GlowDesk/database
**Draft:** /Users/fahad/council/output/ci/draft/supabase/tests/

---

## Investigation summary

Before writing tests I verified every table, policy, SECURITY DEFINER function, view, and trigger in the public schema using psql at 127.0.0.1:54322. Key findings:

1. **G-5 (SECURITY DEFINER search_path):** Already tested by `001_tenancy_schema.test.sql` line 34-39. All 70 public SECURITY DEFINER functions have `search_path=public` in `proconfig`. None are executable by `public` or `anon`. Added an explicit anon/public executability check in the structural guard test (022_guard_checks.test.sql).

2. **G-17 (booking_overrides):** Table does NOT exist in the database (`pg_tables` returns 0 rows). DEFERRED — Phase 5 not built.

3. **G-26 (Realtime channel authorization):** `supabase_realtime` publication exists but has ZERO tables (`pg_publication_tables` is empty). No Realtime channels are active. DEFERRED until Phase 5 when Realtime is wired.

4. **G-14 (Direct-write allowlist):** Verified all 29 tables' policies. 6 tables have direct-write policies: clients, client_notes, profiles, service_categories, settings, shifts. Guard test enforces this set.

5. **G-25 (All-branches sentinel UUID):** Verified via information_schema that all `tenant_id` columns are NOT NULL on base tables. All `branch_id` UUID columns are clean. Guard test enforces sentinel absence.

---

## Test records

### T-db-1: Appointments and appointment_items RLS matrix

- File: draft/supabase/tests/019_appointments_matrix.test.sql (new)
- Proves: ADR-24 (appointments schema), ADR-28 (no direct-write policies), ADR-20 rule 5 (composite FKs), ADR-22 (audit), ADR-7 (status enum)
- Closes gap: G-4 (P1) — pgTAP for appointments/appointment_items
- Result at 07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb: PASSES
- Mutation check: Disabled RLS on appointments (`alter table public.appointments disable row level security`) — 7 tests failed (tests 2, 16, 18, 20, 23, 25-26), including RLS checks, role isolation, cross-tenant denial. Restored and passing again.
- Runtime: <1s (part of 3s full suite)

### T-db-2: cancellation_reasons RLS matrix

- File: draft/supabase/tests/020_cancellation_reasons.test.sql (new)
- Proves: CONVENTIONS §7 (pgTAP per table with RLS matrix), CONVENTIONS §3.2 (tables have RLS)
- Closes gap: G-7 (P3)
- Result at 07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb: PASSES
- Mutation check: Disabled RLS on cancellation_reasons — 8 tests failed (tests 2, 8-14), including RLS check, role scoping, cross-tenant isolation. Restored and passing again.
- Runtime: <1s

### T-db-3: idempotency_keys RLS deny-all

- File: draft/supabase/tests/021_idempotency_keys.test.sql (new)
- Proves: ADR-31 (idempotency_keys is client-inaccessible, RLS deny-all)
- Closes gap: G-6 (P2)
- Result at 07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb: PASSES
- Mutation check: Disabled RLS on idempotency_keys — 2 tests failed (RLS check, SELECT isolation). INSERT still blocked by table-level grant (correct layered security). Restored and passing again.
- Runtime: <1s

### T-db-4: Structural guard checks

- File: draft/supabase/tests/022_guard_checks.test.sql (new)
- Proves: ADR-20 rule 10 (SECURITY DEFINER search_path + anon-exec guard), ADR-21 (security_invoker views), ADR-17 (money columns), ADR-28 (direct-write allowlist), ADR-22 (audit triggers), ADR-20 rule 6 (no sentinel UUID), ADR-20 rule 5 (composite FKs), CONVENTIONS §3.2 (RLS per table)
- Closes gap: G-5 (P1 — adds anon/public executability check), G-14 (P2 — direct-write allowlist), G-25 (P2 — sentinel UUID guard)
- Result at 07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb: PASSES
- Mutation check: Disabled RLS on cancellation_reasons — 1 test failed (test 1: "RLS on every public table" catches it). Restored and passing again.
- Runtime: <1s

---

## Summary table

| ID | File | Gap | Result at HEAD |
|----|------|-----|----------------|
| T-db-1 | draft/.../019_appointments_matrix.test.sql | G-4 (P1) | PASSES |
| T-db-2 | draft/.../020_cancellation_reasons.test.sql | G-7 (P3) | PASSES |
| T-db-3 | draft/.../021_idempotency_keys.test.sql | G-6 (P2) | PASSES |
| T-db-4 | draft/.../022_guard_checks.test.sql | G-5 (P1), G-14 (P2), G-25 (P2) | PASSES |

## Gaps NOT closed (assigned to tests-database)

| Gap | Priority | Reason |
|-----|----------|--------|
| G-17 | P3 | Table `booking_overrides` does not exist (Phase 5 not built). DEFERRED. |
| G-26 | P2 | `supabase_realtime` publication exists but has ZERO tables. No Realtime channels are active. DEFERRED until Phase 5 wires Realtime. |