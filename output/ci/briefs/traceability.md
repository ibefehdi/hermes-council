# Traceability: map what the plan promises to the tests that prove it

Your sandbox: `/Users/fahad/council/.ci-sandbox/GlowDesk/base` (read only; the stack is running from it). Output: `/Users/fahad/council/output/ci/traceability.md`. Start by reading `/Users/fahad/council/output/ci/baseline/BASELINE.md`.

Four authors work from your file in parallel: pipeline, tests-database, tests-backend and tests-frontend. Every gap you miss stays ungated, and every gap you assign wrongly gets no owner, so be exhaustive and precise.

1. **What is built.** For every phase and subphase in `/Users/fahad/GlowDesk/plan/parts/11-delivery-plan.md`, give a status and evidence: `BUILT`, `PARTIAL` (say which parts) or `NOT STARTED`.
   - Use the code, `git log`, the README, `/Users/fahad/GlowDesk/plan/evidence/` if present, and earlier audit reports in `/Users/fahad/council/output/audit/phase-*/AUDIT_REPORT.md` if present.
   - Audit reports are leads, not proof; confirm them against the code at `07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb`.
   - Only built work is gated. List the not-started items once, as future gates.
2. **Requirements.** For every built subphase, list:
   - Every Acceptance criterion and every Tests bullet.
   - The phase Exit criteria that a CI run can check.
   - The ADRs whose invariants the built work carries (tenant and branch isolation, money as integer minor units, idempotency, the envelope and error codes, booking integrity if built, and so on).

   Then add the automatable rules from CONVENTIONS §7 and the §8 PR checklist:
   - The pgTAP matrix per table, operation and role, including cross-tenant, cross-branch and anon.
   - The clean-migration gate (reset from empty on the pinned CLI, type drift fails, functions typecheck, pgTAP, adversarial fixtures, the `sql/drafts-v1/` grep).
   - Missing Arabic translations fail CI; logical CSS properties only; size budgets; axe-core accessibility on main flows.
   - Envelope and error-code contract tests; idempotency replay.
   - Skills copies identical; no secrets or local-only files committed.
   - Anything else on the checklist a machine can enforce.
3. **Existing proof.** For each requirement, record:
   - The test(s) that enforce it (file:line and test name).
   - Whether that test runs in one of the baseline commands.
   - A rating: `STRONG` (read the assertion: it would fail if the guarantee broke), `WEAK` (it asserts something softer, such as only a status code, or it cannot fail), or `NONE`.

   Do not rate a test `STRONG` from its name; open it.
4. **Mechanical sweeps.** Do not rely on reading the plan alone; enumerate the system and check each item.
   - Every table, view and function in `public` from the database catalog (`psql`). For each: is RLS enabled, which pgTAP files reference it, and which operations and roles they cover? Are definer functions safe, with `search_path` fixed, `EXECUTE` revoked from `anon` and `public`, and authorization inside? Do views use `security_invoker`?
   - Every Edge Function route (from each `routes.ts` or `index.ts`). Is there a Deno test for the happy path, a validation rejection, an auth or scope denial, and idempotent replay where money moves?
   - Every screen route of the back office (its router). Is there at least one Playwright journey that visits it, run in both `en` and `ar`?
   - Every check that exists as a command but is not part of any gate (for example type drift, or `fn:check`, if baseline found them unwired).
5. **Gaps.** List every requirement rated `WEAK` or `NONE`, or not run by any gate, as a gap:

   ```
   ### G-<n>: <short title>
   - Requirement: <plan item, ADR or rule, quoted, with location>
   - Today: NONE | WEAK (<why>) | NOT IN CI (<which command>)
   - Priority: P1 | P2 | P3
   - Owner: pipeline | tests-database | tests-backend | tests-frontend
   - Test idea: <arrange, act, assert in two or three lines; or for pipeline, the step to add>
   ```

   - **P1** means a merge must not happen without it: tenant or branch isolation, privilege escalation, money or tax, booking integrity, an acceptance criterion of a built subphase, the clean-migration gate. **P2**: other required tests and guard tests. **P3**: nice to have.
   - Give each gap exactly one owner.
   - If one owner has more than about 25 gaps, mark its lowest P3s `DEFERRED` with a reason so the author can finish.
6. **Summary.** End with a matrix table: requirement | subphase or rule | existing test | rating | gap. Add the gap counts per owner and priority, and the list of future gates for unbuilt work.
