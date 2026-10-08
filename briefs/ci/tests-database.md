# Database tests: pgTAP gaps and guard tests

Your sandbox: `{{SANDBOX}}/database`. Output: `{{CI_DIR}}/tests-database.md`. You own new and changed files under `{{CI_DIR}}/draft/supabase/tests/`. Start by reading `{{CI_DIR}}/baseline/BASELINE.md` and the gaps owned by `tests-database` in `{{CI_DIR}}/traceability.md`. Close the P1 gaps first, then P2, then P3.

## How to write them

- Name new files after the highest existing number (`019_<topic>.test.sql`, ...), one topic per file. Open each with a header comment in the style of `015_clients_matrix.test.sql`: the plan items, ADRs and CONVENTIONS rules it covers, and the fixtures it uses.
- Use the shape `begin; select plan(<exact count>); ... select * from finish(); rollback;`. Use the role and fixture helpers of `000_harness.sql` (`tests.seed_tenancy_matrix()` and the others). Define any extra helper inside your own file's transaction. Do not edit `000_harness.sql`, the migrations or `supabase/seed.sql`.
- Prefer `throws_ok` with the exact SQLSTATE, and `results_eq` or `is` with exact values, over `ok(true-ish)`. For denials, check both directions: the right role succeeds and every wrong role (other branch, other tenant, lower role, outsider, anon) fails or sees nothing.

## What to cover

1. **Isolation-matrix holes** from the gap list: table x operation (SELECT, INSERT, UPDATE, DELETE) x role, including cross-tenant, cross-branch and anon, and Realtime channel authorization where a built table publishes.
2. **Structural guard tests.** One file of catalog-level invariants that fails the moment a future migration breaks a rule. Query `pg_class`, `pg_proc`, `pg_policies`, `information_schema` and `has_function_privilege`:
   - Every `public` table has RLS enabled and at least one policy.
   - Every `SECURITY DEFINER` function in `public` has a fixed `search_path` and is not executable by `anon` or `public` unless it is on an explicit allowlist in the test, with the reason.
   - Every view has `security_invoker`.
   - Money columns are `bigint` and named `..._minor`, and no `real`, `double precision` or `money` column exists.
   - Every tenant-scoped table has a non-null `tenant_id`.
   - Audit triggers exist on the tables the plan says are audited.

   Each check must pass at `{{COMMIT}}`, or be `KNOWN-FAILING` with a real defect behind it. For allowlist entries, cite the ADR or plan line that justifies them.
3. **Invariants of built work** the plan names as acceptance criteria or Tests bullets: constraints, RPC authorization and validation, idempotency boundaries, money rounding, and booking exclusion and concurrency if booking is built.

## Validate each test

1. Run the whole suite from your sandbox with `supabase test db`, and check that your file passes and nothing else changed. For quick iteration on one file, run `psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f <file>` and read the TAP output.
2. Do a mutation check as the common brief describes: a scratch copy with the breaking DDL right after `begin;`. Record which assertion failed.
3. Copy the file to `{{CI_DIR}}/draft/supabase/tests/` and record it in your output file in the common brief's format.
