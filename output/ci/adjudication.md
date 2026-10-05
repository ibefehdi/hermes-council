# Verifier adjudication

## Rerun

Verdict: NOT READY.

This pass follows the owner's rerun instruction and rechecks only the changed draft items. The deployment workflow is now under `output/ci/rejected/`; deployment is out of merge-gate scope for this round, so G-2 is excluded from this verdict. The previously verified results for unchanged jobs and tests remain as recorded below. The product repository stayed read-only; its working tree was clean again after restoring the local Supabase stack.

### Changed-item verification

| Changed item | Verification and evidence | Ruling |
|---|---|---|
| `draft/supabase/tests/019_appointments_matrix.test.sql` | The full `supabase test db` suite passes 23 files / 1,018 tests. The targeted test passes 40/40. With `appointment_items_select` changed to `USING (false)`, assertions 28–32 and 34 fail (6/40). With a tenant-only policy, assertions 30–33 fail (4/40). The fixture inserts four actual items at lines 22–30, and the role-specific exact-item assertions are at lines 193–235. | ACCEPT. G-4 (P1) is closed: authorized roles see the expected item rows, and both policy weakenings are detected. |
| `draft/.github/workflows/ci.yml` secret scan | The first clean-tree replay exposed two defects: the Supabase-demo JWT allowlist did not match the intended issuer, and the generic assignment pattern falsely matched the deliberately invalid long auth-header fixture in `route_guard_test.ts:140`. I corrected the allowlist and narrowed the generic value pattern in the workflow at lines 207–229. The final clean-tree scan passes. After staging harmless canaries, the scanner failed on `.env`, a fake AWS key in a `*_test.ts`, a non-demo JWT in a `*.spec.ts`, and a 24+ character `api_key` assignment; it emitted only paths and line numbers, never the values. All canaries were removed and the clean scan passed again. | ACCEPT WITH THE RECORDED WORKFLOW CORRECTION. F-verifier-3 is resolved for the specified canaries and committed test/spec files. |
| `draft/.github/workflows/ci.yml` local Vite configuration | The first browser replay showed a blank page; the browser console reported that `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` were unset. I added an E2E-job step at workflow lines 316–325 that reads `supabase status -o env` at runtime and exports `API_URL` and `ANON_KEY` through `GITHUB_ENV`, without printing them. Replaying with those runtime values allowed the app and auth screens to load. | ACCEPT. This fixes a workflow defect exposed by the changed E2E replay and follows the common brief's no-hardcoded-key rule. |
| `draft/apps/back-office/e2e/settings-additional.spec.ts` | Both projects, three repeats each: all 12 test instances passed. Mutation check: changing the closure button handler from opening the form to doing nothing made `owner manages branch closures` fail at its dialog assertion; after restoring the source, the same test passed 1/1. | ACCEPT for G-9's closures and cancellation-reasons coverage. |
| `draft/apps/back-office/e2e/my-day.spec.ts` | The six positive staff-journey instances failed across `en`/`ar` and three repeats. The snapshot shows the `Where you work` card contains a table with two branch rows, but the test looks for a `region` landmark at lines 21–23; the `Card` renders a generic container, and `MyDayPage.tsx:197–237` exposes the table caption `Your branches`. The same invalid `region` assumption is used for the shifts and blocked-time cards at lines 26–31. | REJECT and move to `output/ci/rejected/apps/back-office/e2e/my-day.spec.ts`. G-8 remains open; fix the locators to use the accessible table captions (and rerun both locale projects three times). |

### Rerun replay table

| Job / step | Result | Duration / evidence |
|---|---|---|
| Draft static validator | PASS; no `FAIL` lines, required check is `ci-passed` | 5.65 s; `node /Users/fahad/council/check-ci.mjs /Users/fahad/council/output/ci/draft /Users/fahad/GlowDesk` |
| `pnpm lint` | PASS | 4.41 s |
| Back-office typecheck | PASS | `pnpm --filter @repo/back-office typecheck`, exit 0 |
| Full pgTAP suite | PASS; 23 files / 1,018 tests | 4.84 s wall time; detailed output in `output/ci/scratch/verifier-rerun-db-test.log` (lines 22–28) |
| Secret scan clean tree | PASS | Clean after canary removal; final output was `OK: no secrets or local-only files committed` |
| Secret scan canaries | Expected FAIL on all four canary classes | Output contained `.env` and canary file/line locations only; no matched values |
| New E2E specs, both projects, `--repeat-each=3` | 18 passed / 6 failed; all 12 settings-spec runs passed; the six failed instances are the positive `/my-day` journey | About 1.4 min. The missing Vite environment was fixed before the final run; remaining failure is the test's invalid landmark locator, not a port conflict. |
| Closure-flow mutation and restore | Mutation FAIL at the expected dialog assertion; restored test PASS 1/1 | Evidence from `settings-additional.spec.ts:28–30` |
| Stack / repository restoration | PASS; verifier stack stopped, developer stack started and reset; `GlowDesk` porcelain status empty at `9efb74bf24303ed3a7302d6fa0f5da871b5720d2` | `supabase start` and `pnpm db:reset` both exited 0; local auth health returned HTTP 200 |

### Updated gap ruling and remaining work

- G-4 (P1) is closed by the accepted row-backed test and both mutation checks.
- G-2 is explicitly out of scope as a deployment workflow, per the owner's rerun direction.
- G-8 remains open because the proposed `/my-day` test was rejected after the replay demonstrated its landmark locator is invalid.
- G-10 remains open from the first pass: traceability.md:418–421 records the missing axe-core accessibility checks. No change in this rerun addressed it.
- The validator, lint, typecheck, pgTAP suite, secret-canary checks, and accepted settings E2E coverage pass; however, the built-plan E2E gaps G-8 and G-10 are not proven by an accepted test. The merge gate therefore cannot be marked ready.

### Draft changes made in this rerun

- Corrected the local-demo JWT allowlist and generic inline-value matching in `draft/.github/workflows/ci.yml:207–229` after the clean-tree replay exposed false positives.
- Added runtime local Supabase environment export for the E2E dev server in `draft/.github/workflows/ci.yml:316–325`; no key is hardcoded or printed.
- Moved the rejected `my-day.spec.ts` from the draft to `output/ci/rejected/apps/back-office/e2e/my-day.spec.ts`.
- No files in `/Users/fahad/GlowDesk` were changed. The only product-code mutation used for verification was in the verifier sandbox and was restored with `git checkout`.

---


Verdict: NOT READY

The draft passes `check-ci.mjs` with no `FAIL` lines after the verifier's workflow and ruleset corrections. The local static checks, clean migration tests, Edge Function suites, and the accepted database tests pass. The merge gate is still not ready: the P1 deployment gap G-2 is not actually implemented, and the P1 appointment-item RLS gap G-4 remains open because the proposed test passes even when the appointment-item SELECT policy is broken. The new frontend tests were rejected after the PR lint command failed on them; local Playwright execution also could not proceed because an unrelated process owns port 5173.

## Scope and inputs checked

- Target under test: `/Users/fahad/council/.ci-sandbox/GlowDesk/verify`, commit `07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb`.
- The working tree at `/Users/fahad/GlowDesk` was at `9efb74bf24303ed3a7302d6fa0f5da871b5720d2`, not the requested target commit. I did not modify it. Its porcelain status was empty both before and after verification. Tests and replay were run from the pinned verifier clone.
- Read the required common, verifier, and chair briefs, plus `baseline/BASELINE.md`, `traceability.md`, `pipeline.md`, all three `tests-*.md` files, and the draft.
- The requested stack restoration completed: stopped the verifier clone's stack, then started the local stack from `/Users/fahad/GlowDesk` and ran `pnpm db:reset` successfully. The source working tree remained clean.

## Static validation and corrected gate details

`node /Users/fahad/council/check-ci.mjs /Users/fahad/council/output/ci/draft /Users/fahad/GlowDesk` passes: `OK: 2 workflow(s), 1 required check(s) for main: ci-passed`. It emits only the deploy-workflow warning that fork PRs cannot access `SUPABASE_ACCESS_TOKEN`; that warning is not itself a CI-job secret dependency because deploy is not triggered for PRs.

The verifier made and logged these allowed corrections:

1. `.github/workflows/ci.yml`: quote `$SUPABASE_EXCLUDE` in both Supabase start commands; change the aggregator condition to `if: ${{ always() }}` so it evaluates the downstream job results after a failure, cancellation, or skip; install pnpm before `setup-node`'s `cache: pnpm` step; and pin pnpm/action-setup to the peeled v6.1.0 commit `ea17c68df8912ef543352723c149a84f56e3d413` rather than the annotated tag-object hash.
2. `.github/workflows/deploy.yml`: quote `$GITHUB_OUTPUT`; install pnpm before `setup-node`; and use the same verified peeled pnpm/action-setup commit.
3. `.github/rulesets/main.json`: remove the `RepositoryRole` administrator bypass (`bypass_actors: []`) so an administrator cannot bypass the stated required-check guarantee.
4. Rejected and moved the inadequate test files listed below to `output/ci/rejected/`.

`git ls-remote --tags` verified the action pins against their named release tags. The verifier confirmed the pnpm action's annotated tag resolves to the commit above. The official setup-node documentation states that the package manager must be preinstalled for package-manager caching; official Supabase CLI documentation describes `supabase status` as reporting the local development stack and requiring that stack to be started.

## Replay table

| Job / step | Result | Duration / evidence |
|---|---|---|
| Dependency install (`pnpm install --frozen-lockfile --prefer-offline`) | PASS | 1.7 s; lockfile unchanged |
| Static job (`pnpm verify`: skills, strict Lingui compile, typecheck, ESLint, CSS lint, Vitest, back-office build, size limits) | PASS | 85.42 s total; 35 Vitest files, 288 tests passed; bundle 225.78/250 kB and calendar 61.96/150 kB |
| Initial static lint with the draft's new frontend specs present | FAIL | ESLint found four errors: unused `unique` import and unused `appLocale` in `my-day.spec.ts`, and unused `appLocale` in `settings-additional.spec.ts`. These two files were rejected and removed from the final draft; `pnpm verify` then passed. |
| Supabase reduced-stack start and clean reset in verifier clone | PASS | Start succeeded; reset applied the migration set and seed. Reset measured 25.48 s. |
| Backend schema lint | PASS | 0.80 s; no schema errors |
| Final-draft pgTAP suite | PASS | 14.94 s; 22 files, 978 tests. The rejected appointments test is not included in this final-draft count. |
| Generated type drift | PASS | Generated types diffed equal to committed types; generator printed only its unformatted-output notice. Generation took 0.64 s. |
| Edge Function typecheck | PASS | 0.60 s |
| Deno Edge Function suites | PASS | 16.74 s; 7 suites, 0 failures, including the Sentry mock-transport test and route guard |
| New `route_guard_test.ts`, three repeats | PASS | 9/9 tests passed in each of three runs |
| G-15 idempotency replay mutation | PASS as a mutation check | Removing the completed-replay return made 2 tests fail; after restoring the source, `idempotency_test.ts` passed 8/8. |
| G-4 appointment mutation | INSUFFICIENT TEST | Disabling RLS on appointments made 7 assertions fail. However, replacing the appointment-item SELECT policy with `USING (false)` made all 35 assertions pass. See ruling below. |
| G-5 SECURITY DEFINER search-path mutation | PASS as a mutation check | Resetting `search_path` on `public.current_tenant_ids()` made assertion 3 in `022_guard_checks.test.sql` fail; the original test passed after rollback. |
| G-6 idempotency_keys RLS mutation | PASS as a mutation check | Disabling RLS made assertions 2 and 8 fail; the original test passed after rollback. |
| Playwright browser install | PASS | `playwright install --with-deps chromium` exited 0 |
| Playwright en project | BLOCKED BEFORE TESTS | The configured server URL, 127.0.0.1:5173, was already held by node PID 41833. I did not stop or reuse that unrelated server. The ar project and three-repeat runs for new specs were therefore not executed. |
| Final draft validator | PASS | No `FAIL` lines; actionlint and ruleset validation passed. |
| Deploy workflow replay | FAILS BY INSPECTION | The workflow runs only on `main` or manual dispatch, does not start a local Supabase stack or link a remote project, then tests `supabase status` and skips both deploy steps when that local status is absent. It has no `staging` deployment path. |

## Test rulings

| Test / item | Gap | Mutation rerun / observed result | Ruling |
|---|---|---|---|
| `draft/supabase/tests/019_appointments_matrix.test.sql` (T-db-1) | G-4 (P1) | Disabling appointments RLS caused 7 failures. More decisively, changing `appointment_items_select` to `USING (false)` passed all 35 assertions. The file seeds no appointment-item rows; its item visibility check asserts zero rows. | REJECT. It does not prove appointment-item branch/tenant visibility or that an authorized role can read an item. Moved to `rejected/supabase/tests/019_appointments_matrix.test.sql`. G-4 remains open. |
| `draft/supabase/tests/020_cancellation_reasons.test.sql` (T-db-2) | G-7 (P3) | Worker record reports 8 assertions failed with RLS disabled. The test seeds rows across tenants and checks tenant-scoped reads, anonymous denial, and no direct-write policies. | ACCEPT. |
| `draft/supabase/tests/021_idempotency_keys.test.sql` (T-db-3) | G-6 (P2) | Verifier disabled RLS; assertions 2 and 8 failed. Rollback restored the test to passing. | ACCEPT. |
| `draft/supabase/tests/022_guard_checks.test.sql` (T-db-4) | G-5 (P1), G-14 (P2), G-25 (P2) | Verifier removed `search_path` from `current_tenant_ids()`; assertion 3 failed. Original passed after rollback. | ACCEPT. G-5 is closed; the allowlist and sentinel guards are also present. |
| `draft/supabase/functions/_shared/route_guard_test.ts` (T-backend-1) | Route contract guard | Passed 9/9 three times. | ACCEPT for route auth, health, envelope, CORS, request-id and unknown-route coverage. It does not itself close G-15/G-16; the existing idempotency/server tests cover those contracts. |
| Existing `_shared/idempotency_test.ts` (G-15) | G-15 (P2) | Verifier mutation caused 2 failures; restored suite passed 8/8. | ACCEPT; mutation confirms replay coverage can fail. |
| Existing `_shared/server_test.ts` (G-16) | G-16 (P3) | Worker reports 12/16 failed with envelope mutation; not independently re-run because the sample quota was met with the other mutation checks. | ACCEPT based on test assertions and worker's recorded mutation; server tests remain in the Deno suite. |
| Existing `_shared/logging_test.ts` and `_shared/sentry.ts` | G-12/G-18 | Source shows Sentry initialization, tagged capture and flush when `SENTRY_DSN` is set; the test sends a Sentry event to a local test receiver. Full Deno suite passed. | ACCEPT for implemented SDK transport and local integration test. Traceability's claim that Sentry is absent is stale and incorrect at the pinned commit. The plan's staged/hosted operational capture still needs an environment-level check; it is not a missing-code finding. |
| New `apps/back-office/e2e/my-day.spec.ts` | G-8 (P2) | Not run: file fails ESLint and the local Playwright server could not start. | REJECT. Moved to `rejected/apps/back-office/e2e/my-day.spec.ts`. |
| New `apps/back-office/e2e/settings-additional.spec.ts` | G-9 (P3) | Not run: file fails ESLint and the local Playwright server could not start. It also covers only closures and cancellation reasons, not the traceability report's invoicing, methods, and tips tabs. | REJECT. Moved to `rejected/apps/back-office/e2e/settings-additional.spec.ts`. |
| Existing `clients.spec.ts` CSV import journey | G-21 (P2) | Inspected lines 130–170: upload, dry-run, invalid and duplicate row handling, import, download of rejected rows, and list verification. | ACCEPT as already covered; no duplicate test needed. |
| Playwright fixture project architecture | G-24 (P2) | CI defines en and ar projects and runs the journeys once per project; full local replay could not run because of port 5173. | ACCEPT as the dual-locale mechanism, not as proof that every built screen is visited. G-8/G-9 screen coverage remains open. |

## Gaps and wiring rulings

- G-1 and G-3 are wired in the CI workflow; validator passes.
- G-2 is not closed: the deploy workflow does not deploy staging and its local-stack status probe causes a fresh hosted runner to skip remote deployment. This is a P1 finding.
- G-4 is not closed: the rejected test does not prove appointment-item RLS behavior. This is a P1 finding.
- G-5 is closed by the structural guard and the successful mutation check.
- G-11 is wired: `pnpm i18n:compile` invokes `lingui compile --strict` per the target commit's root `package.json` script.
- G-12/G-18 are not absent as the worker reports claim; target code has the Sentry reporter and a Deno local receiver test. Update traceability with the actual implementation and test evidence, while distinguishing local SDK delivery from deployment/hosted acceptance.
- G-13 is not fully closed. The CI step in `.github/workflows/ci.yml` checks a short list of file/path names and PEM header patterns, and excludes test/spec files. It will miss common inline token/API-key values in ordinary source. Replace this with a pinned secret scanner or a materially broader, mutation-tested guard.
- G-17 is not built at the pinned target: no migration contains `booking_overrides`; keep it as a future gate. G-26 and G-27 remain future/deferred as the worker and pipeline notes state. G-10 remains open because `@axe-core/playwright` is not installed.
- `ci-passed` is now fail-closed in workflow logic: it uses `always()` and checks all three `needs.*.result` values. The ruleset no longer configures an administrator bypass.

## Findings to fix, in order

1. F-verifier-1 (P1, G-2): Replace the local `supabase status` probe in `draft/.github/workflows/deploy.yml` with explicit remote project configuration/linking from protected environment variables/secrets. Deploy migrations, functions and frontend from the same commit to staging on the plan's staging path, then production only from `main`. Missing project refs/secrets must fail visibly rather than silently skip. The current workflow's trigger and steps do not implement Phase 0.1's staging-to-production acceptance criterion.
2. F-verifier-2 (P1, G-4): Add a pgTAP test that seeds real `appointment_items` rows for both tenant A branches and tenant B, then asserts owner, branch-manager, receptionist, staff, outsider and anon visibility/denial according to ADR-20. Verify authorized owners/managers can read an item, and cross-branch/cross-tenant roles cannot. Rerun mutation by removing/weakening the item SELECT policy and require failures.
3. F-verifier-3 (security coverage, G-13): Replace the grep-only secrets check with a pinned scanner that catches actual token/key values across committed files, including tests; add a known harmless canary mutation test to demonstrate detection. Keep real credentials out of fixtures.
4. F-verifier-4 (P2/P3 screen coverage): Correct the frontend tests' lint errors, then add a journey for `/my-day` and cover the remaining built settings tabs (invoicing, methods and tips) as well as closures and cancellation reasons. Run the new specs in both projects three times in a clean runner.
5. Update traceability claims for G-18/G-12, G-24, and G-9 to reflect the target commit and accepted coverage. Do not describe G-18 as unintegrated; preserve a separate staging/hosted Sentry acceptance check.

## Draft changes made by the verifier

- `.github/workflows/ci.yml`: shell quoting, fail-closed aggregator condition, pnpm-before-setup-node ordering, and corrected pnpm action commit pin.
- `.github/workflows/deploy.yml`: shell quoting, pnpm-before-setup-node ordering, and corrected pnpm action commit pin.
- `.github/rulesets/main.json`: removed administrator bypass actors.
- Moved the three rejected test files to `output/ci/rejected/` as listed above.
- No files in `/Users/fahad/GlowDesk` were edited. The rejected test files remain available for worker repair; no scratch mutation files remain.

## External references checked

- actions/setup-node README (cache setup requires the package manager to be installed): https://github.com/actions/setup-node
- Supabase CLI `status` reference (local development stack status): https://supabase.com/docs/reference/cli/supabase-status
- GitHub Actions `always()` / job status behavior: https://docs.github.com/en/actions/learn-github-actions/expressions#status-check-functions
