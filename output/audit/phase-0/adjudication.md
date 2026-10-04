# Phase 0 adjudication

## Verdict: FAIL

Phase 0 is not complete. CI/deployment automation and Sentry are still missing, so explicit Phase 0 exit and acceptance criteria remain unmet. The previously reported health smoke failure was caused by the local function server not being served at the time: a fresh local GET and the two health tests now pass, so that is not an ongoing health-handler defect. The onboarding failure-compensation path remains insufficiently verified, the Deno runner still stops after the first failing directory, and required skill copies still differ.

## Scope and freshness

I reviewed the root blackboard and all four auditor handoffs, the gates record, the full Phase 0 specification, and the verifier/chair instructions. The conformance file lists all five subphases and all four phase-level exit criteria; its checklist is not a complete transcription of every plan bullet, so this adjudication relies on the source plan and corrects its overstatements.

The repository is `/Users/fahadasad/glowdesk`, branch `db/settings-catalogues`, HEAD `d9a94634b23d641ec2fff6bdd3fa14ac7f022aa0` (2026-10-04). The working tree is dirty: `packages/db/src/database.types.ts` and two tenancy test files are modified; two settings migrations and one settings test are untracked. The repository was not modified by this verification. The gate record in `gates/GATES.md:3-8` is for clean `main` at `2e22eff2a90c8f09e7d98534cb35e11c9df4a78c`, not this checkout. The current HEAD adds Phase 1 work and updates onboarding; the working-tree settings changes are outside the recorded gate run. No full gate suite was rerun, and the recorded gate totals must not be represented as results for the current checkout.

Fresh read-only checks on current HEAD confirmed: `.github/workflows/` remains absent; there is no Sentry SDK initialization or transport (the only function-side reporting seam still logs in `supabase/functions/_shared/logging.ts:38-45`); `package.json:15` still exits the Deno test loop on the first failed directory; and the three reported Cursor/Claude skill-copy differences remain. Current health verification is different from the historical gate result: `curl -i http://127.0.0.1:54321/functions/v1/health` returned HTTP 200, the expected envelope and `x-request-id`; `deno test --allow-all health_test.ts` in `supabase/functions/health` returned 2 passed, 0 failed. This is a focused read-only health check, not a rerun of all gates or onboarding tests.

## Accepted findings

### F-VERIFIER-1: CI and deployment workflows are missing
- Severity: blocker. Merges F-BE-1, F-FE-1, F-CONFORM-1, F-CONFORM-4, and F-FE-6/F-FE-10 where those duplicate CI drift enforcement.
- Location: no `.github/workflows/` in current HEAD; plan `/Users/fahadasad/glowdesk/plan/parts/11-delivery-plan.md:213-214,226-243`.
- Evidence: current tree inspection found no workflow files. The recorded gates prove some commands work locally (`gates/GATES.md:62-70`) but do not provide PR CI or the required staging-to-production deploy pipeline.
- Ruling: accepted. CI on a PR, automated clean-migration/type-drift checks, and the deployment pipeline are not implemented. The clean-migration gate is therefore not a recurring CI gate; results from a different, older snapshot do not satisfy the exit criterion for this checkout.
- Fix: add `.github/workflows/ci.yml` that installs the pinned toolchain and runs the clean-migration gate, type drift, Deno checks/tests, pgTAP, Vitest, lint, build, and size checks. Add `.github/workflows/deploy.yml` to promote migrations, functions using `--use-api`, and frontend from the same commit through staging and production.

### F-VERIFIER-2: Sentry is not integrated
- Severity: blocker, raised from the auditors' major rating because Phase 0.1 and 0.3 explicitly require Sentry capture (`plan/parts/11-delivery-plan.md:215,230,314-319`). Merges F-BE-3, F-FE-2, and F-CONFORM-2.
- Location: `supabase/functions/_shared/logging.ts:38-45`; no frontend or Deno Sentry initialization/configuration was found in current HEAD.
- Evidence: `captureException` only calls the structured console logger; the source comment says the transport is still to be wired. Search of current HEAD found no Sentry SDK import or initialization.
- Ruling: accepted. A cloud DSN/event cannot be verified locally, but the required local integration code is absent, so this is not merely an external-verification limitation.
- Fix: install and initialize the appropriate frontend and Deno Sentry SDKs, configure DSNs only through environment/secrets, wire `captureException` to send events, and demonstrate a deliberate error in staging.

### F-BE-5: Failed provisioning may leave a newly invited owner without a tenant
- Severity: major.
- Location: current `supabase/functions/onboarding/handlers.ts:127-142`; tests in `supabase/functions/onboarding/onboarding_test.ts:149-176` and `:202-215`.
- Evidence: HEAD now attempts `deleteUser(ownerId)` after an RPC error (`handlers.ts:135-142`), improving on the earlier audited snapshot. It ignores the deletion result, provides no durable cleanup/retry record, and there is still no failure-injection test that makes `provision_tenant` fail after a new invite. The added tests cover duplicate slugs and successful idempotent reruns, not that failure path. The atomic database transaction cannot roll back the preceding Auth invite.
- Ruling: accepted with changes. Do not describe the attempted compensation as a verified fix; it closes the normal success case but not cleanup failure or the untested failure path.
- Fix: only when this request created the Auth user, compensate after RPC failure; check the Auth deletion result and persist/report a retryable cleanup record if deletion fails. Add tests that force the RPC failure, assert the newly invited user is removed, assert cleanup failure is surfaced/retryable, and prove an existing user is never deleted.

### F-VERIFIER-4: The Deno test runner stops before later suites after a failure
- Severity: major.
- Location: root `package.json:15`.
- Evidence: the script ends each directory command with `|| exit 1`. The earlier run failed in `health/` and stopped before onboarding (`gates/fn-test.log:9-28`). Current HEAD adds onboarding tests but leaves the short-circuiting script unchanged; those tests were not rerun here.
- Ruling: accepted. A Deno suite failure hides the result of later suites and prevents the gate from demonstrating onboarding coverage.
- Fix: make `pnpm fn:test` run every function directory, collect per-directory exit codes, report each suite result, and return nonzero only after all suites have run.

### F-CONFORM-3: Cursor and Claude skill copies differ
- Severity: major.
- Location: `.cursor/skills/react-frontend/SKILL.md`, `.cursor/skills/react-frontend/reference.md`, `.cursor/skills/i18n-rtl/reference.md` and corresponding `.claude/skills/` files.
- Evidence: current read-only diffs still show differences in all three pairs. The plan appendix requires the copies to be identical (`plan/parts/15-appendix.md:21`; `plan/PLAN.md:5326`).
- Ruling: accepted. No ADR authorizes the copies to drift.
- Fix: reconcile the content, then synchronize the three `.claude/skills/` files with the implementation-accurate `.cursor/skills/` versions; add a check that fails when paired copies diverge.

### F-DB-3: Gate summary reports an incorrect migration count
- Severity: minor.
- Location: `gates/GATES.md:63,70` and `gates/db-reset.log:7-16`.
- Evidence: the summary says eleven migrations were applied, while the reset log enumerates ten migration files for the recorded gate snapshot.
- Ruling: accepted as a documentation defect; it does not indicate a schema failure.
- Fix: correct the two GATES.md summaries to the number enumerated in the raw log.

### F-DB-4: No positive pgTAP assertion for a valid IANA timezone
- Severity: minor.
- Location: `supabase/migrations/20261004170200_create_branches.sql:5-10`; `supabase/tests/001_tenancy_schema.test.sql:132-136`.
- Evidence: the listed test checks rejection of an offset timezone; the auditor found no positive assertion that an IANA zone is accepted.
- Ruling: accepted as a narrow test-coverage omission; implementation is separately tested against an invalid offset, but the positive acceptance case is not demonstrated.
- Fix: add pgTAP `lives_ok` coverage inserting branches with valid zones such as `Asia/Kuwait` and `America/New_York`.

### F-BE-7: The generic secret-auth environment variable is undocumented
- Severity: minor (reduced from major).
- Location: `supabase/functions/_shared/auth.ts:91-102`; `supabase/functions/.env.example:1-4`.
- Evidence: the generic secret-auth default is named `INTERNAL_FUNCTION_SECRET`, but the example documents only `PLATFORM_ADMIN_SECRET`. The current Phase 0 onboarding function explicitly configures the latter.
- Ruling: accepted as a developer-documentation gap, not a broken current Phase 0 function.
- Fix: document `INTERNAL_FUNCTION_SECRET` as a non-usable placeholder in `.env.example` and note that a per-function `SecretConfig` may override it. Do not include a production credential.

### F-VERIFIER-3: Health smoke depends on an already-served local function
- Severity: minor (reduced from blocker; not a health-handler defect).
- Location: `supabase/functions/health/health_test.ts:1-16`; historical failure `gates/fn-test.log:9-23`.
- Evidence: the old gate received 503/null because the local Functions server was not serving the function (`gates/GATES.md:91-105`). On this current machine, a GET returned 200 with the expected envelope and request ID, and the focused test rerun passed 2/2. Supabase's quickstart explicitly serves functions locally with `supabase functions serve`: https://supabase.com/docs/guides/functions/quickstart.
- Ruling: accepted with change to severity and scope. The earlier blocker claim that the current health handler fails is rejected; the smoke setup must ensure its dependency is running. The full Deno suite and current checkout gate were not rerun.
- Fix: make the health smoke harness start/await the local function server (or assert the required server prerequisite before running), then retain assertions for HTTP 200, envelope, and request ID.

## Rejected, merged, or no longer current findings

- F-DB-1 (untracked Phase 1 migrations) and F-DB-2 (seed references those tables): historically observed on a pre-merge working copy, but not present in the current state described by those findings. The four migrations are committed in the ancestor `bcc2819e22a686d1c0559698f63a882c9a28f116`; the tenant-catalogue and branch-provisioning migrations are committed at current HEAD `d9a94634b23d641ec2fff6bdd3fa14ac7f022aa0`. Their commit subjects identify Phase 1 database/onboarding work, and the seed's schema prerequisites are now tracked. Thus these are not current untracked-file/seed-to-missing-table defects. Separately, current uncommitted settings migrations/tests are noted in freshness above and were not gate-tested.
- F-DB-5 (`colleague_profiles()` behavior for callers with no tenants): reject as a defect. The function's tenant membership predicate returns no rows for a caller with no active tenant, and the outsider test documents that result (`supabase/tests/003_tenancy_matrix.test.sql:121-123`).
- F-BE-2 (idempotency test comment clarity): reject as a defect. The per-function uniqueness boundary is explicitly `(tenant_id, key, function_name)` and is consistent with ADR-31; using the same tenant and key with a different function name is the right case to test.
- F-BE-4: NOT VERIFIABLE LOCALLY, not failed. `supabase/functions/monitors.json` defines monitor targets, but actual external monitoring needs staging/operations evidence. Hosted log-drain delivery is likewise NOT VERIFIABLE LOCALLY; it is not a separate database finding. The missing Sentry integration remains F-VERIFIER-2.
- F-BE-6 (application rate limiting): reject as a defect; ADR-47 defers application-level limits to Phase 9 and permits relying on platform limits for the MVP.
- F-BE-8 (hardcoded local test JWT fallbacks): reject as a production-secret finding. The values are local Supabase development defaults used by test helpers, not production credentials; Supabase's CLI documentation itself shows local anon/service-role keys and provides `supabase status` output: https://supabase.com/docs/reference/cli/supabase-status. No secret value is repeated here.
- F-BE-9 (validation contract test naming): reject; the Deno import-map contract test exists and ran in the recorded `_shared` suite; no failing behavior was shown.
- F-FE-3 (missing `apps/back-office/.env.example`): reject as stale. The file exists in the current repository.
- F-FE-4 (directional token in a schedule-x custom CSS variable): reject as a demonstrated defect. A custom-property identifier containing “left” is not itself a physical CSS property; the auditor supplied no RTL rendering failure. Keep the calendar RTL behavior in normal Phase 5 verification.
- F-CONFORM-5 (missing no-access test): reject. The recorded Playwright run includes the no-access path in English and Arabic (`gates/playwright.log:10,18,26-28`); all 20 tests passed.
- Calendar keyboard-navigation gap: reject for Phase 0; ADR-41 explicitly assigns the remaining gap to Phase 5 (`plan/decisions.md:576-596`; `plan/evidence/0.5/results.md:38-47`).
- F-DB-2/F-DB-3 in the prior adjudication referred to pulled-forward branches and the minimal `provision_tenant` RPC, not the database auditor's differently numbered findings. Those two implementation choices are DEVIATED-JUSTIFIED: the migration headers disclose their Phase 0 composite-FK/onboarding purpose (`20261004170200_create_branches.sql:1-2`; `20261004172000_create_provision_tenant.sql:1-4`).
- No-access, per-function idempotency, the validation-contract test, and rate-limiting comments are not additional findings. Duplicate CI/type-drift findings are merged into F-VERIFIER-1.

## Checklist corrections and acceptance criteria

The plan section `/Users/fahadasad/glowdesk/plan/parts/11-delivery-plan.md:202-393` has five subphases (0.1-0.5) and four phase-level exit criteria. All are considered below; the conformance checklist alone was not accepted as exhaustive.

| Scope | Verified status | Evidence / ruling |
|---|---|---|
| Phase exit: CI green on a trivial PR | NOT MET | No workflow files; F-VERIFIER-1. |
| Phase exit: staging-to-production deploy | NOT MET | No deployment workflow; actual hosted deployment is not locally verifiable. |
| Phase exit: clean-migration gate | NOT MET AS A RECURRING GATE | Reset, pgTAP, lint, and type-drift passed in the historical gate record; no CI gate exists and that record is not current checkout evidence (`GATES.md:62-70`). |
| Phase exit: ADR-41 spike verdict | DONE | ADR-41 and `plan/evidence/0.5/results.md:12-21` record the justified fallback verdict. |
| 0.1 repository/environment foundation | INCOMPLETE | Monorepo and local config exist, but CI/deploy and Sentry integration are missing. Staging/production setup, external monitor firing, production region/legal approval, and hosted log-drain are NOT VERIFIABLE LOCALLY. |
| 0.2 tenancy/auth acceptance | DONE WITH FIXES | Historical pgTAP 149/149 and Playwright 20/20 evidence is positive (`GATES.md:64,69,76,80-81`); current onboarding code now compensates after RPC error but does not verify cleanup success or test the forced-failure path (F-BE-5). The stale local gate evidence does not cover current checkout. |
| 0.3 Edge Function platform acceptance | INCOMPLETE | Local health route and focused health tests now pass, and validation import was tested in the historical `_shared` suite. Sentry is absent; the Deno test runner still short-circuits; staged health/Sentry evidence is unavailable. |
| 0.4 frontend acceptance | DONE WITH FIXES | Historical verify and Playwright suites passed (`verify.log:4-12`; `playwright.log:3-28`), but recurring CI/type-drift enforcement is missing and skill copies differ. Current checkout was not fully gated. |
| 0.5 calendar spike | DONE | ADR-41 fallback verdict and evidence are recorded; remaining keyboard work belongs to Phase 5. |

The recorded gates were: install PASS; initial database reset PASS; pgTAP PASS (149); database lint PASS; type drift PASS; Deno tests FAIL (38 passed, 2 health tests failed in that environment, onboarding was not reached); `pnpm verify` PASS (79 Vitest tests plus typecheck/lint/build/size); Playwright PASS (20); final database reset PASS. These are historical results from `main` at `2e22eff`, not results for current HEAD. The targeted health rerun is 2/2 passing, but no full current-checkout gate suite was run.

## Deviations and external verification

- Calendar scheduler: DEVIATED-JUSTIFIED. ADR-41 documents the no-license decision and authorizes the tested core/custom-resource fallback.
- Branches and the minimal tenant-provisioning RPC: DEVIATED-JUSTIFIED. The migrations disclose the Phase 0 composite-FK and onboarding prerequisites.
- Cursor/Claude skill-copy drift: DEVIATED-UNJUSTIFIED (F-CONFORM-3).
- CI/deploy and Sentry omissions are missing requirements, not justified deviations.
- Staging/production deployment, staged health/Sentry events, external uptime-monitor firing, hosted log-drain delivery, and ADR-48 production-region/legal approval are NOT VERIFIABLE LOCALLY. Verify later using CI logs, deployment/run IDs, a staged health response with request ID, a Sentry event, and operational monitoring/log-drain evidence. Missing local Sentry code and deploy workflow remain findings, not unverifiable items.

## Ordered fix list

1. F-VERIFIER-1 (blocker): add `.github/workflows/ci.yml` and `deploy.yml` with the Phase 0 recurring checks and same-commit staging-to-production pipeline.
2. F-VERIFIER-2 (blocker): integrate frontend and Deno Sentry, wire `captureException`, and demonstrate a staged error event.
3. F-BE-5 (major): check compensating user deletion, record/retry cleanup failures, and add failure-injection tests proving no orphan remains and existing users are not deleted.
4. F-VERIFIER-4 (major): run every Deno function suite and aggregate/reveal all results before returning nonzero.
5. F-CONFORM-3 (major): synchronize the three `.claude/skills/` files with the implementation-accurate `.cursor/skills/` copies and prevent future drift.
6. F-DB-3 (minor): correct the migration count in `gates/GATES.md` to match the raw reset log.
7. F-DB-4 (minor): add pgTAP acceptance tests for valid IANA time zones.
8. F-BE-7 (minor): document `INTERNAL_FUNCTION_SECRET` as a placeholder and describe `SecretConfig` overrides.
9. F-VERIFIER-3 (minor): make the health smoke harness start or explicitly require a served local function before making requests.
