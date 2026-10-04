# Phase 0 audit report: Foundation

## Verdict: FAIL

Phase 0 is not complete. The repository still has no CI or deployment workflows, and Sentry is not integrated, so required phase exit criteria are unmet. Three more issues need correction: onboarding can still leave a newly invited owner without a tenant if provisioning and cleanup fail, the Deno test command stops at the first failed suite, and three required Cursor/Claude skill pairs differ. The verifier accepted 2 blockers, 3 majors, and 4 minors. Some local checks passed, but the full gate run belongs to an older checkout and was not repeated against the current working tree.

| Subphase | Status |
|---|---|
| 0.1 Repository and environments | Incomplete |
| 0.2 Tenancy and security skeleton | Done with fixes |
| 0.3 Edge Function platform | Incomplete |
| 0.4 Frontend platform | Done with fixes |
| 0.5 Calendar library spike | Done |

The authoritative adjudication, including rechecked evidence and rejected findings, is `adjudication.md`. Domain-level audit notes are in `backend.md`, `frontend.md`, `database.md`, and `conformance.md`.

## What was audited

The audit covers all of Phase 0, including subphases 0.1–0.5 and the phase-level exit criteria, in `/Users/fahadasad/glowdesk/plan/parts/11-delivery-plan.md:190-393`. ADRs take precedence over the plan, then `PLAN.md`, `CONVENTIONS.md`, and the repository skills, as specified in `briefs/common.md`.

The repository is `/Users/fahadasad/glowdesk`. At verification, it was on branch `db/settings-catalogues`, at commit `d9a94634b23d641ec2fff6bdd3fa14ac7f022aa0` (2026-10-04). The working tree was dirty: `packages/db/src/database.types.ts` and two tenancy test files were modified; two settings migrations and one settings test were untracked. The verifier did not modify the repository. The saved gate run instead used clean `main` at `2e22eff2a90c8f09e7d98534cb35e11c9df4a78c`; its results are historical, not evidence that the current checkout passed the full suite (`adjudication.md:7-13`; `gates/GATES.md:3-8`).

The verifier rechecked the current checkout read-only. It confirmed that workflow files and Sentry wiring remain absent, `package.json:15` still short-circuits the Deno test loop, and three skill-copy pairs still differ. It also made a focused current health check: `GET http://127.0.0.1:54321/functions/v1/health` returned HTTP 200 with the expected envelope and request ID, and `deno test --allow-all health_test.ts` passed 2/2. This was not a full gate rerun or an onboarding test run (`adjudication.md:13`).

## Gates

The saved results below are from clean `main` at `2e22eff`, not the current checkout (`gates/GATES.md:58-81`; `adjudication.md:11-13`).

| Command | Result | Key detail |
|---|---|---|
| `pnpm install --frozen-lockfile` | PASS | All nine workspace projects resolved (`GATES.md:62`). |
| `pnpm db:reset` (initial) | PASS | Reset and seed succeeded. The summary says 11 migrations, but the raw log enumerates 10; see F-DB-3 (`GATES.md:63`; `db-reset.log:7-16`; `adjudication.md:52-57`). |
| `pnpm db:test` (pgTAP) | PASS | 149 tests passed (`GATES.md:64,74-76`). |
| `pnpm db:lint` | PASS | No schema errors (`GATES.md:65`). |
| Generated type drift check | PASS | Generated types matched the committed file for that snapshot (`GATES.md:66,107-108`). |
| `pnpm fn:test` (Deno) | FAIL | 35 `_shared` tests and 3 template tests passed; health was 0/2 because the functions server was not serving the route. The command stopped before later suites (`GATES.md:67,77-79`; `fn-test.log:9-28`). A focused health rerun on the current checkout passed 2/2, but the full command was not rerun. |
| `pnpm verify` | PASS | Typecheck, lint, CSS lint, 79 Vitest tests, build, and size checks passed (`GATES.md:68`; `verify.log:3-12`). |
| Playwright suite | PASS | 20 tests passed, 10 each in English and Arabic (`GATES.md:69,80-82`; `playwright.log:3-28`). |
| `pnpm db:reset` (final) | PASS | Reset and seed succeeded; the same migration-count discrepancy applies (`GATES.md:70`; `db-reset.log:7-16`). |

The historical clean database reset and pgTAP results show those checks worked on that snapshot. They do not satisfy the recurring CI clean-migration criterion, and do not establish that the current dirty checkout passes.

## Exit and acceptance criteria

### Phase-level exit criteria

| Criterion | Status | Evidence |
|---|---|---|
| CI is green on a trivial PR touching a function and a component | NOT MET | No `.github/workflows/` exists in current HEAD; F-VERIFIER-1. The saved local commands are not a PR workflow (`adjudication.md:17-22`). |
| Deploy pipeline promotes staging to production with functions and migrations | NOT MET | No deployment workflow exists; the same-commit pipeline is required by the plan (`plan/parts/11-delivery-plan.md:213,228`; `adjudication.md:17-22`). |
| Clean-migration gate passes end to end from an empty database on the pinned CLI | NOT MET AS A RECURRING GATE | Historical reset, pgTAP, lint, and type drift passed, but no CI workflow runs the gate and the record is for a different checkout (`GATES.md:62-70`; `adjudication.md:11,20-22`). |
| Spike verdict is recorded in ADR-41 with evidence | DONE | ADR-41 and `plan/evidence/0.5/results.md:12-21` record the fallback verdict and evidence (`adjudication.md:105,110`). |

### Subphase acceptance criteria

| Criterion | Subphase | Status | Evidence |
|---|---:|---|---|
| CI green on a trivial PR | 0.1 | NOT MET | No CI workflow; F-VERIFIER-1. |
| Staging-to-production deployment | 0.1 | NOT MET | No deploy workflow; F-VERIFIER-1. Hosted deployment also cannot be verified locally. |
| Clean-migration gate passes and rejects `sql/drafts-v1/` references | 0.1 | NOT MET AS A RECURRING GATE | Historical local database checks passed on the prior snapshot; no CI gate exists. |
| Sentry captures a deliberate error; uptime monitor fires on simulated downtime | 0.1 | SENTRY NOT MET; MONITOR NOT VERIFIABLE LOCALLY | Sentry code is absent (F-VERIFIER-2). Actual external monitor firing requires operational evidence; monitor targets are configured (`adjudication.md:23-29,85`). |
| Member logs in and sees shell in English and Arabic; user without membership sees no-access | 0.2 | DONE ON SAVED GATE SNAPSHOT | Playwright passed in both locales, including no-access (`playwright.log:7,10,15,18`; `adjudication.md:107`). Current checkout was not fully gated. |
| pgTAP proves tenant isolation, profile privacy, tenant write restriction, and immediate revocation | 0.2 | DONE ON SAVED GATE SNAPSHOT | 149 pgTAP tests passed; verifier confirmed relevant test coverage (`GATES.md:64,76`; `adjudication.md:107`). |
| Staged health route returns 200 with request ID | 0.3 | NOT MET | Staging deployment is absent. Current local GET and focused health tests pass, but do not prove staged behavior (`adjudication.md:13,73-78`). |
| Sentry captures an unhandled staged function error | 0.3 | NOT MET | No Sentry SDK or transport is wired (F-VERIFIER-2). |
| `packages/validation` schemas import from Deno | 0.3 | DONE LOCALLY; CI NOT MET | The validation contract test ran in the historical `_shared` suite; recurring CI is absent (`GATES.md:67,77`; `adjudication.md:13,88`). |
| Money and UTC date format correctly for English and Arabic/Asia-Kuwait | 0.4 | DONE ON SAVED GATE SNAPSHOT | Formatter assertions are in `packages/i18n/src/format.test.ts:8-50`; `pnpm verify` passed (`verify.log:8`; `adjudication.md:109`). |
| Shell renders in English and Arabic with correct direction; login is the entry point | 0.4 | DONE ON SAVED GATE SNAPSHOT | Playwright passed in both locale projects (`playwright.log:3-28`; `adjudication.md:109`). |
| All named packages build and pass Vitest | 0.4 | DONE ON SAVED GATE SNAPSHOT | `pnpm verify` passed with 79 Vitest tests and build (`verify.log:4-12`). The plan says five but lists six packages (`plan/parts/11-delivery-plan.md:356`). |
| CI drift check keeps `database.types.ts` current | 0.4 | NOT MET | The historical local type-drift check passed, but no CI workflow enforces it (F-VERIFIER-1; `adjudication.md:13,109`). |
| ADR-41 verdict and evidence are recorded; fallback documents API and gaps if premium is no-go | 0.5 | DONE | ADR-41 authorizes the fallback; evidence is recorded. Remaining keyboard navigation is assigned to Phase 5 (`plan/evidence/0.5/results.md:12-21`; `adjudication.md:110,116`). |

## Plan checklist

Statuses below reflect the verifier's rulings. `NOT VERIFIABLE LOCALLY` means the item requires cloud or operational evidence; it is not a local failure unless required implementation is missing. Phase 0 plan source: `plan/parts/11-delivery-plan.md:202-393`.

### Subphase 0.1: Repository and environments

- Goal: INCOMPLETE. The monorepo and local setup exist, but CI/deployment workflows and Sentry are missing.
- Features: PARTIAL. pnpm monorepo and local Supabase configuration exist. Required CI and deployment workflows and Sentry integration are absent. Staging/production project setup, preview branches, paid-plan status, production region/legal approval, and hosted observability are NOT VERIFIABLE LOCALLY.
- Database work: DONE AS SPECIFIED. No database work is required in 0.1 (`:218`).
- Edge Functions: NONE SPECIFIED (`:220`).
- Screens: NONE SPECIFIED (`:222`).
- i18n/RTL: NONE SPECIFIED (`:224`).
- Acceptance criteria: INCOMPLETE. CI, deployment, recurring clean-migration checks, and Sentry capture are missing. Actual uptime-monitor firing is NOT VERIFIABLE LOCALLY (`:226-230`).
- Tests: INCOMPLETE. No CI workflow self-test or staging deploy dry-run can run without the required workflows (`:232`).
- Dependencies: NONE (`:234`).
- Backlog: PARTIAL. Local scaffold and verification exist; CI/deploy/Sentry are missing. Staging/production setup, external uptime monitor firing, log-drain, and region/legal checks are NOT VERIFIABLE LOCALLY. `.env.example` also omits the generic `INTERNAL_FUNCTION_SECRET` (F-BE-7; `adjudication.md:66-71`).

### Subphase 0.2: Tenancy and security skeleton

- Goal: DONE WITH FIXES. Core RLS/auth foundation and test harness are present; onboarding failure cleanup is not fully handled or verified (F-BE-5).
- Features: DONE WITH FIXES. Email/password auth, session and password-reset flows, route guards, tenancy helpers, branch-scoped RLS, all-branches representation, audit machinery, and no-access path are present. The owner-invite failure case remains unresolved (`adjudication.md:31-36,107`).
- Database work: DONE. Tenancy schema, helpers, settings, audit log, idempotency, composite foreign keys, and pgTAP coverage are present. 149 tests passed on the saved snapshot. Branches and the minimal provisioning RPC were pulled forward with rationale disclosed in migration headers (`GATES.md:64,76`; `adjudication.md:93,107,117`).
- Edge Functions: DONE WITH FIXES. Onboarding exists and now attempts to delete a newly invited owner after RPC failure, but ignores deletion failure and lacks failure-injection coverage (`handlers.ts:127-142`; `onboarding_test.ts:149-176,202-215`; `adjudication.md:31-36`).
- Screens: DONE ON SAVED GATE SNAPSHOT. Login, password reset, shell, no-access, 403, and 404 flows are implemented and exercised (`frontend.md:50-82,248-258`; `playwright.log:3-28`).
- i18n/RTL: DONE FOR SPECIFIED PATH ON SAVED GATE SNAPSHOT. English/Arabic shell and no-access journeys passed (`playwright.log:3-28`).
- Acceptance criteria: DONE WITH FIXES. Membership, no-access, tenant isolation, profile privacy, tenant write restriction, and revocation are covered on the saved snapshot; onboarding orphan cleanup remains unverified (`adjudication.md:31-36,107`).
- Tests: DONE LOCALLY ON SAVED SNAPSHOT; CI MISSING. pgTAP and Playwright passed, but no workflow runs them on changes (`GATES.md:64,69`; F-VERIFIER-1).
- Dependencies: 0.1 is PARTIAL. Local repository and Supabase foundation exist, but CI/environment delivery requirements are unmet (`:280`).
- Backlog: DONE WITH FIXES. The database, auth screens, shell, and test harness are substantially delivered; CI and onboarding failure cleanup remain open (`:282-291`; F-BE-5).

### Subphase 0.3: Edge Function platform

- Goal: INCOMPLETE. Shared function infrastructure exists, but Sentry and staged health evidence are missing; the test command also hides later suite results after a failure.
- Features: PARTIAL. Wrapper, response envelope, logging, CORS, idempotency, validation import, template, health route, and monitor configuration exist. Sentry transport does not (`adjudication.md:23-29,38-43`).
- Database work: DONE AS SPECIFIED. None is required (`:305`).
- Edge Functions: INCOMPLETE. Focused current local health route and tests pass, but staging is not demonstrated. The saved full gate health tests failed because the Functions server was not serving the route; F-VERIFIER-3 requires fixing the smoke harness, not the health handler (`adjudication.md:73-78`).
- Screens: NONE SPECIFIED (`:312`).
- i18n/RTL: NONE SPECIFIED (`:313`).
- Acceptance criteria: INCOMPLETE. Staged health response and staged Sentry event are not demonstrated; Deno validation import works locally (`adjudication.md:73-78,88`).
- Tests: INCOMPLETE. Saved results: `_shared` 35/35 and template 3/3 passed; health was 0/2 when no function server was serving it. The runner exits on the first failing directory, so later suites are hidden (`GATES.md:67,77-79`; F-VERIFIER-4). Focused health rerun passed 2/2 but the full test command was not rerun (`adjudication.md:13`).
- Dependencies: 0.2 is substantially present; the CI dependency from 0.1 is unmet (`:321`).
- Backlog: PARTIAL. Shared modules, validation contract, template, health route, and monitor config exist; Sentry, reliable suite reporting, and staged verification remain open (`:323-327`).

### Subphase 0.4: Frontend platform

- Goal: DONE WITH FIXES. Shell, package foundation, and i18n/RTL baseline are implemented; recurring CI drift enforcement and skill-copy synchronization are missing.
- Features: DONE. Router, session context, tenant/branch switchers, login/reset and deep-link restore, UI primitives, typed clients, and formatter helpers are present (`frontend.md:104-175,241-258`).
- Database work: DONE AS SPECIFIED. None is required; frontend consumes the 0.2 schema (`:343`).
- Edge Functions: NONE SPECIFIED.
- Screens: DONE ON SAVED GATE SNAPSHOT. Shell, switchers, login/reset, no-access and error screens are present and tested (`frontend.md:50-90,160-175`).
- i18n/RTL: DONE ON SAVED GATE SNAPSHOT. English/Arabic catalogs, `dir`/`lang`, logical CSS lint, money/date formatting, and RTL handling are present (`frontend.md:176-232`).
- Acceptance criteria: DONE LOCALLY ON SAVED SNAPSHOT. Formatter, locale, build and Playwright checks passed; type drift is not enforced in CI (`verify.log:4-12`; `playwright.log:3-28`; `adjudication.md:109`).
- Tests: PARTIAL. Historical Vitest, Playwright, and local type-drift checks passed; current checkout lacks recurring CI enforcement (`GATES.md:66,68-69`; F-VERIFIER-1).
- Dependencies: 0.1 is PARTIAL because required CI is absent; auth foundation from 0.2 exists (`:360`).
- Backlog: DONE WITH FIXES. Shell, screens, packages, formatters, and Playwright suite exist. CI enforcement and skill-copy synchronization remain (`:362-368`; F-CONFORM-3).

### Subphase 0.5: Calendar library spike

- Goal: DONE. ADR-41 records the tested fallback verdict and evidence (`plan/evidence/0.5/results.md:12-21`).
- Features: DEVIATED-JUSTIFIED. Premium was not evaluated because no license was available; ADR-41 authorizes the core/custom-resource fallback (`adjudication.md:92,116`).
- Database work: NONE SPECIFIED.
- Edge Functions: NONE SPECIFIED.
- Screens: NONE SPECIFIED.
- i18n/RTL: NONE SPECIFIED.
- Acceptance criteria: DONE. Verdict, fallback wrapper surface, evidence, and gap list are recorded. Remaining keyboard-navigation work belongs to Phase 5 (`adjudication.md:92,110,116`).
- Tests: DONE AS SPIKE EVIDENCE. Performance traces, screenshots, keyboard/RTL results, and prototype evidence are referenced in `plan/evidence/0.5/results.md:12-21`.
- Dependencies: 0.4 exists; its overall status remains done with fixes (`:387`; `adjudication.md:109-110`).
- Backlog: DONE WITH JUSTIFIED FALLBACK. The fallback was implemented; premium evaluation was waived under ADR-41 (`:389-392`; `adjudication.md:92`).

## Deviations

- Calendar scheduler: DEVIATED-JUSTIFIED. ADR-41 explains why premium was not evaluated and authorizes the fallback; evidence supports the decision (`adjudication.md:92,116`).
- Branches table and minimal `provision_tenant` RPC: DEVIATED-JUSTIFIED. These Phase 1 elements were pulled forward to support Phase 0 composite-FK and onboarding needs; migration headers disclose the rationale (`adjudication.md:93,117`).
- Cursor/Claude skill copies: DEVIATED-UNJUSTIFIED. Three paired files differ despite the plan appendix requiring identical copies (F-CONFORM-3; `adjudication.md:45-50`).
- CI/deployment and Sentry omissions are missing requirements, not justified deviations.
- Application-level rate limiting is DEVIATED-JUSTIFIED by ADR-47, which defers it to Phase 9 (`adjudication.md:86`).

## Findings

### Blockers

#### F-VERIFIER-1: CI and deployment workflows are missing
- Location: No `.github/workflows/` in the current repository; requirements at `plan/parts/11-delivery-plan.md:213-214,226-243`.
- Problem: No PR CI runs the required quality, clean-migration, or type-drift checks, and no workflow deploys migrations, functions, and frontend from the same commit. Required exit criteria are unmet.
- Evidence: Current tree inspection found no workflow files. The saved local gates are not CI and were run against a different snapshot (`adjudication.md:11,17-22`).
- Fix: Add `.github/workflows/ci.yml` with the pinned toolchain, clean-migration and `sql/drafts-v1/` checks, generated-type drift, function checks/tests, pgTAP, Vitest, lint, build, and size checks. Add `.github/workflows/deploy.yml` to promote migrations, functions using `--use-api`, and frontend from the same commit through staging and production.

#### F-VERIFIER-2: Sentry is not integrated
- Location: `supabase/functions/_shared/logging.ts:38-45`; no frontend or Deno Sentry initialization/configuration in current HEAD.
- Problem: `captureException` only logs locally; Phase 0.1 and 0.3 require Sentry capture (`plan/parts/11-delivery-plan.md:215,230,314-319`).
- Evidence: The logging implementation has no Sentry transport, and the current code search found no Sentry SDK import or initialization (`adjudication.md:24-29`).
- Fix: Install and initialize appropriate frontend and Deno Sentry SDKs, configure DSNs through environment/secrets, wire `captureException` to send events, and demonstrate a deliberate staged error.

### Major findings

#### F-BE-5: Failed provisioning may leave a newly invited owner without a tenant
- Location: `supabase/functions/onboarding/handlers.ts:127-142`; tests at `onboarding_test.ts:149-176,202-215`.
- Problem: After a provisioning RPC error the handler attempts to delete a newly invited user, but ignores deletion failure and has no durable retry path. No failure-injection test exercises this path. The Auth invite happens before the database transaction, so the transaction cannot roll it back.
- Evidence: The current handler's compensation is best-effort; existing tests cover duplicate slugs and successful idempotent reruns, not forced RPC or cleanup failure (`adjudication.md:31-36`).
- Fix: Compensate only when this request created the Auth user; check deletion results and persist/report retryable cleanup if deletion fails. Add tests that force RPC failure, verify successful cleanup, verify cleanup failure is retryable, and prove an existing user is never deleted.

#### F-VERIFIER-4: Deno test runner stops before later suites after a failure
- Location: Root `package.json:15`.
- Problem: The command exits on the first failed function directory, hiding the outcomes of later suites, including onboarding.
- Evidence: The historical health failure stopped the run before onboarding (`gates/fn-test.log:9-28`). Current HEAD adds onboarding tests but leaves the short-circuiting script unchanged (`adjudication.md:38-43`).
- Fix: Change `pnpm fn:test` to run every function directory, collect and report each exit code, and return nonzero only after all suites finish.

#### F-CONFORM-3: Cursor and Claude skill copies differ
- Location: `.cursor/skills/react-frontend/SKILL.md`, `.cursor/skills/react-frontend/reference.md`, `.cursor/skills/i18n-rtl/reference.md` and corresponding `.claude/skills/` files.
- Problem: Three pairs differ, despite the plan requiring the copies to be identical.
- Evidence: Current read-only diffs still show all three differences; no ADR authorizes this drift (`adjudication.md:45-50`).
- Fix: Reconcile the content, synchronize the `.claude/skills/` copies to the implementation-accurate `.cursor/skills/` files, and add a check that fails when a pair diverges.

### Minor findings

#### F-DB-3: Gate summary reports an incorrect migration count
- Location: `gates/GATES.md:63,70`; raw `gates/db-reset.log:7-16`.
- Problem: The summary reports eleven applied migrations; the raw log enumerates ten for the saved gate snapshot.
- Evidence: The raw migration log is the source of the count (`adjudication.md:52-56`).
- Fix: Correct both reset summaries in `GATES.md` to match the ten migrations enumerated in the raw log.

#### F-DB-4: No positive pgTAP assertion for a valid IANA timezone
- Location: `supabase/migrations/20261004170200_create_branches.sql:5-10`; `supabase/tests/001_tenancy_schema.test.sql:132-136`.
- Problem: The test rejects an offset timezone but does not demonstrate that a valid IANA timezone is accepted.
- Evidence: The verifier found no positive assertion for a valid zone (`adjudication.md:59-64`).
- Fix: Add pgTAP `lives_ok` coverage inserting branches with valid zones such as `Asia/Kuwait` and `America/New_York`.

#### F-BE-7: `INTERNAL_FUNCTION_SECRET` is undocumented
- Location: `supabase/functions/_shared/auth.ts:91-102`; `supabase/functions/.env.example:1-4`.
- Problem: The generic secret-auth default is named `INTERNAL_FUNCTION_SECRET`, but the example documents only `PLATFORM_ADMIN_SECRET`.
- Evidence: The current Phase 0 onboarding function configures `PLATFORM_ADMIN_SECRET`; the generic default remains undocumented (`adjudication.md:66-71`).
- Fix: Document `INTERNAL_FUNCTION_SECRET` as a non-usable placeholder in `.env.example` and state that a per-function `SecretConfig` may override it. Do not include a production credential.

#### F-VERIFIER-3: Health smoke depends on an already-served local function
- Location: `supabase/functions/health/health_test.ts:1-16`; historical failure in `gates/fn-test.log:9-23`.
- Problem: The old smoke run received 503/null because the local Functions server was not serving the route. The current handler itself is not shown to be defective.
- Evidence: Current local GET returned 200 with the expected envelope and request ID; focused health tests passed 2/2. This is not a full suite rerun. Supabase's quickstart documents serving functions locally: https://supabase.com/docs/guides/functions/quickstart (`adjudication.md:73-78`).
- Fix: Make the health smoke harness start and await the local Functions server, or assert the server prerequisite before making requests; retain checks for HTTP 200, response envelope, and `x-request-id`.

### Rejected, merged, or no longer current findings

- F-DB-1 and F-DB-2, the earlier claims about untracked Phase 1 migrations and a seed referencing missing tables, are no longer current. Those migrations are now committed in ancestors/current HEAD, and the seed prerequisites are tracked. Current uncommitted settings migrations/tests remain outside the saved gate evidence (`adjudication.md:82`).
- F-DB-5, the claim that `colleague_profiles()` is unsafe for callers with no tenants, is rejected: the membership predicate returns no rows and the outsider test covers that behavior (`003_tenancy_matrix.test.sql:121-123`; `adjudication.md:83`).
- F-BE-2, idempotency test comment clarity, is rejected: the `(tenant_id, key, function_name)` boundary matches ADR-31 (`adjudication.md:84`).
- F-BE-4, external uptime monitor firing, and hosted log-drain delivery are NOT VERIFIABLE LOCALLY, not failed implementation findings. Monitor targets exist; the missing Sentry code is separately accepted as F-VERIFIER-2 (`adjudication.md:85`).
- F-BE-6, application-level rate limiting, is rejected under ADR-47, which defers it to Phase 9 (`adjudication.md:86`).
- F-BE-8, local test JWT fallback values, is rejected as a production-secret finding: they are local Supabase development defaults, not production credentials. No values are reproduced here (`adjudication.md:87`).
- F-BE-9, validation contract test naming, is rejected: the Deno import-map contract test exists and ran in the saved `_shared` suite (`adjudication.md:88`).
- F-FE-3, missing `apps/back-office/.env.example`, is stale; the file exists in the current repository (`adjudication.md:89`).
- F-FE-4, the calendar CSS custom-property identifier containing “left,” is not a demonstrated physical-property or RTL defect (`adjudication.md:90`).
- F-CONFORM-5, missing no-access test, is rejected: the saved Playwright run covers no-access in English and Arabic (`playwright.log:10,18`; `adjudication.md:91`).
- The remaining calendar keyboard-navigation gap is assigned to Phase 5 by ADR-41, not Phase 0 (`plan/decisions.md:576-596`; `plan/evidence/0.5/results.md:38-47`; `adjudication.md:92`).
- Duplicate CI/type-drift findings are merged into F-VERIFIER-1. The prior branch/RPC forward-pull findings were justified and disclosed in migration headers (`adjudication.md:93-94`).

## Not verifiable locally

Staging/production configuration and deployment, staged health and Sentry events, external uptime-monitor firing, hosted log-drain delivery, and ADR-48 production-region/legal approval require cloud or operations evidence. Verify them with CI logs, deployment/run IDs, a staged health response with request ID, a Sentry event, monitor firing evidence, log-drain evidence, and the required region/legal approval. Missing local CI/deploy workflows and Sentry integration remain code findings, not unverifiable items (`adjudication.md:114-120`).

## Fix prompt

```text
Fix the Phase 0 audit findings below in /Users/fahadasad/glowdesk, in order.
Context: @plan/parts/11-delivery-plan.md @plan/decisions.md @plan/CONVENTIONS.md
Skills: /feature-delivery /spa-domain-glossary /spa-platform-architecture /supabase-database /supabase-edge-functions /react-frontend /i18n-rtl

1. F-VERIFIER-1: Add .github/workflows/ci.yml with the pinned clean-migration gate, generated-type drift, Deno checks/tests, pgTAP, Vitest, lint, build, and size checks. Add .github/workflows/deploy.yml to promote migrations, functions using --use-api, and frontend from the same commit through staging and production.
2. F-VERIFIER-2: Integrate and initialize Sentry for the frontend and Deno functions, configure DSNs only through environment/secrets, wire supabase/functions/_shared/logging.ts captureException to Sentry, and demonstrate a deliberate staged error event.
3. F-BE-5: In supabase/functions/onboarding/handlers.ts, compensate for provision_tenant failure only when this request invited the owner; check deletion results and persist/report cleanup failures for retry. Add failure-injection tests for RPC failure, cleanup failure, and protection of existing users.
4. F-VERIFIER-4: Change the root Deno test runner to run every function suite, report each result, aggregate failures, and return nonzero only after all suites finish.
5. F-CONFORM-3: Synchronize .claude/skills/react-frontend/SKILL.md, .claude/skills/react-frontend/reference.md, and .claude/skills/i18n-rtl/reference.md with the implementation-accurate .cursor/skills copies, and add a drift check.

Rules: never edit an applied migration; add a new migration if schema changes are needed. Keep both skill copies identical. Use Conventional Commits. Done means every audit gate passes again on the fixed checkout and each fixed acceptance criterion is demonstrated by a test. Attach staging deployment, health, Sentry, uptime, and log-drain evidence where cloud verification is required.
```

## Finding summary

| ID | Severity | Title |
|---|---|---|
| F-VERIFIER-1 | Blocker | CI and deployment workflows are missing |
| F-VERIFIER-2 | Blocker | Sentry is not integrated |
| F-BE-5 | Major | Failed provisioning may leave an invited owner without a tenant |
| F-VERIFIER-4 | Major | Deno runner stops before later suites after a failure |
| F-CONFORM-3 | Major | Cursor and Claude skill copies differ |
| F-DB-3 | Minor | Gate summary reports an incorrect migration count |
| F-DB-4 | Minor | No positive pgTAP assertion for a valid IANA timezone |
| F-BE-7 | Minor | `INTERNAL_FUNCTION_SECRET` is undocumented |
| F-VERIFIER-3 | Minor | Health smoke depends on an already-served local function |

Count: 2 blockers, 3 majors, 4 minors.
