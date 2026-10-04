# Phase 1 audit adjudication

## Verdict: FAIL

The phase has substantial implementation and the database/security evidence is strong, but it does not pass the audit gate. The recorded gate run on `main` at `916121fbf5568a1e6929e5e9b61f7fe3346f865e` failed both the Edge Function test command and the Arabic Playwright smoke test. The repository is now on `fix/phase-0-audit` at `105104354d55ff95f1cfe5770210a4da5e1eeddd`, with a clean working tree and additional commits not covered by those logs. No allowed evidence establishes that the current commit passes the gates. The Arabic failure is concrete, but its root cause is not established; the evidence does not justify the auditors’ speculation that RTL itself causes an authentication/session defect.

| Subphase | Adjudicated status | Reason |
|---|---|---|
| 1.1 Provisioning | Done with fixes | Database, ops path, and provisioning implementations exist. The gate run did not execute onboarding Deno tests after earlier `_shared` failures; the current test runner now continues through every function directory, but has not been run on the current commit. |
| 1.2 Settings hub | Incomplete | Screens, database paths, and role-gated RPCs are present; the settings Playwright tests passed in both locales. The complete Playwright gate nevertheless failed in the Arabic receptionist smoke test, and the logs do not cover current HEAD. |
| 1.3 Roles and memberships | Done with fixes | Membership controls and database enforcement are present and the browser member/scope tests passed in both locales. Deno invite tests were not executed in the recorded run, and current-commit gate evidence is absent. |

## Repository and evidence basis

The verifier inspected `/Users/fahadasad/glowdesk` on 2026-10-04. Current state from read-only Git commands: branch `fix/phase-0-audit`, commit `105104354d55ff95f1cfe5770210a4da5e1eeddd`, clean working tree. `GATES.md` records a different target: `main` at `916121fbf5568a1e6929e5e9b61f7fe3346f865e` (GATES.md:5-8). The current branch contains subsequent commits including `b5ce3b2`, `0fec7de`, `3299b9a`, `5476608`, `1800e3d`, and `02ef093`; therefore the gate result table is not a verification of the current HEAD. The current branch adds `scripts/fn-test.sh` and points `pnpm fn:test` to it (`package.json:14-15`), but that change has no gate result in the supplied logs.

The blackboard on `t_9c32f38b` identifies the four completed audit workers and the verifier/synthesizer tasks. All four auditor reports exist and were read, along with `GATES.md`, the phase 1 plan section, and the failed Playwright error context. The reports agree on the principal Arabic test failure and the 320 passing pgTAP assertions; they differ on the settings-RPC ruling and on the status of the required Deno tests. The gate report itself records post-run working-tree changes at the old snapshot (GATES.md:150-175); current Git status is clean, so the frontend finding about currently uncommitted Sentry work does not describe current HEAD.

## Adjudicated acceptance and plan checklist

Evidence for the criteria below is from the named gate logs, tests, or saved evidence. “Done with current-commit verification outstanding” is not a claim that the current HEAD passed a test.

### Subphase 1.1 — Provisioning

- Features and Edge Functions: DONE. Tenant provisioning, branch provisioning, seeded defaults, plan features, and the ops path are present. Conformance report references `supabase/functions/onboarding/handlers.ts:155` and migration `supabase/migrations/20261005110100_provision_branch.sql:115-211`; the Deno tests include repeated tenant provisioning and overnight/split branch provisioning (`backend.md:83-112`).
- Database work: DONE in the recorded database run. The nine Phase 1 migrations and provisioning fixtures are reported in `database.md:14-27`; `GATES.md:50-53` records reset, 320/320 pgTAP, database lint, and type-drift PASS.
- Screens and i18n/RTL: NOT APPLICABLE to this ops-only subphase, as the plan says (`11-delivery-plan.md:433`).
- Acceptance: provisioning evidence records SpaCorner and a repeated idempotent call returning the existing tenant/branch (`plan/evidence/1.3/ops-provision.txt:1-9`). The plan requires overnight/split intervals, zero-length rejection, and a full-day fixture (`11-delivery-plan.md:435-440`); the Deno test source covers these (`backend.md:97-110`) and database tests passed in the gate. However, the required onboarding Deno test suite was not executed by the recorded `pnpm fn:test` run because it stopped after `_shared` failures (`GATES.md:102-109`). Current `scripts/fn-test.sh:1-24` removes the stop-at-first-directory behavior, but has not been run on current HEAD.
- Dependencies and backlog: Phase 0 dependency and each Phase 1.1 backlog item are present per `conformance.md:28-50`; no missing implementation was independently identified.

### Subphase 1.2 — Settings hub

- Features, screens, and database: DONE by inspection. The conformance and frontend reports inventory business settings, setup checklist, branch details/hours/closures/invoicing/tips/methods, cancellation reasons, and blocked-time types (`conformance.md:52-70`; `frontend.md:78-145`). The plan requires all of these (`11-delivery-plan.md:455-478`).
- Edge Function/data-access interpretation: the plan says settings mutations “go direct per the ADR-28 allowlist” (`11-delivery-plan.md:469`). ADR-28 takes precedence and expressly prohibits direct writes to `tenants` and `branches`, requiring an Edge Function or RPC (`plan/decisions.md:461-465`). The frontend calls the settings RPCs directly with `supabase.rpc` (`apps/back-office/src/features/settings/mutations.ts:44-90`, `127-160`); it does not route those settings mutations through an Edge Function. The RPC helpers check live tenant/branch roles (`supabase/migrations/20261005120100_settings_rpcs.sql:14-44`), and pgTAP covers the role matrix (`supabase/tests/006_settings_matrix.test.sql`). This is consistent with the higher-priority ADR and is not an undeclared plan deviation.
- i18n/RTL: DONE by inspection and recorded verification: bilingual fields and direction handling are documented in `frontend.md:174-212`; strict catalog compilation and stylelint passed in `GATES.md:55,111-120`.
- Acceptance: second-branch split/overnight flow is represented by `apps/back-office/evidence/phase1-exit.spec.ts:59-88`; saved database output records Thursday 10:00-14:00 and 18:00-02:00 (`plan/evidence/1.3/db-checks.txt:9-14`). Archiving and row retention are shown in `db-checks.txt:1-7` and `006_settings_matrix.test.sql` (as indexed in `database.md:355-363`). Settings Playwright tests passed 3/3 in each locale (`GATES.md:125-139`). The separate Arabic receptionist smoke failure still causes the full gate to fail; it is not evidence that a settings editor itself failed.
- Currency lock: DONE for Phase 1’s stated scope, not a failure. The plan explicitly says the predicate is unit-tested here and full database enforcement ships with Phase 6 (`11-delivery-plan.md:480-486`). `tenant_currency_locked()` is deliberately false until Phase 6 (`20261005120100_settings_rpcs.sql:62-72`); the UI stays locked until a server answer and has a boolean unit test (`apps/back-office/src/features/settings/lib/currency.ts:1-7`, `currency.test.ts:4-12`), while `phase1-exit.spec.ts:139-148` tests the locked UI with a mocked server answer. pgTAP explicitly describes the pre-Phase-6 false predicate (`006_settings_matrix.test.sql:147-148`). This is the declared cross-phase boundary, not a failed criterion.
- Dependencies and backlog: 1.1 dependency and listed backlog items are covered in `conformance.md:64-70`; no missing screen or feature found.

### Subphase 1.3 — Roles and memberships

- Features/screens: DONE by inspection. Members/roles, invitations, role changes, deactivation, and branch/tenant switchers are inventoried in `frontend.md:146-170` and `conformance.md:72-92`, matching `11-delivery-plan.md:500-521`.
- Database/security: DONE in the recorded run. Membership mutations use grant/authority checks and live-scope validation; grants, forbidden-role cases, audit, last-owner protection, and immediate revocation are covered by the migration and role-grant tests described in `database.md:65-71,171-219,238-253`. Recorded pgTAP: 320/320 passed (`GATES.md:51,85-94`).
- i18n/RTL: DONE by inspection for member names/emails and paired locale fields (`frontend.md:202-212`); EN and AR members/scope Playwright cases passed (`GATES.md:125-139`).
- Acceptance: manager branch scope, receptionist restrictions, invite flow, and next-request role change have browser and database evidence (`frontend.md:236-255`; `conformance.md:76-84`; `007_role_grants.test.sql`). Required Deno invite tests exist, but were not reached in the recorded gate run (`GATES.md:102-109`).
- Dependencies and backlog: Phase 1.1 and 0.4 dependencies and listed backlog are covered in `conformance.md:86-92`; no missing implementation found.

### Phase-level exit criteria

| Criterion | Adjudicated status | Evidence |
|---|---|---|
| Platform ops provisions SpaCorner; owner sees checklist | DONE | `plan/evidence/1.3/ops-provision.txt:1-9`; `phase1-exit.spec.ts:49-57`. |
| Owner creates a branch with overnight and split hours, shown in branch-local context | DONE in saved evidence | `phase1-exit.spec.ts:59-88`; `plan/evidence/1.3/db-checks.txt:9-14`; settings browser suite passed in both locales (`GATES.md:125-139`). |
| Manager sees only assigned branches; receptionist cannot write settings | DONE in targeted recorded tests | Database role matrix (`database.md:238-253`) and settings/scope E2E suites (`GATES.md:125-139`); raw UI write attempts are included in the phase exit test source (`phase1-exit.spec.ts:115-124`). |
| Archiving hides a branch and retains its rows | DONE | `plan/evidence/1.3/db-checks.txt:1-7`; database tests described in `database.md:355-363`. |
| Currency UI blocks changes after a sale | DONE for Phase 1 scope; full predicate/database enforcement is Phase 6 | Plan cross-phase note `11-delivery-plan.md:480-486`; unit/UI evidence described above. |
| Role change applies on target’s next request without re-login | DONE in recorded tests | pgTAP immediate-revocation test and member E2E result (`database.md:238-253`; `GATES.md:125-139`). |
| Arabic receptionist smoke test reaches the app shell before role-denial assertion | NOT DONE in recorded gate | The Arabic run remained at `/login`; see `gates/08-playwright.log:24-31` and failure context. This failing gate alone prevents PASS. |

## Findings adjudicated

### Accepted blockers

### F-FE-1: Arabic receptionist Playwright sign-in does not reach the app shell
- Severity: blocker.
- Location: `apps/back-office/e2e/smoke.spec.ts:59-67`; `gates/08-playwright.log:24-31`; `gates/playwright-results/smoke-a-receptionist-is-se-ab0d1-3-for-an-owner-manager-page-ar/error-context.md:21-45`.
- Problem: the Arabic receptionist test expected `/?branch=...` and remained on `/login`. The error context shows the Arabic login page with email and password controls marked invalid. The evidence proves the Arabic test flow fails; it does not prove the frontend auditor’s proposed locale/session root cause.
- Evidence: the E2E gate has 29/30 passing and this one failure; the English equivalent passes (`GATES.md:122-139`). The settings-specific tests pass in both locales, so do not characterize this as a demonstrated failure of every Arabic settings screen.
- Fix: repair the Arabic sign-in path so the localized email and password controls are populated and accepted, then the receptionist reaches the shell and is denied the owner/manager page. Add value assertions after filling in `apps/back-office/e2e/fixtures.ts:41-45` (or correct the login/session path if those values are populated) and retain the shell/403 assertions in `smoke.spec.ts:59-67`; rerun the failed Arabic test and full Playwright suite on current HEAD. Do not weaken or skip the assertion.
- Plan item: Phase 1.2 acceptance, “All settings work in EN and AR/RTL” (`11-delivery-plan.md:480-486`), and phase-level receptionist/settings isolation (`:409`).

### F-verifier-1: Gate evidence does not verify the current repository commit
- Severity: blocker.
- Location: `gates/GATES.md:5-8,45-56,150-175`; current Git state: branch `fix/phase-0-audit`, HEAD `105104354d55ff95f1cfe5770210a4da5e1eeddd`, clean.
- Problem: gate results and the auditor reports are tied to `main` at `916121f`, while the requested repository is now at a later, different commit. The later tree changes the Deno test runner and includes other source/dependency changes. No supplied log verifies those changes. The gate report also records 13 post-run working-tree changes at its snapshot; current state is clean, but this does not establish which gates pass on current HEAD.
- Evidence: GATES reports Edge Function tests FAIL (31 pass, 9 fail) and Playwright FAIL (29 pass, 1 fail) at lines 54-56; current `package.json:15` invokes the new runner, and `scripts/fn-test.sh:1-24` collects every function directory before failing. No current-HEAD gate report is present.
- Fix: run the full required gate set from a clean checkout/worktree of `105104354d55ff95f1cfe5770210a4da5e1eeddd`, save each command’s output, and update the phase report with those exact results. The failed AR test must pass; Deno tests for both provisioning actions and invite-user must execute and pass. Do not reset or mutate the audited worktree to obtain the evidence.
- Plan item: all phase 1 test requirements, especially `11-delivery-plan.md:435-440,480-486,523-529`; verifier gate rule requires current evidence.

### Rejected or corrected findings

- F-DB-1 (seed omits explicit currency/plan): reject. The phase does not require explicit seed values; the seed uses the schema’s valid defaults. No acceptance criterion or ADR is violated (`database.md:308-323`).
- F-DB-2 and F-1.1-1 (test loop skipped onboarding): accept as a valid finding against the gate snapshot, but resolved in the current source by `scripts/fn-test.sh` and `package.json:15`; the current-commit execution is still outstanding under F-verifier-1. Do not prescribe reverting or weakening the test loop.
- F-BE-1 (provision-tenant lacks Idempotency-Key): reject. Phase 1 requires idempotent re-run safety, not the money-mutation key protocol; slug/owner matching is the intended business idempotency check and repeated-call tests are present (`11-delivery-plan.md:418,435-440`; `backend.md:91-102,341-365`). ADR-31 scopes the mandatory header to money-moving mutations (`plan/decisions.md:488-493`).
- F-BE-2 (_shared blast radius undocumented): reject. ADR-32 itself documents that an `_shared` change redeploys all functions and affects every domain (`plan/decisions.md:498-503`); the architecture documentation repeats the same consequence (`plan/parts/06-architecture.md:176-178`).
- F-BE-3 and F-1.2-1 (settings RPCs granted to authenticated / alleged direct-write deviation): reject. ADR-28 explicitly prohibits direct writes to `tenants` and `branches` and requires RPC or Edge Function paths (`plan/decisions.md:461-465`). The settings migration implements direct Supabase-callable RPCs with live authorization helpers and denies clients direct access to those helper functions (`20261005120100_settings_rpcs.sql:1-7,14-47,391-417`); frontend mutations call `supabase.rpc` directly (`apps/back-office/src/features/settings/mutations.ts:44-90,127-160`). This honors the higher-precedence ADR; the authenticated grant is necessary for that direct RPC path, not a privilege escalation. Recorded pgTAP checks the role matrix (`006_settings_matrix.test.sql`; `GATES.md:51`).
- F-FE-2 (Sentry is uncommitted WIP): reject as stale for current HEAD. The gate report records those files as modified/untracked at its earlier snapshot (`GATES.md:150-175`), but the current tree is clean and the Sentry work is represented by commits `b5ce3b2` and `0fec7de` on the current branch.
- F-FE-3 (Stack RTL alignment): reject as speculative. The finding states the component was not inspected; `packages/ui/src/Layout.module.css:8-10,53-67` uses flex row and flex alignment with no physical left/right positioning, and the logical-property stylelint gate passed (`GATES.md:55,111-120`).
- F-FE-4: not a finding; today’s operational home data is assigned to a later phase, as the frontend auditor correctly notes (`frontend.md:300-302`).
- F-DB-3: informational only; the later Phase 1 migration replaces the Phase 0 provisioning function (`database.md:340-347`).

## Deviations and additional security sweep

- Settings RPC implementation is compliant with ADR-28’s higher-precedence requirement for tenant/branch writes; classify it as no deviation, not `DEVIATED-UNJUSTIFIED`.
- Sentry was pulled forward after the gate snapshot and is represented by named commits. It is not a current uncommitted Phase 1 change; the current branch still requires gates because those commits were not in the gate snapshot.
- The recorded 320 pgTAP assertions include cross-tenant and cross-branch role tests, denied writes, membership revocation, and audit checks (`database.md:238-253,266-291`; `GATES.md:85-94`). Settings role helpers check live memberships and are not executable by clients (`20261005120100_settings_rpcs.sql:14-47`). I found no separate cross-tenant or privilege-escalation defect supported by the inspected evidence. This conclusion is limited by the gate/current-commit mismatch; do not describe current HEAD as fully security-tested.

## Ordered fix list

1. F-FE-1 (blocker): make Arabic receptionist sign-in populate and authenticate the localized form; preserve the app-shell and authorization assertions; rerun Arabic and full Playwright suites.
2. F-verifier-1 (blocker): execute and archive all required gates on a clean worktree of current HEAD `105104354d55ff95f1cfe5770210a4da5e1eeddd`; verify provisioning and invite Deno tests actually run and pass, and update the report to this commit.

No accepted major or minor code findings remain after rejecting the incorrect or stale reports. The phase remains FAIL until both blockers are resolved and the current-commit gates pass.
