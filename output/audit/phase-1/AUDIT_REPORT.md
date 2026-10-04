# Phase 1 audit report

## 1. Verdict: FAIL

Phase 1 is not ready to close. The recorded Playwright run failed the Arabic receptionist sign-in check, and the supplied gate logs target an older commit than the current repository. The database and most targeted browser checks passed on the recorded snapshot, but the current HEAD has not been verified by the full gate set. The fixes are bounded: repair and test the Arabic sign-in path, then run and archive all required gates from a clean checkout of current HEAD.

| Subphase | Status | Reason |
|---|---|---|
| 1.1 Provisioning | Done with fixes | Provisioning code, database paths, and ops runbook are present. The gate snapshot did not reach onboarding Deno tests, and current-HEAD gates remain outstanding. |
| 1.2 Settings hub | Incomplete | Settings implementation and targeted settings tests are present, but the Arabic receptionist smoke test failed and current-HEAD gates are missing. |
| 1.3 Roles and memberships | Done with fixes | Membership controls and database enforcement are present; the recorded database and browser member/scope tests passed. Deno invite tests were not reached, and current-HEAD gates remain outstanding. |

## 2. What was audited

The audit covers plan phase 1 in `/Users/fahadasad/glowdesk`, including all three subphases, the phase-level exit criteria, and the binding ADRs. The verifier inspected the repository on 2026-10-04. At that inspection, the current repository was on branch `fix/phase-0-audit`, commit `105104354d55ff95f1cfe5770210a4da5e1eeddd`, with a clean working tree. The supplied gate snapshot instead targets branch `main`, commit `916121fbf5568a1e6929e5e9b61f7fe3346f865e` (`gates/GATES.md:5-8`). The gate results therefore do not establish the state of current HEAD.

## 3. Gates

These are the recorded results for `main` at `916121fbf5568a1e6929e5e9b61f7fe3346f865e`, not a run on current HEAD. Log references are relative to `/Users/fahadasad/hermes-council/output/audit/phase-1/gates/`.

| Command | Result | Key detail |
|---|---|---|
| `pnpm install --frozen-lockfile` | PASS (exit 0) | All 9 workspace projects resolved; already up to date (`GATES.md:49-50`, `01-pnpm-install-frozen.log`). |
| `pnpm db:reset` | PASS (exit 0) | 19 migrations applied and seed loaded (`GATES.md:50,63-83`, `02-pnpm-db-reset.log`). This is the gate worker's recorded stateful run; it was not repeated for this synthesis. |
| `pnpm db:test` | PASS (exit 0) | 8 pgTAP files, 320/320 tests passed (`GATES.md:51,85-94`, `03-pnpm-db-test.log`). |
| `pnpm db:lint` | PASS (exit 0) | No schema errors (`GATES.md:52,96-97`, `04-pnpm-db-lint.log`). |
| `supabase gen types --local` and whitespace-insensitive diff | PASS (exit 0) | Generated types matched committed types; no type drift (`GATES.md:53,99-100`, `05-type-drift.log`). |
| `pnpm fn:test` | FAIL (exit 1) | 31 passed, 9 failed in connectivity-dependent tests. Onboarding provisioning and invite suites were not run because the runner stopped after earlier function-directory failures (`GATES.md:54,102-109`, `06-pnpm-fn-test.log`). |
| `pnpm verify` | PASS (exit 0) | i18n compile, typecheck, ESLint, Stylelint, Vitest (20 files/111 tests), build, and bundle-size checks passed (`GATES.md:55,111-120`, `07-pnpm-verify.log`). |
| `pnpm exec playwright test` | FAIL (exit 1) | 29/30 passed. The Arabic receptionist smoke test stayed at `/login` instead of reaching the app shell (`GATES.md:56,122-139`, `08-playwright.log:24-31`). |

The recorded gate suite includes 320 pgTAP tests, 111 Vitest tests, and 30 Playwright tests (29 passed, 1 failed). The Deno run recorded 31 passes and 9 failures, and did not execute the onboarding tests. The `GATES.md:150-175` post-run status describes changes at the old snapshot; the verifier found the current repository clean, so those old post-run changes are not treated as current uncommitted work.

## 4. Exit and acceptance criteria

Evidence below is from the recorded gate run, saved Phase 1 evidence, and source/test inspection. It does not certify current HEAD, because the gate snapshot is older.

The phase goal is to let platform operations create tenants and let owners configure the business before operational data exists. Implementation evidence covers tenant provisioning, branches, hours, roles, and settings, but the whole phase is not complete until the failed Arabic flow is fixed and current-HEAD gates pass (`11-delivery-plan.md:397-401,409`; findings F-FE-1 and F-verifier-1).

The phase names two risks: settings sprawl and an onboarding function with too much power. The settings hub uses typed fields and a narrow `settings` table for dynamic keys; provisioning uses the platform-admin secret and audit path (`11-delivery-plan.md:407`; `supabase/functions/onboarding/index.ts:1-9`; `supabase/migrations/20261005110100_provision_branch.sql:115-177`). No separate defect was accepted for these mitigations; security conclusions remain bounded by the old gate snapshot.

### Phase-level exit criteria

| Criterion | Status | Evidence |
|---|---|---|
| Platform ops provisions SpaCorner; owner logs in and sees the setup checklist | DONE in saved evidence | `plan/evidence/1.3/ops-provision.txt:1-9`; `apps/back-office/evidence/phase1-exit.spec.ts:49-57`. |
| Owner creates a second branch with overnight and split hours shown in branch-local context | DONE in saved evidence | `apps/back-office/evidence/phase1-exit.spec.ts:59-88`; `plan/evidence/1.3/db-checks.txt:9-14`; settings Playwright tests passed in both locales (`gates/GATES.md:125-139`). |
| Manager sees only assigned branches; receptionist cannot write settings | DONE in targeted recorded tests | Database role matrix and browser settings/scope suites (`database.md:238-253`; `gates/GATES.md:125-139`). The separate failed receptionist smoke test concerns reaching the app shell, not a demonstrated settings write. |
| Archiving hides a branch and retains its rows | DONE | Saved database checks (`plan/evidence/1.3/db-checks.txt:1-7`) and settings matrix (`database.md:355-363`). |
| Currency changes are blocked in the UI after a sale | DONE for Phase 1 scope | Plan defers full database enforcement to Phase 6; Phase 1 tests the predicate and locked UI (`plan/parts/11-delivery-plan.md:480-486`; `apps/back-office/src/features/settings/lib/currency.test.ts:4-12`; `phase1-exit.spec.ts:139-148`). |
| Role changes apply on the target's next request without re-login | DONE in recorded tests | pgTAP immediate-revocation test and member E2E result (`database.md:238-253`; `gates/GATES.md:125-139`). |
| Arabic receptionist smoke test reaches the shell before the role-denial assertion | NOT DONE | Arabic run stayed at `/login`; see `gates/08-playwright.log:24-31` and failure context `gates/playwright-results/smoke-a-receptionist-is-se-ab0d1-3-for-an-owner-manager-page-ar/error-context.md:21-45`. This is an accepted blocker. |

### Subphase acceptance criteria

| Criterion | Subphase | Status | Evidence |
|---|---|---|---|
| Ops provisions SpaCorner and owner sees the tenant app shell | 1.1 | DONE in saved evidence | `plan/evidence/1.3/ops-provision.txt:1-9`; phase exit test `phase1-exit.spec.ts:49-57`. |
| Repeating provision-tenant does not create a duplicate tenant | 1.1 | PARTIAL | Saved provisioning evidence shows the repeated call returned the existing tenant/branch (`ops-provision.txt:1-9`); the required Deno test source exists, but onboarding tests were not executed in the recorded gate (`GATES.md:102-109`). |
| Provision-branch supports overnight and split intervals; rejects zero length; fixtures cover a full day | 1.1 | PARTIAL | Deno test source covers these cases (`backend.md:97-110`), and database fixtures passed (`GATES.md:85-94`); the required onboarding Deno suite was skipped. |
| Owner creates a second branch with overnight and split hours rendered in branch-local time; zero-length hours are rejected | 1.2 | DONE in saved evidence | `phase1-exit.spec.ts:59-88`; `plan/evidence/1.3/db-checks.txt:9-14`; `005_branch_config.test.sql` passed in the 320-test suite (`GATES.md:85-94`). |
| Archiving hides the branch from operations and preserves its rows | 1.2 | DONE | `plan/evidence/1.3/db-checks.txt:1-7`; settings matrix retained-row checks (`database.md:355-363`). |
| Currency UI is locked after a sale; database enforcement is deferred to Phase 6 | 1.2 | DONE for Phase 1 scope | Explicit plan boundary (`11-delivery-plan.md:480-486`); predicate unit test and mocked-server UI test (`currency.test.ts:4-12`; `phase1-exit.spec.ts:139-148`). |
| Settings work in EN and AR/RTL | 1.2 | PARTIAL | Settings Playwright suite passed 3/3 in each locale (`GATES.md:125-139`), and i18n/style checks passed (`GATES.md:55,111-120`), but the Arabic receptionist smoke flow failed and current-HEAD evidence is absent. |
| Manager sees only assigned branches and cannot read tenant settings | 1.3 | DONE in targeted recorded tests | Role matrix and settings/scope browser tests (`database.md:238-253`; `GATES.md:125-139`). |
| Role change applies on target's next request without re-login | 1.3 | DONE in recorded tests | `007_role_grants.test.sql` immediate-revocation test and member E2E (`database.md:238-253`; `GATES.md:125-139`). |
| Invite creates auth account and membership atomically, sends invitation, and is audited | 1.3 | PARTIAL | Implementation and Deno test coverage are present (`supabase/functions/onboarding/members.ts:83-112`; `backend.md:114-136`), but invite Deno tests were not reached in the recorded gate (`GATES.md:102-109`). |
| Manager trying to grant owner role receives FORBIDDEN | 1.3 | DONE in recorded tests | Membership role-grant test source (`members_test.ts:103-127`) and pgTAP role-grant suite passed (`GATES.md:85-94`); the Deno suite itself was not reached. |

## 5. Plan checklist

The statuses reflect the verifier's adjudication. `DONE` describes inspected implementation or passing recorded tests, not certification of current HEAD. `PARTIAL` means a required test or gate result is missing or failed.

### Subphase 1.1 — Provisioning

| Plan area | Status | Verified checklist |
|---|---|---|
| Goal | DONE in implementation; current verification outstanding | Platform-admin provisioning creates tenant, branch, and seeded defaults; no current-HEAD gate evidence is supplied (`11-delivery-plan.md:415,418-421`; `handlers.ts:155-209`). |
| Features | DONE | Tenant and branch provisioning, seeded defaults, plans/features, and platform-admin ops path are present (`supabase/functions/onboarding/handlers.ts:155-209`; `supabase/migrations/20261005110100_provision_branch.sql:115-211`; `scripts/ops/provision.ts`; `docs/runbooks/platform-admin.md`). |
| Database | DONE in recorded run | Branches, opening hours, closures, invoice counters, plans, plan features, and tenant plan fields are implemented; RLS and audit triggers are present. Nine Phase 1 migrations applied, and all 320 pgTAP tests passed (`GATES.md:63-94`; `database.md:14-27`). |
| Edge Functions | DONE implementation; tests PARTIAL | `onboarding/provision-tenant` and `onboarding/provision-branch` use service-role paths and transactional database RPCs (`handlers.ts:155-209`). Required onboarding Deno tests exist, including idempotency and interval cases, but were skipped by the recorded test runner (`GATES.md:102-109`). |
| Screens | NOT APPLICABLE | Phase 1.1 is ops-side; the plan explicitly says no screens (`11-delivery-plan.md:433`). |
| i18n/RTL | NOT APPLICABLE | This subphase has no user-facing screens (`11-delivery-plan.md:433`). |
| Tests | PARTIAL | pgTAP passed 320/320; the gate recorded 31 Deno passes and 9 connectivity failures, then skipped onboarding tests. Current `scripts/fn-test.sh:1-24` runs every function directory, but was not executed on current HEAD (`GATES.md:102-109`; adjudication §2). |
| Dependencies | DONE | Phase 0 tenancy, auth, RLS, and test harness are present; subphase 1.1 depends on Phase 0 (`11-delivery-plan.md:442`; `conformance.md:201-206`). |
| Backlog | DONE by inspection | All listed database migrations, two onboarding functions, and the platform-admin runbook are present (`11-delivery-plan.md:444-449`; `conformance.md:45-50`). |

### Subphase 1.2 — Settings hub

| Plan area | Status | Verified checklist |
|---|---|---|
| Goal | DONE in implementation; acceptance PARTIAL | Settings screens and persistence paths exist, but the full Arabic acceptance and current-HEAD gate requirements are not met (`11-delivery-plan.md:455-462,480-486`; F-FE-1, F-verifier-1). |
| Features | DONE | Business details, branch editor, calendar defaults, cancellation reasons, blocked-time types, and owner setup checklist are present (`conformance.md:52-70`; `frontend.md:78-145`). |
| Database | DONE in recorded run | Settings tables, branch defaults, role-gated RPCs, archive retention, and pgTAP role matrix are present; database tests and lint passed (`GATES.md:51-52,85-97`; `database.md:167-210`). |
| Edge Functions | DONE; no deviation | Settings mutations call role-checked RPCs directly through Supabase. ADR-28 takes precedence over the phase wording and prohibits direct client writes to `tenants` and `branches`, requiring an RPC or Edge Function (`plan/decisions.md:461-465`; `settings/mutations.ts:44-90,127-160`; `20261005120100_settings_rpcs.sql:14-47`). This implementation is compliant, not an unjustified direct-write deviation. |
| Screens | DONE by inspection; acceptance PARTIAL | Checklist, tenant settings, branch details/hours/closures/invoicing/tips/methods, and catalogue editors are present (`frontend.md:78-145`). The targeted settings suite passed in both locales, but the overall Arabic smoke gate failed (`GATES.md:125-139`). |
| i18n/RTL | DONE for implementation and checks; acceptance PARTIAL | Bilingual fields, direction handling, and bidi isolation are present (`frontend.md:174-212`); strict catalog compilation and Stylelint passed (`GATES.md:55,111-120`). The full EN/AR acceptance is not met because of the failed Arabic receptionist flow. |
| Tests | PARTIAL | pgTAP and targeted settings E2E passed on the recorded snapshot; full Playwright was 29/30, with the Arabic receptionist smoke test failing. No gates cover current HEAD (`GATES.md:85-94,122-139`; adjudication §2). |
| Dependencies | DONE | Phase 1.1 branch and plan-feature foundations are present (`11-delivery-plan.md:488`; `conformance.md:203-206`). |
| Backlog | DONE by inspection | Database, branch calendar defaults, tenant settings, branch editor, catalogue editors, and setup checklist are present (`11-delivery-plan.md:490-496`; `conformance.md:64-70`). |

### Subphase 1.3 — Roles and memberships

| Plan area | Status | Verified checklist |
|---|---|---|
| Goal | DONE in implementation; current verification outstanding | Owner role/scope controls, invitations, and immediate membership enforcement are implemented; invite tests did not run in the recorded gate (`11-delivery-plan.md:502-509`; `GATES.md:102-109`). |
| Features | DONE | Member list, role/scope changes, invitations, deactivation, and branch/tenant switchers are present (`frontend.md:146-170`; `conformance.md:72-84`). |
| Database | DONE in recorded run | Membership grant checks, live-scope authorization, audit, last-owner protection, and immediate revocation are implemented; pgTAP passed 320/320 overall (`database.md:171-219,238-253`; `GATES.md:51,85-94`). |
| Edge Functions | DONE implementation; tests PARTIAL | `onboarding/invite-user` and membership mutations use scope and role checks (`supabase/functions/onboarding/members.ts:83-148`). Invite Deno tests exist, but the recorded gate did not reach them (`backend.md:114-136`; `GATES.md:102-109`). |
| Screens | DONE | Members/roles, invite and role-change flows, deactivation, and scope switchers are present; recorded member and scope browser tests passed in both locales (`frontend.md:146-170`; `GATES.md:125-139`). |
| i18n/RTL | DONE by inspection and targeted checks | Member names/emails use bidi isolation and locale-specific forms are present; member/scope browser suites passed in EN and AR (`frontend.md:202-212`; `GATES.md:125-139`). |
| Tests | PARTIAL | pgTAP and member/scope E2E passed on the recorded snapshot; invite Deno tests were skipped and current-HEAD gates are outstanding (`GATES.md:85-94,102-109,125-139`). |
| Dependencies | DONE | Membership foundations from 1.1 and switcher shell from 0.4 are present (`11-delivery-plan.md:531`; `conformance.md:203-206`). |
| Backlog | DONE by inspection | Role-matrix tests, member screen, switchers, invite function, and role-grant enforcement are present (`11-delivery-plan.md:533-539`; `conformance.md:86-92`). |

## 6. Deviations

| Item | Ruling | Reason |
|---|---|---|
| Settings mutations use role-checked RPCs rather than direct table writes | No deviation | ADR-28 overrides the phase wording and disallows direct writes to `tenants` and `branches`; the RPC path is permitted and performs server-side role checks (`plan/decisions.md:461-465`; `adjudication.md:34,86,94`). |
| Sentry work was pulled forward | Declared, justified | The work appears in commits `b5ce3b2` and `0fec7de`; the current tree is clean. Pulled-forward work is allowed when declared (`adjudication.md:15,87,95`; `conformance.md:137-140`). It is not accepted as a current-tree uncommitted-change finding. |

No undeclared Phase 1 deviation remains after applying the verifier's rulings. The current-HEAD gate gap remains a blocker, not a plan deviation.

## 7. Findings

### Accepted blockers

#### F-FE-1: Arabic receptionist sign-in does not reach the app shell

- Severity: blocker.
- Location: `apps/back-office/e2e/smoke.spec.ts:59-67`; `gates/08-playwright.log:24-31`; failure context `gates/playwright-results/smoke-a-receptionist-is-se-ab0d1-3-for-an-owner-manager-page-ar/error-context.md:21-45`.
- Problem: The Arabic receptionist test expected the app shell URL with a branch query, but stayed at `/login`. The error context shows invalid email and password controls. The evidence confirms the flow fails; it does not establish the proposed RTL/session root cause.
- Evidence: Playwright recorded 29/30 passing, with the Arabic test failing and its English equivalent passing (`GATES.md:122-139`). Settings-specific Playwright tests passed in both locales (`GATES.md:125-139`).
- Fix: Repair the Arabic sign-in flow so the localized email and password controls are populated and accepted. Add value assertions after filling the form in `apps/back-office/e2e/fixtures.ts:41-45`, or correct the login/session path if the values are already present. Preserve the app-shell and authorization-denial assertions in `smoke.spec.ts:59-67`; rerun the failed Arabic test and full Playwright suite on current HEAD. Do not skip or weaken the test.
- Plan item: Phase 1.2 acceptance, all settings in EN and AR/RTL (`plan/parts/11-delivery-plan.md:480-486`), and phase-level receptionist/settings isolation (`plan/parts/11-delivery-plan.md:409`).

#### F-verifier-1: Gate results do not cover the current repository commit

- Severity: blocker.
- Location: `gates/GATES.md:5-8,45-56,150-175`; current repository state is branch `fix/phase-0-audit`, HEAD `105104354d55ff95f1cfe5770210a4da5e1eeddd`, clean.
- Problem: Gate logs target `main` at `916121fbf5568a1e6929e5e9b61f7fe3346f865e`, not current HEAD. Later commits changed source and the Deno test runner; no supplied gate report verifies the current tree.
- Evidence: `GATES.md:54-56` records failing Edge Function and Playwright gates on the old commit. Current `package.json:14-15` points to the new runner, and `scripts/fn-test.sh:1-24` runs all function directories. There is no current-HEAD gate report (`adjudication.md:15,72-78`).
- Fix: Run every required gate from a clean checkout/worktree of `105104354d55ff95f1cfe5770210a4da5e1eeddd`, save each command's output, and update the audit report with those exact results. Verify that provisioning and invite Deno tests execute and pass, and that the Arabic Playwright test and full suite pass. Do not reset or mutate the audited worktree to obtain evidence.
- Plan item: all Phase 1 test requirements, especially `11-delivery-plan.md:435-440,480-486,523-529`.

### Rejected, corrected, or informational reports

- F-DB-1, omitted explicit seed currency/plan: rejected. Valid schema defaults apply; no plan requirement or ADR is violated (`database.md:308-323`; adjudication §7).
- F-BE-1, provision-tenant lacks `Idempotency-Key`: rejected. The plan requires idempotent reruns, which slug/owner matching supplies; ADR-31's mandatory header is scoped to money-moving mutations (`backend.md:341-365`; adjudication §7).
- F-BE-2, `_shared` blast radius undocumented: rejected. ADR-32 and architecture documentation already state that shared changes affect all functions (`plan/decisions.md:498-503`; adjudication §7).
- F-BE-3 and F-1.2-1, settings RPCs granted to `authenticated` / direct-write deviation: rejected. Role-checked RPCs are the ADR-28-compliant path; authenticated execution is necessary for the client-callable RPCs and pgTAP covers role authorization (`20261005120100_settings_rpcs.sql:1-7,14-47,391-417`; adjudication §7).
- F-FE-2, Sentry as uncommitted WIP: rejected as stale. Current tree is clean and the work is represented by commits `b5ce3b2` and `0fec7de` (`adjudication.md:87`).
- F-FE-3, suspected RTL Stack alignment: rejected as speculative; the component uses flex alignment without physical left/right positioning, and Stylelint passed (`packages/ui/src/Layout.module.css:8-10,53-67`; `GATES.md:55,111-120`).
- F-FE-4, missing today's operational home data: not a finding; that screen belongs to a later phase (`frontend.md:300-302`).
- F-DB-2 and F-1.1-1, onboarding tests skipped by the old test loop: valid against the old gate snapshot, but resolved in current source by `scripts/fn-test.sh` and `package.json:15`. Execution on current HEAD is still outstanding under F-verifier-1 (`adjudication.md:83`).
- F-DB-3, Phase 0 provisioning migration is replaced by a later Phase 1 migration: informational only, no fix required (`database.md:340-347`).

## 8. Not verifiable locally

The verifier identified no Phase 1 acceptance criterion that requires a cloud environment to evaluate. This report does not establish production deployment, hosted Sentry delivery, uptime, or cloud-region behavior; if those are release requirements, prove them after deployment with the deployment record and live telemetry. Their absence is not counted as a Phase 1 failure here.

## 9. Fix prompt

```text
Fix the phase 1 audit findings below in /Users/fahadasad/glowdesk, in order.
Context: @plan/parts/11-delivery-plan.md @plan/decisions.md @plan/CONVENTIONS.md
Skills: /feature-delivery /spa-domain-glossary /spa-platform-architecture /react-frontend /i18n-rtl

1. F-FE-1: apps/back-office/e2e/fixtures.ts and the Arabic login/session flow - make the localized email and password controls populate and authenticate; add assertions for their values after filling. If the values are already populated, fix the actual login/session path instead. Keep the app-shell and role-denial assertions in apps/back-office/e2e/smoke.spec.ts:59-67. Do not weaken or skip the test.
2. F-verifier-1: use a clean checkout/worktree of commit 105104354d55ff95f1cfe5770210a4da5e1eeddd; run every required Phase 1 gate, save each command's output, and confirm the onboarding provisioning and invite Deno suites execute and pass. Confirm the Arabic receptionist test and full Playwright suite pass, then update the audit evidence to name this exact commit and its results. Do not mutate the existing audited worktree to produce the evidence.

Rules: never edit an applied migration (add a new one); keep both skill copies identical; use Conventional Commits for code changes. Done means every gate in the audit passes again and each fixed acceptance criterion is demonstrated by a test.
```

### Finding summary

| ID | Severity | Title |
|---|---|---|
| F-FE-1 | blocker | Arabic receptionist sign-in does not reach the app shell |
| F-verifier-1 | blocker | Gate results do not cover the current repository commit |

Counts: 2 blockers, 0 majors, 0 minors accepted.

Detailed auditor handoffs: `conformance.md`, `database.md`, `backend.md`, and `frontend.md` in `/Users/fahadasad/hermes-council/output/audit/phase-1/`. The verifier's ruling and exact adjudication are in `adjudication.md`.