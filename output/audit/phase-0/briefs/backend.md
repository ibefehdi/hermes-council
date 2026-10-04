# Edge Functions and backend audit

Output: `/Users/fahadasad/hermes-council/output/audit/phase-0/backend.md`

Scope: everything under `/Users/fahadasad/glowdesk/supabase/functions/`, `packages/validation`, `packages/api` and Edge Function settings in `supabase/config.toml` that belongs to phase 0, judged against the phase's Edge Functions section, ADR-19, ADR-20 rules 3 and 7, ADR-27 to ADR-33, CONVENTIONS.md §3.3, §4 and §6, and the `supabase-edge-functions` skill. Start by reading `/Users/fahadasad/hermes-council/output/audit/phase-0/gates/GATES.md`.

If the phase has no Edge Function or backend work, write a short file that says so with the evidence (the phase text and `git diff --stat` for the phase), confirm the function tests in the gate logs still pass, and stop.

1. **Layout and isolation.** Function slug = bounded-context name; `_shared/` modules as the skill describes; functions import `_shared` by relative path and `packages/validation` through its Deno-compatible export, never from `apps/` or other packages. A broken or redeployed function must not affect the others. Dependencies are pinned.
2. **Auth modes.** For every route: which auth mode it uses (user JWT, platform secret, none), whether that matches the plan, how the JWT is verified (`verify_jwt` in `config.toml` versus in-code checks), and whether secrets are compared in constant time. Platform-admin paths must not be reachable without the secret. The service role is never used for per-user requests, and privileged code re-derives scope from `memberships` (ADR-20 rule 7).
3. **Contract.** Every response uses the ADR-29 envelope; error codes and HTTP statuses match the CONVENTIONS §4.2 catalogue; validation failures return `VALIDATION` with `fieldErrors`; request ids are propagated; CORS is handled; unhandled errors become `INTERNAL` without leaking stack traces or SQL.
4. **Invariants.** Money-moving mutations require `Idempotency-Key` and use the `idempotency_keys` protocol with the per-function replay boundary (ADR-31). Multi-row writes run in one database transaction (an RPC), not as a sequence of client calls that can half-succeed. Note any orphan state a failure midway would leave (for example an invited auth user with no tenant).
5. **Exercise it.** Call the served functions on `http://127.0.0.1:54321/functions/v1/<slug>/...` with good and bad input: missing and wrong credentials, malformed bodies, duplicates, and the happy path. Record each request and response (redact secrets). Do not leave data behind unless it is clearly test data you name in your output.
6. **Tests.** Check the Deno tests cover the phase's Tests section: happy path, validation rejection, scope denial, idempotent replay and concurrency where relevant. Flag tests that mock away the thing they claim to test.
7. **Secrets and config.** Local secrets live in gitignored files with a committed example; nothing secret is committed (`git log -p` search for key-like strings); required secrets are documented.
