# Verifier: replay the pipeline and adjudicate every test

Your sandbox: `/Users/fahad/council/.ci-sandbox/GlowDesk/verify`, a fresh clone at `07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb`. Output: `/Users/fahad/council/output/ci/adjudication.md`.

Inputs:

- `baseline/BASELINE.md`.
- `traceability.md`.
- The four worker files: `pipeline.md`, `tests-database.md`, `tests-backend.md`, `tests-frontend.md`.
- The draft in `/Users/fahad/council/output/ci/draft/`.

If any worker file is missing or clearly incomplete, block the task with a note naming it.

You may change the draft in exactly two ways, and you log every change in `adjudication.md`:

- Move a rejected test from `draft/<path>` to `/Users/fahad/council/output/ci/rejected/<path>`.
- Fix a workflow or ruleset error your replay exposed.

The repository at `/Users/fahad/GlowDesk` stays read-only for you as well.

1. **Static validation.** `node /Users/fahad/council/check-ci.mjs /Users/fahad/council/output/ci/draft /Users/fahad/GlowDesk` must pass with no `FAIL` lines.
2. **Replay the pipeline.** Copy the draft over your sandbox (`cp -R /Users/fahad/council/output/ci/draft/. /Users/fahad/council/.ci-sandbox/GlowDesk/verify/`) and run `pnpm install --frozen-lockfile --prefer-offline`. Then run every job of every workflow exactly as written, step by step, as a pull request into `main` would:
   - Run `supabase stop` (the stack currently runs from `/Users/fahad/council/.ci-sandbox/GlowDesk/base`), then start it from your sandbox with the workflow's exact flags. Run the clean-migration gate, the function tests, and the Playwright suite in both projects.
   - Record every step's result and duration against the pipeline's estimate.
   - Run each new Playwright spec with `--repeat-each=3` and each new Deno file three times, to catch flakiness.

   The run must be green except for exactly the tests marked `KNOWN-FAILING`, and those must fail for the stated reason. Any other failure is a pipeline or test defect: fix it in the draft or reject the test.
3. **Served-code mutations.** With the stack serving your sandbox's functions, run every `MUTATION DEFERRED (served code)` check:
   - Make the edit and confirm the change is live; restart the stack if the edge runtime does not reload.
   - Run the test and confirm it fails.
   - Restore with `git -C /Users/fahad/council/.ci-sandbox/GlowDesk/verify checkout -- <file>` and confirm it passes again.
4. **Adjudicate every new test.** Rule `accept`, `accept with changes` (state them) or `reject` (state why, with evidence).
   - Re-run the mutation check yourself for every test that closes a P1 gap, and for at least 30% of the others.
   - Reject a test if:
     - It cannot fail.
     - It duplicates an existing test.
     - It is flaky or depends on order or leftover data.
     - It tests unbuilt work.
     - It asserts weaker than its title claims.
     - It hardcodes secrets.
   - Confirm each `KNOWN-FAILING` test exposes a real defect against the plan or an ADR (reproduce it), not a test bug or a misread of the plan. Confirm the proposed fix is right.
5. **Gaps and wiring.**
   - Every P1 gap in `traceability.md` is closed by an accepted test or pipeline step, or is explained as not checkable in CI; an open P1 is a finding.
   - Spot-check the traceability task's `BUILT` statuses and at least 30% of its `STRONG` ratings by opening the tests.
   - Confirm every accepted test runs in a job that the required aggregator depends on.
6. **Your own sweep.** Look for what all of them missed:
   - A built table, route or screen with no test.
   - A required check that can pass while something failed.
   - A cache that could hide a failure.
   - A step that hides an error with `|| true`.
   - A secret a fork PR would need.

   Add each as `F-verifier-<n>` with the fix.
7. **Verdict**, stated at the top:
   - `READY`: the static validation passes, the replay is fully green, and every P1 gap is closed.
   - `READY AFTER FIXES`: the same, except that some accepted tests are `KNOWN-FAILING` because of confirmed defects, which must be fixed in the PR that installs CI.
   - `NOT READY`: the static validation fails, the replay fails for pipeline reasons you could not fix, or a P1 gap is open.
8. **Restore the developer's stack.**
   - Run `supabase stop` in your sandbox, then `supabase start` and `pnpm db:reset` in `/Users/fahad/GlowDesk`. These commands only touch the database and gitignored state.
   - Confirm `git -C /Users/fahad/GlowDesk status --porcelain` matches the baseline snapshot.

End with:

- The replay table: job | step | result | duration.
- The test rulings table: test | gap | mutation re-run | ruling.
- The list of draft changes you made.
- The ordered list of defects to fix, if any.

Complete your task once `adjudication.md` is written, whatever the verdict.

## Rerun after the owner's fixes (this pass replaces steps 2 to 7 above)

Your first pass is recorded in `adjudication.md` (verdict NOT READY). The owner has since changed the draft. Re-check **only what changed**; your first-pass results for everything else stand, so do not replay unchanged jobs again. The draft is already copied into your sandbox.

What changed:

1. **`.github/workflows/deploy.yml` moved to `rejected/`.** Deployment is not a merge gate, so it is out of scope for this council. G-2 is a future gate (Phase 0.1 deploy pipeline), not a finding against the merge gates, and it does not affect the verdict.
2. **`supabase/tests/019_appointments_matrix.test.sql` is back in the draft**, now seeding one `appointment_items` row per fixture appointment and asserting the exact visible item ids per role (plan 40). The owner's results:
   - It passes 40/40.
   - With `appointment_items_select` replaced by `USING (false)`, assertions 28 to 32 and 34 fail.
   - With a tenant-only policy (no parent-appointment check), assertions 30 to 33 fail.

   Re-run the test and both mutations yourself, using the scratch-copy method.
3. **The secrets step in `ci.yml` is rewritten.** It checks committed local-only and key files by path, plus secret values in every tracked file, tests included. It allows only the Supabase local demo JWTs (`iss` "supabase-demo"). Extract the step's script and run it in your sandbox: it must pass on the clean tree, and fail on canaries you `git add` and then remove. Use at least a `.env` file, a fake `AKIA...` key in a `*_test.ts` file, a non-demo JWT in a `*.spec.ts` file, and a hardcoded `api_key = "<24+ chars>"`. Confirm it never prints a secret value.
4. **`apps/back-office/e2e/my-day.spec.ts` and `settings-additional.spec.ts` are back.** The lint errors are fixed, hardcoded English is replaced with `strings.ts` keys (their Arabic values match `packages/i18n/locales/ar/messages.po`), and closures use a random future date. Both pass ESLint and the back-office typecheck. Run them with Playwright in both projects with `--repeat-each=3`.

   Port 5173 is taken by the owner's own dev server: never stop or reuse it. Instead, temporarily edit your sandbox's `apps/back-office/playwright.config.ts`: set `baseURL` to `http://127.0.0.1:5174` and the `webServer` to `command: "pnpm dev --port 5174 --strictPort"` with `url: "http://127.0.0.1:5174"`. Run only these two specs; they sign in with a password and do not need the 5173 redirect URLs. Afterwards, restore the file with `git -C <sandbox> checkout -- apps/back-office/playwright.config.ts`.

   The stack must serve your sandbox. Start it from your sandbox, and run `pnpm db:reset` first so the test schema and data are clean.

Then:

- Run `node /Users/fahad/council/check-ci.mjs /Users/fahad/council/output/ci/draft /Users/fahad/glowdesk`; it must show no `FAIL` lines. Also run `pnpm lint` and `supabase test db` once in your sandbox, for the whole suite with the new files.
- Rule on each changed item, and recompute the verdict with the rule in step 7, leaving G-2 out.
- Add a section `## Rerun` at the **top** of `adjudication.md`, holding the new verdict, a table of each change with its result, and your rulings. Keep the first pass below it, unchanged. Update the ordered fix list, and the list of draft changes you made.
- Restore the developer's stack as in step 8.
- **Complete your task when `adjudication.md` is updated, whatever the verdict.** Do not block or ask for input; NOT READY is a valid result, and the chair reports it. If a check cannot run, record why and still complete.
