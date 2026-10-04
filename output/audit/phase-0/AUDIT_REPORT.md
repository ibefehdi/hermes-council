# Phase 0 audit report: Foundation

## Verdict: FAIL

Phase 0 is not complete. The audit accepted three blockers: the repository has no CI or deployment workflows, Sentry is not wired, and the local health-function smoke test fails. The onboarding provisioning failure path, the Deno test runner's early exit, and mismatched Cursor/Claude skill copies are major findings. The implementation has substantial passing work in tenancy, frontend, and the calendar spike, but these gaps prevent phase exit. The recorded gate results are historical: they were run on an earlier commit, not the current checkout.

| Subphase | Status |
|---|---|
| 0.1 Repository and environments | Incomplete |
| 0.2 Tenancy and security skeleton | Done with fixes |
| 0.3 Edge Function platform | Incomplete |
| 0.4 Frontend platform | Done with fixes |
| 0.5 Calendar library spike | Done |

The verifier's authoritative rulings and evidence are in `adjudication.md`. Detailed domain audits are in `database.md`, `backend.md`, `frontend.md`, and `conformance.md`.

## What was audited

The audit covers the full Phase 0 section in `/Users/fahadasad/glowdesk/plan/parts/11-delivery-plan.md:190-393`, including subphases 0.1 through 0.5 and the phase-level exit criteria. ADRs take precedence over the plan, followed by `PLAN.md`, `CONVENTIONS.md`, and the Cursor skills, as required by `briefs/common.md`.

The repository is `/Users/fahadasad/glowdesk`. At report time it was on branch `fn/onboarding-provisioning`, commit `bcc2819e22a686d1c0559698f63a882c9a28f116` (`feat(db): add branch hours, closed periods, invoice counters and plans`), dated 2026-10-04. The working tree was not clean: it had modified files and untracked files, including Phase 1 migration and onboarding changes. The earlier gates were run on clean `main` at `2e22eff2a90c8f09e7d98534cb35e11c9df4a78c`. The verifier notes that the intervening committed work did not change the CI, Sentry, health, onboarding-handler, or skill-copy files it adjudicated. The current uncommitted onboarding handler diff adds an attempted compensating user deletion, but the diff does not add a test that forces the provisioning RPC to fail; this uncommitted change is not a verified fix. Gate counts below are evidence for the earlier snapshot only. Sources: `gates/GATES.md:3-8`; verifier's freshness note in `adjudication.md:7-11`; read-only `git status` and `git rev-parse HEAD` at report time.

## Gate results

All nine gate results below come from `gates/GATES.md:58-81` and refer to the earlier `main` snapshot.

| Command | Result | Key detail |
|---|---|---|
| `pnpm install --frozen-lockfile` | PASS | All nine workspace projects resolved (`GATES.md:62`). |
| `pnpm db:reset` (initial) | PASS | Eleven migrations applied and seed loaded (`:63`). |
| `pnpm db:test` | PASS | Five pgTAP files, 149 tests, no failures (`:64,74-76`). |
| `pnpm db:lint` | PASS | No schema errors (`:65`). |
| Generated type drift check | PASS | Generated types matched the committed file (`:66`). |
| `pnpm fn:test` | FAIL | 38 passed, 2 health tests failed. The endpoint returned 503 instead of 200 and omitted the expected request ID; onboarding tests were not reached (`:67,77-79`; `fn-test.log:9-28`). |
| `pnpm verify` | PASS | Typecheck, ESLint, CSS lint, 79 Vitest tests, build, and size checks passed (`:68, verify.log:3-12`). |
| Playwright suite | PASS | 20 tests passed, 10 each in English and Arabic (`:69,80-82`; `playwright.log:3-28`). This includes the no-membership screen in both locales (`playwright.log:10,18`). |
| `pnpm db:reset` (final) | PASS | Reset and seed completed successfully (`:70`). |

The gate log says the local Functions server was not serving the health function (`GATES.md:91-105`). That may explain the immediate 503, but it does not turn the failing acceptance test into a pass. The health smoke must serve the function and prove the expected response.

## Phase exit and acceptance criteria

| Criterion | Status | Evidence |
|---|---|---|
| CI is green on a trivial PR touching a function and a component | NOT MET | No `.github` directory or workflow files were found; Phase 0.1 requires `ci.yml` (`plan/parts/11-delivery-plan.md:213,227`; `adjudication.md:17-21`). |
| Deploy pipeline promotes staging to production with functions and migrations | NOT MET | No deploy workflow exists; the plan requires same-commit migration, function, and frontend deployment (`plan/parts/11-delivery-plan.md:213,228`; `adjudication.md:17-21`). Actual hosted deployment is also not locally verifiable. |
| Clean-migration gate passes end to end from an empty database on the pinned CLI | NOT DONE | Local reset, pgTAP, lint, and type-drift gates passed on the earlier snapshot, but no CI gate exists and the Deno gate failed. The current checkout was not run through the suite (`GATES.md:63-67,70`; `adjudication.md:78-80`). |
| Spike verdict recorded in ADR-41 with evidence | DONE | ADR-41 records the fallback GO and evidence; premium evaluation was waived under the ADR-41 no-license decision (`adjudication.md:80-81,92`; `plan/evidence/0.5/results.md:12-21`). |

Subphase acceptance criteria:

| Criterion | Subphase | Status | Evidence |
|---|---:|---|---|
| CI green on a trivial PR | 0.1 | NOT MET | No CI workflow (`adjudication.md:17-21`). |
| Staging-to-production deploy | 0.1 | NOT MET | No deploy workflow (`adjudication.md:17-21`). |
| Clean-migration gate passes and rejects any `sql/drafts-v1/` reference | 0.1 | NOT DONE | Local reset and database tests passed on the earlier snapshot, but there is no automated CI gate; the Deno gate failed (`GATES.md:63-67`; `plan/parts/11-delivery-plan.md:214,229`). |
| Sentry captures a deliberate error and uptime monitor fires on simulated downtime | 0.1 | NOT MET / NOT VERIFIABLE LOCALLY | Sentry code is absent, so its required implementation is missing. External monitor firing requires the hosted monitor and cannot be proven locally; `monitors.json` exists (`adjudication.md:23-27,60,95`). |
| Member can log in and see shell in English and Arabic; user without membership sees no-access | 0.2 | DONE | Playwright smoke and no-access tests passed in both locales (`playwright.log:7,10,15,18`). |
| pgTAP proves cross-tenant reads empty, profiles not world-readable, authenticated users cannot insert tenants, and revocation immediately removes access | 0.2 | DONE | 149 pgTAP tests passed; test files cover outsider isolation, profiles, grants, and revocation (`GATES.md:64,76`; `adjudication.md:83`). |
| Health route deployed to staging returns 200 with request ID | 0.3 | NOT MET | Local smoke failed with 503 and no request ID; no staging deployment workflow is present (`fn-test.log:9-23`; `adjudication.md:29-33`). |
| Sentry captures an unhandled error from a staged function crash | 0.3 | NOT MET | No Sentry SDK or transport is wired (`adjudication.md:23-27`). A staged event cannot be verified until the integration and deployment exist. |
| `packages/validation` imports from Deno | 0.3 | DONE LOCALLY; CI NOT MET | The validation contract test ran in the passing `_shared` suite; persistent CI execution is absent (`GATES.md:67,77`; `adjudication.md:84`). |
| Money format is `KWD 12.500` in English and the Arabic equivalent; UTC date renders in Asia/Kuwait | 0.4 | DONE | Formatter assertions exist in `packages/i18n/src/format.test.ts:8-50`; `pnpm verify` passed (`adjudication.md:85`, `verify.log:8`). |
| Shell renders in English and Arabic with correct direction; login is the entry point | 0.4 | DONE | Playwright passed across English and Arabic; frontend locale checks are detailed in `frontend.md:207-212,248-258` and gate totals in `playwright.log:3-28`. |
| All six named packages build and their Vitest suites pass | 0.4 | DONE LOCALLY | The plan says “five” but lists six packages (`plan/parts/11-delivery-plan.md:356`). `pnpm verify` passed typecheck, 79 Vitest tests, and build (`verify.log:5-10`). |
| CI drift check keeps `database.types.ts` current | 0.4 | NOT MET | Local type drift passed on the gate snapshot, but CI does not exist (`GATES.md:66`; `adjudication.md:85`). |
| ADR-41 spike verdict and evidence recorded | 0.5 | DONE | ADR-41 and `plan/evidence/0.5/results.md:12-21` record the fallback verdict and evidence. |
| If premium is no-go, fallback demonstrates the calendar wrapper API and documents gaps | 0.5 | DONE | Fallback prototype and gap list are recorded; ADR-41 assigns remaining keyboard-navigation work to Phase 5 (`adjudication.md:66,86,92`). |

## Plan checklist

Statuses below reflect the verifier's adjudication, not the earlier conformance checklist where it conflicts with gate evidence. `NOT VERIFIABLE LOCALLY` means the item requires a cloud service; it is not a local failure unless required local implementation is absent.

### Subphase 0.1: Repository and environments

- Goal: PARTIAL. The monorepo exists, but the required end-to-end CI/CD foundation is missing (`conformance.md:27-42`; `adjudication.md:19-21`).
- Features delivered: PARTIAL. pnpm scaffold and local Supabase development configuration exist. CI, deployment, and Sentry are missing. Staging/production projects, preview branches, paid-plan status, production region, legal verification, and hosted observability are not verifiable locally. A health monitor config exists, but an external service firing is not verifiable (`conformance.md:27-42`; `adjudication.md:60,82,95`).
- Database work: DONE AS SPECIFIED. No database work is required in 0.1 (`plan/parts/11-delivery-plan.md:218`).
- Edge Functions, screens, and i18n/RTL: NONE SPECIFIED for this subphase (`:220-224`).
- Tests: INCOMPLETE. No CI workflow self-test or staging deploy dry-run; the recurring clean-migration and drift gates are absent (`:232,236-243`; `adjudication.md:17-21`).
- Dependencies: NONE.
- Backlog: PARTIAL. Monorepo and local verification exist. CI and deploy workflows are missing; clean-migration CI and Sentry transport are missing. External uptime monitor, log drain, staging/production setup, and region/legal checks are not verifiable locally. `.env.example` also omits the generic `INTERNAL_FUNCTION_SECRET` (`adjudication.md:51-54`).

### Subphase 0.2: Tenancy and security skeleton

- Goal: DONE WITH FIXES. The RLS/auth foundation and pgTAP harness are implemented and passed their recorded checks; the onboarding invited-owner failure path remains a major issue (`database.md:56-170,183-272`; `adjudication.md:40-44`).
- Features delivered: DONE WITH FIXES. Email/password auth, session and password reset flow, route guards, helpers, four-policy and branch-scoped RLS patterns, all-branches representation, audit machinery, and test harness are present. The no-membership path is tested in English and Arabic (`frontend.md:50-90`; `adjudication.md:83`).
- Database work: DONE. Tenancy tables, helper functions, settings, audit log, idempotency keys, composite foreign keys, and pgTAP suite are present; 149 tests passed on the gate snapshot (`database.md:13-115,183-272`; `GATES.md:64,76`). `branches` and the minimal `provision_tenant` RPC were pulled forward with their rationale declared in migration comments (`adjudication.md:58-59`).
- Edge Functions: DONE WITH FIXES. Onboarding provisioning exists, but an invited user may be orphaned if the RPC fails. Current uncommitted handler edits attempt compensating deletion, but no failure-injection test was found and the change has not been verified (`backend.md:144-152,394-418`; current checkout diff; `adjudication.md:40-44`).
- Screens: DONE. Login, password reset, shell, no-access, 403, and 404 flows are implemented and exercised as detailed in `frontend.md:50-82,248-258`.
- i18n/RTL: DONE for the specified login/shell path. The English/Arabic shell and no-access flows passed; full i18n/RTL baseline details are in `frontend.md:176-232` and `playwright.log:3-28`.
- Acceptance criteria: DONE WITH FIXES. Membership, no-access, tenant isolation, profile privacy, tenant write restriction, and revocation are covered. The orphan-invite edge case is not resolved by verified evidence (`adjudication.md:83`).
- Tests: DONE LOCALLY; CI MISSING. pgTAP and Playwright passed on the historical gate snapshot, but no CI workflow runs them on changes (`GATES.md:64,69`; `adjudication.md:78-85`).
- Dependencies: 0.1 is PARTIAL; local repository and Supabase foundation exist, but CI and environment delivery requirements are unmet (`plan/parts/11-delivery-plan.md:280`).
- Backlog: DONE WITH FIXES. Database, auth screens, shell, switcher, and harness tasks are substantially delivered. CI dependency and onboarding failure handling remain open (`:282-291`; `adjudication.md:40-44`).

### Subphase 0.3: Edge Function platform

- Goal: PARTIAL. Shared function infrastructure exists, but health smoke and Sentry acceptance requirements fail (`backend.md:162-234`; `adjudication.md:23-38`).
- Features delivered: PARTIAL. Wrapper, error envelope, logging, CORS, idempotency, Deno-compatible validation, function template, health route, and monitor configuration exist. `captureException` logs to console and has no Sentry transport (`backend.md:164-233`; `adjudication.md:23-27`).
- Database work: DONE AS SPECIFIED. None is required (`plan/parts/11-delivery-plan.md:305`).
- Edge Functions: INCOMPLETE. The health smoke test fails with 503 and null request ID; local boot/serve setup must be corrected and staging response verified (`fn-test.log:9-23`; `adjudication.md:29-33`).
- Screens and i18n/RTL: NONE SPECIFIED (`plan/parts/11-delivery-plan.md:312-313`).
- Acceptance criteria: INCOMPLETE. Staging health response and Sentry event are not demonstrated; Deno validation import passes locally (`adjudication.md:29-38,84`).
- Tests: INCOMPLETE. `_shared` 35/35 and template 3/3 passed; health 0/2 passed. `pnpm fn:test` exits on the first function-directory failure, so onboarding test outcomes were not reported (`GATES.md:67,77-79`; `fn-test.log:3-28`; `adjudication.md:35-38`).
- Dependencies: 0.2 is substantially present. CI dependency from 0.1 is unmet (`plan/parts/11-delivery-plan.md:321`).
- Backlog: PARTIAL. Shared modules, validation contract test, template, health route, and monitor config exist; health boot/smoke, Sentry, and dependable suite reporting remain open (`:323-327`; `adjudication.md:23-38`).

### Subphase 0.4: Frontend platform

- Goal: DONE WITH FIXES. The shell, session context, package foundation, and i18n/RTL baseline are implemented. Skill-copy drift and missing recurring CI drift enforcement remain (`frontend.md:104-258`; `adjudication.md:46-49,85`).
- Features delivered: DONE. Router, session context, tenant/branch switchers, login/reset and deep-link restore, UI primitives, typed DB/API clients, and formatter helpers are present (`frontend.md:104-175,241-258`).
- Database work: DONE AS SPECIFIED. None is required; the frontend consumes the Phase 0.2 schema (`plan/parts/11-delivery-plan.md:343`).
- Edge Functions: NONE SPECIFIED.
- Screens: DONE. Shell, switchers, login/reset, no-access and error screens are covered in `frontend.md:50-90,160-175`.
- i18n/RTL: DONE. English/Arabic catalogs, `dir`/`lang`, logical CSS lint, money/date formatting, and RTL handling are detailed in `frontend.md:176-232`.
- Acceptance criteria: DONE LOCALLY. Format assertions, locale rendering, and package builds passed locally (`adjudication.md:85`; `verify.log:4-12`; `playwright.log:3-28`).
- Tests: PARTIAL. Vitest, Playwright, and local type-drift checks passed on the historical snapshot; CI drift enforcement is missing (`GATES.md:66,68-69`; `adjudication.md:85`).
- Dependencies: 0.1 is PARTIAL; the code can be locally verified, but the required CI is absent. The auth foundation from 0.2 exists (`plan/parts/11-delivery-plan.md:360`).
- Backlog: DONE WITH FIXES. Frontend shell, screens, packages, formatters, and Playwright suite exist. CI enforcement and skill-copy synchronization remain (`:362-368`; `adjudication.md:46-49`).

### Subphase 0.5: Calendar library spike

- Goal: DONE. The fallback path was evaluated against the spike criteria and recorded in ADR-41 (`plan/parts/11-delivery-plan.md:374-385`; `plan/evidence/0.5/results.md:12-21`).
- Features delivered: DEVIATED-JUSTIFIED. Premium was not evaluated because no license was available; ADR-41 authorizes the core/custom-resource fallback (`adjudication.md:66,92`).
- Database work, Edge Functions, screens, and i18n/RTL: NONE SPECIFIED.
- Acceptance criteria: DONE. ADR verdict, fallback API surface, evidence, and gap list are recorded (`adjudication.md:80-81,86,92`). Remaining in-grid keyboard navigation is assigned to Phase 5, not a Phase 0 defect (`adjudication.md:66`).
- Tests: DONE AS SPIKE EVIDENCE. Performance traces, screenshots, keyboard/RTL results and prototype evidence are referenced in `plan/evidence/0.5/results.md:12-21`.
- Dependencies: 0.4 exists; its overall status remains “done with fixes” (`plan/parts/11-delivery-plan.md:387`; `adjudication.md:85`).
- Backlog: DONE WITH JUSTIFIED FALLBACK. The selected fallback was implemented; premium evaluation was waived under ADR-41 (`:389-392`; `adjudication.md:92`).

## Deviations

- Calendar scheduler: DEVIATED-JUSTIFIED. ADR-41 records that premium could not be evaluated without a license and authorizes the fallback; evidence supports the verdict (`adjudication.md:66,92`).
- `branches` table and minimal `provision_tenant` RPC: DEVIATED-JUSTIFIED. Both were pulled forward from Phase 1.1 for Phase 0 composite-FK and onboarding needs, and the migration headers disclose the rationale and boundary (`adjudication.md:58-59,93`).
- Cursor/Claude skill copies: DEVIATED-UNJUSTIFIED. Three files differ despite the plan appendix requiring identical copies (`adjudication.md:46-49,94`).
- CI/CD and Sentry omissions are missing requirements, not justified deviations. The local checks do not substitute for persistent CI or deployments.

## Findings

### Blockers

#### F-VERIFIER-1: CI and deployment workflows are missing
- Location: `/Users/fahadasad/glowdesk/.github/` is absent; Phase 0 requirements are at `plan/parts/11-delivery-plan.md:213-214,226-243`.
- Problem: There is no CI workflow for tests, clean migration, generated-type drift, or size checks, and no deployment workflow. This leaves phase exit criteria unmet.
- Fix: Add `.github/workflows/ci.yml` with the pinned clean-migration gate, generated-type drift, Deno tests, Vitest, lint, build, and size checks. Add `.github/workflows/deploy.yml` to promote migrations, functions using `--use-api`, and frontend from the same commit through staging and production.

#### F-VERIFIER-2: Sentry is not integrated
- Location: `supabase/functions/_shared/logging.ts:38-45`; the repository has no frontend or Deno Sentry initialization/configuration (`adjudication.md:23-27`).
- Problem: `captureException` only logs to console, despite Phase 0.1 and 0.3 Sentry requirements.
- Fix: Add and initialize the frontend and Deno Sentry SDKs, configure DSNs via environment/secrets, wire `captureException` to send events, and demonstrate a deliberately generated exception in the staging Sentry project.

#### F-VERIFIER-3: Health function smoke fails and local boot is unproven
- Location: `gates/fn-test.log:9-23`; implementation test `supabase/functions/health/health_test.ts:6-16`.
- Problem: Both health tests fail: expected HTTP 200 and a request ID, received 503 and null. The verifier also observed `BOOT_ERROR` from the local endpoint (`adjudication.md:29-33`). The gate log says the functions server was not running; Supabase documents serving functions after starting the local stack: https://supabase.com/docs/guides/functions/quickstart.
- Fix: Start/serve the health function in the local smoke setup, resolve any worker boot error, and require the test to verify HTTP 200, the expected envelope, and `x-request-id`; then verify the staging endpoint separately.

### Major findings

#### F-BE-5: Failed provisioning can orphan a newly invited owner
- Location: `supabase/functions/onboarding/handlers.ts:49-63` in the audited snapshot; the current uncommitted diff adds a compensating `deleteUser` call but no test that forces the RPC failure.
- Problem: The handler invites a new owner before calling `provision_tenant`. If that RPC fails, the Auth user may remain without a tenant. The existing duplicate-slug test does not exercise an RPC failure after invitation. The uncommitted attempted fix also does not check the deletion result, and has not been verified (`adjudication.md:40-44`; current read-only diff).
- Fix: On provisioning failure after a new invite, compensate by deleting only that newly created Auth user; handle and record any cleanup failure for retry. Add a test that forces the RPC failure and asserts that no orphan remains. Never delete a pre-existing owner account.

#### F-VERIFIER-4: Deno runner exits before onboarding tests
- Location: root `package.json:15`; failing health suite in `gates/fn-test.log:9-28`; onboarding tests at `supabase/functions/onboarding/onboarding_test.ts:93-157` in the audited snapshot.
- Problem: The test loop exits on the first directory failure. The health failure therefore prevents the onboarding suite from running, so the recorded 38 passing Deno tests do not establish onboarding coverage.
- Fix: Change the runner to execute every function suite, aggregate exit codes, and return nonzero after all suites finish. Make the gate report onboarding results and retain the health failure.

#### F-CONFORM-3: Cursor and Claude skill copies differ
- Location: `.cursor/skills/react-frontend/SKILL.md`, `.cursor/skills/react-frontend/reference.md`, and `.cursor/skills/i18n-rtl/reference.md` differ from their `.claude/skills/` counterparts (`adjudication.md:46-49`).
- Problem: The plan appendix requires the skill copies to be identical.
- Fix: Synchronize the three `.claude/skills/` files with the implementation-accurate `.cursor/skills/` versions and keep both trees identical.

### Minor finding

#### F-BE-7: `INTERNAL_FUNCTION_SECRET` is undocumented
- Location: `supabase/functions/_shared/auth.ts:91-102` and `supabase/functions/.env.example:1-4`.
- Problem: The generic secret-auth default names `INTERNAL_FUNCTION_SECRET`, but the example documents only `PLATFORM_ADMIN_SECRET`. The verifier reduced severity to minor because the Phase 0 secret-auth function explicitly configures `PLATFORM_ADMIN_SECRET` (`adjudication.md:51-54`).
- Fix: Document `INTERNAL_FUNCTION_SECRET` as a placeholder in `.env.example`, explain that per-function `SecretConfig` may override it, and do not include a usable production secret.

### Rejected, merged, or deferred findings

- CI drift observations are merged into F-VERIFIER-1; they are not separate findings. The local drift check passed on the historical snapshot, but recurring CI enforcement is absent (`adjudication.md:67,69`).
- The no-access test finding is rejected: the Playwright test passes in English and Arabic (`playwright.log:10,18`; `adjudication.md:70`).
- Realtime authorization testing is out of Phase 0 scope because no Realtime subscription implementation was found; ADR-38 places the hook/test with the Realtime implementation (`adjudication.md:62`).
- Remaining calendar keyboard-navigation gap is assigned to Phase 5 by ADR-41, not a Phase 0 defect (`adjudication.md:66`).
- External uptime monitor firing and hosted log-drain wiring are NOT VERIFIABLE LOCALLY; `monitors.json` exists. Verify them in staging rather than treating them as local failures (`adjudication.md:60,95`).
- Pulled-forward branches and the minimal provisioning RPC are justified and disclosed, not defects (`adjudication.md:58-59`).
- Idempotency comment clarity and validation-contract naming were rejected as non-defects; per-function idempotency matches the database uniqueness boundary, and the contract test ran (`adjudication.md:63`).
- Rate limiting is DEVIATED-JUSTIFIED by ADR-47; application-level limits are assigned to Phase 9 (`adjudication.md:64`).
- The conformance auditor's favicon concern and deterministic seed UUID style concern are not Phase 0 defects (`adjudication.md:61,68`).

## Not verifiable locally

The following require cloud or operational evidence: staging/production Supabase project configuration and paid-plan status; deployed staging-to-production workflow; production region and the Phase 8 legal gate; an external uptime monitor firing on simulated downtime; hosted log-drain delivery; and staged health/Sentry events. The missing CI and Sentry implementation remain code blockers, not unverifiable items. The fix should attach CI logs, deployment/run IDs, a successful staged health response with request ID, a Sentry event, and uptime/log-drain evidence before closing those criteria (`adjudication.md:60,95`).

## Fix prompt

```text
Fix the Phase 0 audit findings below in /Users/fahadasad/glowdesk, in order.
Context: @plan/parts/11-delivery-plan.md @plan/decisions.md @plan/CONVENTIONS.md
Skills: /feature-delivery /spa-domain-glossary /spa-platform-architecture /supabase-database /supabase-edge-functions /react-frontend /i18n-rtl

1. F-VERIFIER-1: Add .github/workflows/ci.yml and deploy.yml. CI must run the pinned clean-migration gate (reset from empty, generated-type drift, function typecheck/build, pgTAP, adversarial fixture suite, and fail on sql/drafts-v1 references), Deno tests, Vitest, lint, frontend build, and size checks. Deployment must promote migrations, functions with --use-api, and frontend from the same commit through staging and production.
2. F-VERIFIER-2: Add and initialize Sentry for the frontend and Deno functions, configure DSNs through secrets/environment, wire supabase/functions/_shared/logging.ts captureException to Sentry, and demonstrate a deliberate staged error event.
3. F-VERIFIER-3: Serve the health function in local smoke setup, resolve BOOT_ERROR, and test HTTP 200, the expected envelope, and x-request-id. Verify the deployed staging route separately.
4. F-BE-5: In supabase/functions/onboarding/handlers.ts, compensate for a failed provision_tenant RPC only when this request invited the owner; handle and record cleanup failure for retry. Add a failure-injection test proving no orphan remains and proving existing users are not deleted.
5. F-VERIFIER-4: Change the root Deno test runner to execute every function directory, aggregate failures, and report the onboarding suite result without hiding the health failure.
6. F-CONFORM-3: Synchronize .claude/skills/react-frontend/SKILL.md, .claude/skills/react-frontend/reference.md, and .claude/skills/i18n-rtl/reference.md with the implementation-accurate .cursor/skills copies.
7. F-BE-7: Document INTERNAL_FUNCTION_SECRET in supabase/functions/.env.example as a placeholder and state that a per-function SecretConfig can override it. Do not add a production credential.

Rules: never edit an applied migration; add a new migration when schema changes are needed. Keep both skill copies identical. Use Conventional Commits. Done means every audit gate passes again and each fixed acceptance criterion is demonstrated by a test; attach staging deployment, health, Sentry, uptime, and log-drain evidence where cloud verification is required.
```

## Finding summary

| ID | Severity | Title |
|---|---|---|
| F-VERIFIER-1 | Blocker | CI and deployment workflows are missing |
| F-VERIFIER-2 | Blocker | Sentry is not integrated |
| F-VERIFIER-3 | Blocker | Health function smoke fails and local boot is unproven |
| F-BE-5 | Major | Failed provisioning can orphan a newly invited owner |
| F-VERIFIER-4 | Major | Deno runner exits before onboarding tests |
| F-CONFORM-3 | Major | Cursor and Claude skill copies differ |
| F-BE-7 | Minor | `INTERNAL_FUNCTION_SECRET` is undocumented |

Count: 3 blockers, 3 majors, 1 minor.