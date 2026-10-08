# Edge Function tests: Deno gaps and contract guards

Your sandbox: `{{SANDBOX}}/backend`. Output: `{{CI_DIR}}/tests-backend.md`. You own new and changed `*_test.ts` files under `{{CI_DIR}}/draft/supabase/functions/`, plus any fixtures next to them. Start by reading `{{CI_DIR}}/baseline/BASELINE.md` and the gaps owned by `tests-backend` in `{{CI_DIR}}/traceability.md`. Close the P1 gaps first, then P2, then P3.

## How to write them

- Put each test in the function folder it covers (`supabase/functions/<slug>/<topic>_test.ts`), or in `_shared/` for shared modules. `pnpm fn:test` (`scripts/fn-test.sh`) runs `deno test` in every function folder, so new files are picked up without wiring.
- Follow the existing pattern in `clients/clients_test.ts`:
  - `useLocalStackEnv()`, `requireServedFunction()` and `accessTokenFor()` from `_shared/testing.ts`.
  - The seed users from the README and the fixed seed UUIDs.
  - A per-run `runId` on every row you create.
- Use the function's own `deno.json` and import map. Do not add dependencies.
- Assert exact values: the HTTP status, the ADR-29 envelope shape, the error code from the CONVENTIONS §4.2 catalogue, the `fieldErrors` keys on `VALIDATION`, and the database state after the call (read it back with the admin client).

## What to cover

1. **Every built route, per the gap list:**
   - The happy path.
   - A malformed body (`VALIDATION`).
   - A missing token and a wrong-scope token: other tenant, other branch, lower role (`UNAUTHENTICATED` or `FORBIDDEN`, as the catalogue says).
   - A platform-secret route called without the secret.
   - For money-moving or idempotent routes: replaying the same `Idempotency-Key` returns the cached response and writes once, and the same key on a different function is independent (ADR-31).
   - Concurrency where the plan asks for it.
2. **Contract guard tests**, which fail when a future route breaks a rule:
   - A table-driven test that enumerates every route of every function (from the routing tables, not a hand-written list, so new routes are included automatically).
   - It asserts that each route rejects an unauthenticated call unless the route is on an explicit allowlist with the reason.
   - It asserts that each route answers unknown input with the envelope, never a stack trace or SQL text.
   - Plus the `_shared` invariants: the error mapping covers the whole catalogue, and CORS and request-id propagation hold.
3. **Failure paths the plan names.** For example, compensation when a multi-step operation fails midway, without leaving orphan state such as an invited auth user with no tenant.

## Validate each test

1. Run it from your sandbox: `cd supabase/functions/<slug> && deno test --allow-all <file>`. Then run the full `pnpm fn:test` and check nothing else changed.
2. Do a mutation check:
   - Logic you can exercise in-process (a handler, a `_shared` module or a validator called directly): edit it in your sandbox, watch the test fail, restore it.
   - Behaviour that only shows over HTTP through the served function: record `MUTATION DEFERRED (served code)` with the exact edit to make, so the verifier can run it.
3. Copy the file to the draft and record it in your output file in the common brief's format.
