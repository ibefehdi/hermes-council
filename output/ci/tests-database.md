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

## Test files