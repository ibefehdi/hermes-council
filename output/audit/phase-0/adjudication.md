# Phase 0 adjudication

## Verdict: FAIL

Phase 0 is not complete. The checked repository has no CI or deployment workflows, no Sentry transport, and the health-function smoke gate fails; each blocks a phase requirement or acceptance criterion. The substantive tenancy/RLS, frontend/i18n, and calendar-spike work is mostly sound, but there are also an onboarding failure path, out-of-sync skill copies, and a Deno test command that stops before reaching onboarding tests.

## Scope and freshness

The four auditor files and the shared blackboard were reviewed, and the blockers and majors were re-checked against repository files and gate evidence. The conformance checklist names all five subphases and phase exit criteria, but it is not an exhaustive row-for-row transcription of every plan section as its brief required; its statuses are therefore corrected below rather than accepted wholesale.

The gate run in `gates/GATES.md` reports the repository at `2e22eff2a90c8f09e7d98534cb35e11c9df4a78c` on `main`. During this verification the repository advanced to `bcc2819e22a686d1c0559698f63a882c9a28f116` on `fn/onboarding-provisioning`, and `supabase/migrations/20261005110000_create_tenant_catalogues.sql` was untracked. The intervening commit adds Phase 1 database work and updates generated types, seed data, and a database test; it does not change the CI, Sentry, health, onboarding-handler, or skill-copy files adjudicated here. Consequently the gate counts below are valid evidence for the recorded earlier snapshot, not a fresh test run of the later commit and untracked migration. The final report must disclose this distinction and must not describe the current checkout as the gate-tested `main` snapshot.

## Findings adjudication

### Accepted findings

#### F-VERIFIER-1: CI and deployment workflows are missing
- Severity: blocker. This merges F-DB-1, F-BE-1, F-FRONTEND-1, F-CONFORM-1, and the duplicate CI-drift findings F-CONFORM-4 / F-FRONTEND-6 / F-FRONTEND-10.
- Evidence: `/Users/fahadasad/glowdesk/.github` does not exist. Phase 0.1 explicitly requires `ci.yml`, `deploy.yml`, and the clean-migration gate (`plan/parts/11-delivery-plan.md:213-214,226-232,236-243`). The gate table does not substitute for persistent CI or a staging-to-production deploy pipeline (`gates/GATES.md:62-70`).
- Ruling: accepted. The phase exit criteria for CI, deployment, and an automated clean-migration gate are not met.
- Fix: add `.github/workflows/ci.yml` implementing the pinned clean-migration gate, generated-type drift check, Deno tests, Vitest, lint, build, and size checks; add `.github/workflows/deploy.yml` that promotes migrations, functions using `--use-api`, and the frontend from the same commit through staging and production.

#### F-VERIFIER-2: Sentry is not integrated
- Severity: blocker, raised from the auditors' major rating because Phase 0.1 and 0.3 each have explicit Sentry acceptance criteria (`plan/parts/11-delivery-plan.md:215,230,314-319`).
- Merges F-BE-3, F-DB-4 (Sentry portion), and F-CONFORM-2.
- Evidence: `supabase/functions/_shared/logging.ts:38-45` says a transport will be wired but `captureException` only logs; repository search found no Sentry SDK/init or DSN configuration in the frontend or functions.
- Fix: add and initialize the frontend and Deno Sentry SDKs, configure the DSN via environment/secrets, wire `_shared/logging.ts:captureException` to send exceptions, and demonstrate a deliberately generated exception arriving in the staging Sentry project.

#### F-VERIFIER-3: Health function fails its smoke check and does not boot locally
- Severity: blocker, raised from F-DB-5 because the 0.3 health-route acceptance criterion and a required gate are not satisfied.
- Evidence: `gates/fn-test.log:9-23` records both health tests failing (expected 200 and request ID, received 503 and null); a read-only request to `http://127.0.0.1:54321/functions/v1/health` returned HTTP 503 with `BOOT_ERROR`. The implementation is `supabase/functions/health/health_test.ts:6-16`. The gate log says the local Functions server was not running; Supabase's local quickstart explicitly runs `supabase functions serve <name>` after `supabase start` when testing a function: https://supabase.com/docs/guides/functions/quickstart.
- Ruling: the evidence does not isolate whether the immediate cause is a missing local serve step, a worker boot error, or both. It does establish a failing gate and an unproven health endpoint; it is not acceptable to mark the criterion DONE.
- Fix: make the local health test setup start/serve the health function, inspect and resolve any worker boot error, and require the smoke test to pass with HTTP 200, the expected envelope, and `x-request-id`. Then verify the staged endpoint separately.

#### F-VERIFIER-4: The Deno test command exits before onboarding tests
- Severity: major.
- Evidence: root `package.json:15` loops over function directories but exits on the first directory failure (`|| exit 1`). The recorded run fails in `health/` (`gates/fn-test.log:9-28`) and contains no onboarding test results, although `supabase/functions/onboarding/onboarding_test.ts` contains the onboarding integration tests (see its tests at lines 93-157). Thus the 38 passing Deno tests do not establish that the onboarding tests passed.
- Fix: change the test runner to collect each directory's exit code and continue through all function suites before returning nonzero, and make the gate explicitly report the onboarding suite result. Keep the health failure visible rather than suppressing it.

#### F-BE-5: A failed provisioning RPC can leave a newly invited owner without a tenant
- Severity: major.
- Evidence: `supabase/functions/onboarding/handlers.ts:49-63` creates/invites the owner before calling `provision_tenant`; RPC errors are thrown without compensating cleanup. The existing duplicate-slug test only covers the pre-invite check (`onboarding_test.ts:149-156`), not an RPC failure after a new invite.
- Ruling: accepted. The migration makes tenant, branch, membership, and audit-row creation atomic, but that database transaction cannot roll back the preceding Auth invite.
- Fix: when `ownerInvited` is true and `provision_tenant` fails, perform a compensating deletion for that newly created Auth user and record any cleanup failure for retry; add a test that forces the RPC failure and verifies no orphan remains. Do not delete an existing owner account.

#### F-CONFORM-3: The Cursor and Claude skill copies differ
- Severity: major.
- Evidence: a direct recursive diff found differences in `.cursor/skills/react-frontend/SKILL.md`, `.cursor/skills/react-frontend/reference.md`, and `.cursor/skills/i18n-rtl/reference.md` versus their `.claude/skills/` counterparts. The plan appendix requires identical copies (`plan/parts/15-appendix.md:21`; also `plan/PLAN.md:5326`).
- Fix: synchronize the three `.claude/skills/` files with the implementation-accurate `.cursor/skills/` copies and keep both trees identical.

#### F-BE-7: The generic secret-auth environment variable is undocumented
- Severity: minor (reduced from major). The only Phase 0 function using secret auth explicitly configures `PLATFORM_ADMIN_SECRET`; the generic `DEFAULT_SECRET` path is not currently used by that function.
- Evidence: `supabase/functions/_shared/auth.ts:91-102` names `INTERNAL_FUNCTION_SECRET` as the generic default, while `supabase/functions/.env.example:1-4` documents only `PLATFORM_ADMIN_SECRET`.
- Fix: document `INTERNAL_FUNCTION_SECRET` as a placeholder in `.env.example`, state that per-function `SecretConfig` can override it, and do not ship a usable production credential in the example.

### Rejected, merged, or not-verifiable findings

- F-DB-2 (branches pulled forward) — rejected as a defect. The Phase 0 composite-FK design needs `branches` as the parent target; the migration comment explicitly records why it lands with the tenancy skeleton (`20261004170200_create_branches.sql:1-2`). This is a justified, disclosed pull-forward, not an undeclared deviation.
- F-DB-3 (provisioning RPC pulled forward) — rejected as a defect. Phase 0.2 includes an onboarding provisioning path; the migration comment declares that the RPC is the minimal path and that full provisioning remains in Phase 1.1 (`20261004172000_create_provision_tenant.sql:1-4`).
- F-DB-4 uptime-monitor/log-drain portion and F-BE-4 — NOT VERIFIABLE LOCALLY, not failed. `supabase/functions/monitors.json` contains health and onboarding probes (`:1-18`), but an external monitor firing on simulated downtime and a hosted log drain require the configured cloud service. Verify those in staging; do not claim they passed locally.
- F-DB-6 (deterministic seed UUID style) — rejected; deterministic UUIDs are intentional test fixtures and no Phase 0 safety or acceptance defect was shown.
- F-DB-7 (Realtime channel authorization test) — rejected for Phase 0. The phase does not deliver a Realtime subscription or `useRealtime` hook; ADR-38 describes that hook and its authorization test as part of the Realtime implementation, not a reason to invent a subscription test for this foundation-only phase. No publication/subscription implementation was found in the Phase 0 migrations or application code.
- F-BE-2 and the validation-contract-test naming concern under F-BE-6 — rejected as non-defects. The per-function key boundary matches the unique constraint `(tenant_id, key, function_name)`, and the Deno contract test is present and ran in the `_shared` suite.
- The separate F-BE-6 rate-limit observation is explicitly DEVIATED-JUSTIFIED by ADR-47; do not raise it again.
- F-FRONTEND-2, F-FRONTEND-3, and F-FRONTEND-4 were retracted by their auditor and are not findings. F-FRONTEND-7/8 are positive notes, not findings. F-FRONTEND-9 describes a passing two-locale test and is rejected as a defect.
- F-FRONTEND-5 is a documented ADR-41 gap that must close before Phase 5 exits, not a Phase 0 failure. ADR-41 records keyboard create/reschedule/cancel as GO for the spike and explicitly assigns the remaining in-grid navigation gap to Phase 5 (`plan/decisions.md:576-596`; `plan/evidence/0.5/results.md:38-47`).
- F-FRONTEND-6 and F-FRONTEND-10 are duplicates of F-VERIFIER-1, not separate defects: `gates/verify.log:6-12` shows CSS lint and size-limit passed locally. CI enforcement is addressed by the missing-CI finding.
- F-FRONTEND-11 (favicon) is not a Phase 0 plan requirement. The frontend walkthrough reports a 404, but it does not affect the phase's listed acceptance criteria.
- F-CONFORM-4 (generated-type CI drift check) is merged into F-VERIFIER-1. The local type-drift gate passed for the older snapshot (`gates/GATES.md:66`), while the required recurring CI check is absent.
- F-CONFORM-5 (no-access test) is rejected. `apps/back-office/e2e/smoke.spec.ts:34-47` exercises the no-membership path; `gates/playwright.log:10,18,26-28` records the test passing in both English and Arabic as part of 20 passing Playwright tests.

## Checklist corrections and acceptance criteria

The plan defines five subphases (0.1-0.5) and four phase-level exit criteria (`plan/parts/11-delivery-plan.md:202-202` and `:206-393`). The conformance checklist includes all five, so no subphase is omitted. Its “every DONE row” assertions still require correction where evidence conflicts with the gate logs.

| Scope | Verified status | Evidence / ruling |
|---|---|---|
| Phase exit: CI green on a PR | MISSING | No `.github/workflows/`; F-VERIFIER-1. |
| Phase exit: staging-to-production deploy | MISSING | No deploy workflow; F-VERIFIER-1. Cloud deployment itself is not locally testable. |
| Phase exit: clean-migration gate | NOT DONE | Local reset, pgTAP, lint, and type-drift results passed for the gate snapshot, but no CI gate exists; the Deno gate failed and current repository state later advanced. |
| Phase exit: ADR-41 spike verdict | DONE | ADR-41 records the fallback GO and evidence (`plan/decisions.md:576-596`; `plan/evidence/0.5/results.md:12-21`). The ADR-authorized fallback means premium evaluation was not required after the no-license ruling. |
| 0.1 repository/environment foundation | INCOMPLETE | Monorepo exists; CI/deploy and Sentry missing. Staging/production project configuration, production region, external uptime service, and hosted log drain are NOT VERIFIABLE LOCALLY. |
| 0.2 tenancy/auth acceptance | DONE WITH FIXES | Playwright proves login/shell and no-access in both locales (`gates/playwright.log:7,10,15,18`); pgTAP has 149 passing tests (`gates/GATES.md:64,76`). `002_tenancy_rls.test.sql:7-17,136-142` directly checks outsider isolation and immediate membership revocation. Orphan-invite failure is F-BE-5. |
| 0.3 Edge Function platform acceptance | INCOMPLETE | Shared modules and validation contract tests passed in the recorded Deno run, but two health tests failed (`fn-test.log:3-22`), local health returned BOOT_ERROR, Sentry is absent, and onboarding tests were skipped by short-circuiting. |
| 0.4 frontend acceptance | DONE WITH FIXES | Money and branch-timezone formatter assertions are present (`packages/i18n/src/format.test.ts:8-50`); root verification reports 79 Vitest tests, typecheck, lint, build, and size-limit passing (`gates/verify.log:4-12`); Playwright reports 20/20 across `en` and `ar` (`gates/playwright.log:3-28`). Skill-copy drift is F-CONFORM-3; the type-drift CI check is included in F-VERIFIER-1. |
| 0.5 calendar spike | DONE | ADR-41 and spike results record passing fallback performance, keyboard operation, RTL, staff-column, bundle, and drag budgets (`plan/evidence/0.5/results.md:12-21`). Remaining quality gaps are expressly assigned to Phase 5 (`:38-47`). |

Independent security spot-check: the live membership helpers in `20261004170400_create_memberships.sql:51-114` filter by `auth.uid()`, active membership, tenant, role, and branch; all pin `search_path`. The policies in `20261004170500_tenancy_policies.sql:4-42` scope tenant/branch reads. The privileged provisioning RPC revokes execute from public/anon/authenticated and grants it only to `service_role` (`20261004172000_create_provision_tenant.sql:88-91`), while the Edge Function requires its explicit platform-admin secret (`supabase/functions/onboarding/index.ts:4-9`). The pgTAP evidence covers cross-tenant reads, unauthenticated access, branch role checks, revocation, and rejected privileged writes. This spot-check found no additional cross-tenant or cross-branch access defect.

## Deviations and external verification

- The calendar choice is DEVIATED-JUSTIFIED: ADR-41 records that premium was unavailable to evaluate and authorizes the core/custom-view fallback; its measured evidence meets the Phase 0 spike decision criteria.
- Branches and the minimal tenant-provisioning RPC were pulled forward from Phase 1.1 for explicit composite-FK and onboarding prerequisites; both migration headers record the rationale and boundary. These are justified, disclosed deviations.
- The skills mismatch is an undeclared and unjustified process deviation (F-CONFORM-3).
- Staging/prod CI and deploy execution, the deployed health/Sentry acceptance checks, external uptime-monitor firing, hosted log-drain wiring, and the ADR-48 production region/legal gate cannot be demonstrated locally. Sentry code is nevertheless missing locally and remains an accepted blocker; cloud delivery does not excuse absent implementation.

## Ordered fix list

1. F-VERIFIER-1 (blocker): add `.github/workflows/ci.yml` and `deploy.yml` with all Phase 0 checks and same-commit staging-to-production deployment.
2. F-VERIFIER-2 (blocker): integrate and initialize Sentry in the frontend and Deno functions, wire `captureException`, and verify a staged exception event.
3. F-VERIFIER-3 (blocker): make the health function boot and return 200 plus the expected envelope and request ID; serve it during the local smoke test and verify the deployed staging endpoint.
4. F-BE-5 (major): compensate for failed tenant provisioning after a new owner invite; add a test for the RPC-failure path.
5. F-VERIFIER-4 (major): change `pnpm fn:test` to continue through all function directories, aggregate failures, and report onboarding test results.
6. F-CONFORM-3 (major): synchronize the three differing `.claude/skills/` files with the implementation-accurate `.cursor/skills/` copies.
7. F-BE-7 (minor): document the generic `INTERNAL_FUNCTION_SECRET` variable in `supabase/functions/.env.example` as a placeholder.
