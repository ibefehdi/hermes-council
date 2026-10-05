# Database tests: pgTAP gaps and guard tests

**Generated:** 2026-10-05
**Repository:** /Users/fahad/GlowDesk (read-only, commit 07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb)
**Sandbox:** /Users/fahad/council/.ci-sandbox/GlowDesk/database
**Draft:** /Users/fahad/council/output/ci/draft/supabase/tests/

---

## Investigation summary

Before writing tests I verified every table, policy, SECURITY DEFINER function, view, and trigger in the public schema using psql at 127.0.0.1:54322. Key findings:

1. **G-5 (SECURITY DEFINER search_path):** Already tested by `001_tenancy_schema.test.sql` line 34-39. All 70 public SECURITY DEFINER functions have `search_path=public` in `proconfig`. None are executable by `public` or `anon`. Adding an explicit anon-exec check in the structural guard test file.

2. **G-17 (booking_overrides):** Table does NOT exist in the database (grep for `booking_overrides` in pg_tables returns 0 rows). DEFERRED — Phase 5 not built.

3. **G-26 (Realtime channel authorization):** `supabase_realtime` publication exists but has ZERO tables (`pg_publication_tables` is empty). No Realtime channels are active. DEFERRED until Phase 5 when Realtime is wired.

4. **G-14 (Direct-write allowlist):** Verified all 29 tables' policies. Tables in the deny-all category (appointments, appointment_items, idempotency_keys) have no INSERT/UPDATE/DELETE policies already. Adding an explicit guard test.

5. **G-25 (All-branches sentinel UUID):** Verified via information_schema that all `branch_id` columns are nullable UUIDs. Adding guard test.

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

- File: supabase/tests/020_cancellation_reasons.test.sql (new)
- Proves: CONVENTIONS §7 (pgTAP per table with RLS matrix), CONVENTIONS §3.2 (tables have RLS)
- Closes gap: G-7 (P3)
- Result at 07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb: PASSES
- Mutation check:
- Runtime: