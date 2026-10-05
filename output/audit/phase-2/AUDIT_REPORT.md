# Phase 2 audit report: Staff & shifts

## 1. Verdict

PASS

Phase 2 is complete against the binding plan, and the audited evidence supports the security and acceptance claims. All three subphases and all six phase-level exit criteria are complete. There are no accepted blockers or major findings. Three minor fixes remain: add a recovery test for an interrupted staff invitation, recheck active staff/branch/type status when updating blocked time, and cover omitted versus empty staff filters through the shift-copy HTTP endpoint. The latest repository commit also changes the Playwright server setup and sign-in fixture after the recorded gates; the phase implementation is unchanged, but the E2E gate should be rerun on that commit before release.

| Subphase | Status |
|---|---|
| 2.1 Staff records | Done with minor fixes |
| 2.2 Shifts | Done with minor fixes |
| 2.3 Blocked time | Done with minor fixes |

## 2. What was audited

- Repository: `/Users/fahadasad/glowdesk`.
- Branch and current HEAD: `main`, `710eedadc6484a21bfd06873a4d0afe1eb391fbc` (`test(e2e): run against a non-watching dev server and assert sign-in field values`).
- The current working tree has no uncommitted changes. `git status --short --branch` reported `## main...origin/main [ahead 1]`; the one commit ahead of `origin/main` is the E2E setup change described below.
- Verification and gate evidence were collected against `edfad112962008246b818f9edf9c3c95591e05c2`. After that verification, commit `710eedadc6484a21bfd06873a4d0afe1eb391fbc` changed `README.md`, `apps/back-office/e2e/fixtures.ts`, `apps/back-office/playwright.config.ts`, and `apps/back-office/vite.config.ts`. It changes how Playwright starts its server and adds assertions to the sign-in fixture; it does not change Phase 2 product implementation. The Playwright gate has not been rerun on this later commit, so the recorded 48-test result applies to `edfad11`, not `710eeda`.
- Audit date: 2026-10-05 (+03).
- Scope: the full Phase 2 section and subphases 2.1–2.3 in `plan/parts/11-delivery-plan.md:543-679`, interpreted under `plan/decisions.md` before `plan/PLAN.md`, `plan/CONVENTIONS.md`, and the project skills, as required by the common audit brief.
- Evidence basis: `adjudication.md` (authoritative verifier ruling), `gates/GATES.md`, and the four auditor reports: `conformance.md`, `database.md`, `backend.md`, and `frontend.md`. No stateful gate or Playwright suite was rerun for this synthesis.

## 3. Gates

The gate table below reproduces `gates/GATES.md:41-55`. The first attempt at Deno tests had three environment BOOT_ERROR failures; after restarting the local Supabase stack, the recorded rerun passed. The retry is documented at `gates/GATES.md:101-105` and is not a failed gate.

| Command/check | Result | Key detail |
|---|---|---|
| `pnpm install --frozen-lockfile` | PASS, exit 0 | Already up to date. `gates/pnpm-install.log`. |
| `pnpm db:reset` | PASS, exit 0 | 30 migrations applied and seed loaded. `gates/pnpm-db-reset.log`. |
| `pnpm db:test` (`supabase test db`) | PASS, exit 0 | 536 tests passed, 0 failed. `gates/pnpm-db-test.log`. |
| `pnpm db:lint` (`supabase db lint --level warning`) | PASS, exit 0 | No schema errors. `gates/pnpm-db-lint.log`. |
| Type drift check | PASS, expected diff exit 1 | Generated TypeScript matches; only three informational banner lines differ. `gates/type-drift.log`; `GATES.md:49,55`. |
| `pnpm fn:test` | PASS, exit 0 | 94 Deno tests passed, 0 failed. `gates/pnpm-fn-test.log`. |
| `pnpm verify` | PASS, exit 0 | Skills check, i18n compile, 8-package typecheck, lint, CSS lint, 177 Vitest tests, build, and size checks passed. `gates/pnpm-verify.log`. |
| Playwright E2E suite | PASS, exit 0 | 48 passed: 24 English and 24 Arabic. `gates/playwright.log`. This run was against `edfad11`; rerun on current HEAD before release. |
| Final `pnpm db:reset` | PASS, exit 0 | All 30 migrations and seed applied cleanly. `gates/pnpm-db-reset.log`. |

Test totals are 536 pgTAP, 94 Deno, 177 Vitest, and 48 Playwright tests, all with zero recorded failures and skips (`gates/GATES.md:57-71`). The Playwright count is the one exception to current-HEAD evidence, as noted above.

## 4. Exit and acceptance criteria

### Phase-level exit criteria

The phase heading at `plan/parts/11-delivery-plan.md:557` contains six exit conditions. All six have evidence; the older conformance report's references to four or five criteria are counting errors, not missing requirements. The verifier checked all six (`adjudication.md:34-43`).

| Criterion | Subphase | Status and evidence |
|---|---|---|
| A staff member assigned to two branches appears in both staff lists and shift grids. | 2.1, 2.2 | DONE. `apps/back-office/e2e/staff.spec.ts:8-48` checks both staff lists; `shifts.spec.ts:99-118` covers branch-specific shift grids (`adjudication.md:34-35`). |
| A branch manager of A cannot see branch B's shifts. | 2.2 | DONE. `apps/back-office/e2e/shifts.spec.ts:110-123` and `supabase/tests/009_shifts_matrix.test.sql` demonstrate branch isolation (`adjudication.md:35`). |
| Non-login staff can be created and scheduled. | 2.1, 2.2 | DONE. `apps/back-office/e2e/staff.spec.ts:30-42` creates non-login staff; `shifts.spec.ts:29-44` schedules staff (`adjudication.md:36`). |
| Typed blocked time appears in the calendar data endpoint. | 2.3 | DONE. `supabase/functions/staff/blocked_time_test.ts:126-159` checks typed blocks in the schedule result (`adjudication.md:37`). |
| Overlapping blocks are rejected. | 2.3 | DONE. `blocked_time_test.ts:61-79` races writes and requires one success; `011_blocked_times_conflicts.test.sql:64-75` tests the exclusion constraint (`adjudication.md:38`). |
| A block over an existing appointment is rejected. | 2.3 | DONE. `blocked_time_test.ts:93-124` tests appointment-buffer conflicts; `011_blocked_times_conflicts.test.sql:86-98` tests the database path (`adjudication.md:39`). |

### Subphase acceptance criteria

| Criterion | Subphase | Status and evidence |
|---|---|---|
| Two-branch staff appears in both branch lists. | 2.1 | DONE. `apps/back-office/e2e/staff.spec.ts:39-42` (`adjudication.md:25`). |
| Non-login staff can be created; invited staff can sign in and see only their own day across branches. | 2.1 | DONE. `staff.spec.ts:30-42,53-89` (`adjudication.md:26`). Minor finding F-BE-1 concerns crash recovery after invitation, not the demonstrated happy path. |
| Arabic staff names are searchable with normalization. | 2.1 | DONE. `staff.spec.ts:44-50` searches a normalized Arabic name (`adjudication.md:27`). |
| Copy-previous-week preserves dated wall times for overnight shifts in a DST-free Kuwait week. | 2.2 | DONE. `apps/back-office/e2e/shifts.spec.ts:46-77` and `supabase/functions/staff/shifts_test.ts:114-163` (`adjudication.md:28`). |
| Branch manager A cannot see branch B shifts. | 2.2 | DONE. `shifts.spec.ts:90-123` and `supabase/tests/009_shifts_matrix.test.sql` (`adjudication.md:29`). |
| Typed blocked time appears alongside shifts in the calendar endpoint. | 2.3 | DONE. `supabase/functions/staff/blocked_time_test.ts:126-159`; UI verification at `apps/back-office/e2e/blocked-time.spec.ts:44-52` (`adjudication.md:30`). |
| Concurrent overlapping blocks are rejected. | 2.3 | DONE. `blocked_time_test.ts:61-79`; `blocked-time.spec.ts:54-56` checks the user-facing conflict (`adjudication.md:31`). |
| A block over an appointment, including its buffer, is rejected. | 2.3 | DONE. `blocked_time_test.ts:93-124`; `blocked-time.spec.ts:57-60` (`adjudication.md:32`). |
| Manager-created time off appears on the staff schedule without an approval flow. | 2.3 | DONE. `blocked-time.spec.ts:80-125`; this behavior follows ADR-53 (`plan/decisions.md:71`, `plan/parts/11-delivery-plan.md:647,661,667`; `adjudication.md:33`). |

## 5. Plan checklist

Statuses below reflect the verifier's adjudication, not unreviewed auditor claims. Detailed implementation evidence is in `conformance.md` and the domain reports named in each section. `PARTIAL` marks only the specific minor edge-case validation or test coverage, not a failed phase acceptance criterion.

### 2.1 Staff records

| Plan area | Status | Evidence / note |
|---|---|---|
| Features: bilingual staff CRUD, contact/job title, bookable status, branch assignments/default branch/per-branch bookable; optional login; branch list/search; cross-branch My Day data. | DONE | Database fields and assignment model: `supabase/migrations/20261006100100_create_staff_members.sql:6-68` and `...staff_rpcs.sql:265-295`. Screens and branches: `frontend.md:28-50`. |
| Database: staff and assignment migrations, partial unique login index, composite foreign keys, RLS/read matrix, audit triggers, search normalization. | DONE | `database.md:47-71`; pgTAP matrix `supabase/tests/008_staff_matrix.test.sql` (64 tests), `conformance.md:37-41`. |
| Edge Functions: `staff/upsert` and `staff/invite-login`. | DONE | `supabase/functions/staff/handlers.ts:74-94,128-213`; upsert is transactional through `upsert_staff_member()`. Invite crash-recovery test remains a minor gap (F-BE-1). |
| Screens: staff list, editor, My Day. | DONE | `frontend.md:28-50`; `apps/back-office/src/features/staff/routes.tsx:22-42`; My Day route at `apps/back-office/src/features/my-day/routes.tsx:5-9`. The tested no-profile empty state is intentional. |
| i18n/RTL: English and Arabic strings, Arabic plurals/search, bidi handling and logical CSS. | DONE | `frontend.md:52-69`; strict catalog check and both locale E2E projects passed in the recorded gates. |
| Tests: pgTAP matrix, invite Deno tests, normalization Vitest, bilingual Playwright CRUD. | PARTIAL (minor) | Required suites ran and passed (`GATES.md:47,50-52`). Add one Deno recovery case simulating an Auth user created before membership/link completion; `adjudication.md:49-54`. |
| Dependencies: Phase 1.3 roles and invite machinery. | DONE | Live membership/authority checks in `conformance.md:75-79`; database RPC checks summarized in `database.md:61-71`. |
| Backlog: staff/assignment database work, upsert/invite functions, list/editor, My Day. | DONE | All listed backlog deliverables at `plan/parts/11-delivery-plan.md:595-600` are implemented; see the rows above. |

### 2.2 Shifts

| Plan area | Status | Evidence / note |
|---|---|---|
| Features: branch/week/staff grid, dated shift create/edit/delete, previous-week copy, overnight shifts, schedule endpoint for Phase 5. | DONE | `conformance.md:83-91`; `supabase/migrations/20261006110000_create_shifts.sql`; schedule RPC in `.../20261006110100_shift_rpcs.sql:137-177`. |
| Database: timestamptz shifts, branch-scoped RLS/audit, overlap exclusion, cross-branch tests. | DONE | `database.md:73-87`; `supabase/tests/009_shifts_matrix.test.sql` (59 tests). |
| Edge Functions: `staff/shifts-materialize` with wall-time copy, overnight/DST handling and staff filtering. | DONE | `conformance.md:100-104`; `backend.md:35-51`; test evidence in `supabase/functions/staff/shifts_test.ts:114-208`. |
| Screens: weekly shift grid (form editing and drag-to-draw) and copy-previous-week action. | DONE | `frontend.md:89-102`; 48 bilingual E2E tests passed on the audited commit. |
| i18n/RTL: translated messages, Arabic plurals, logical CSS and RTL-aware drag behavior. | DONE | `frontend.md:104-121`; `ShiftGridPage.tsx:324-325` adjusts screen-coordinate math by direction. |
| Tests: Deno materialization, Vitest mappers, bilingual Playwright drawing. | PARTIAL (minor) | Test suites passed on `edfad11`, but the served-function test helper always sends `staff_ids` as an array. Add cases for omitted `staff_ids` (copy all) and `[]` (copy none); explicit null is invalid under the shared schema. `adjudication.md:63-68`. Rerun Playwright after current commit `710eeda`. |
| Dependencies: Phase 2.1 staff records. | DONE | Composite foreign key ties shifts to staff in the same tenant; `conformance.md:128-132`. |
| Backlog: shifts migration/tests, materialization function, shift grid and copy action. | DONE | All listed Phase 2.2 backlog items at `plan/parts/11-delivery-plan.md:632-636` are implemented; see the rows above. |

### 2.3 Blocked time

| Plan area | Status | Evidence / note |
|---|---|---|
| Features: typed blocks, branch and all-branches time off, role-specific creation rights, no in-app approval flow. | DONE | `conformance.md:136-145`; this matches ADR-53 (`plan/decisions.md:71`). |
| Database: blocked-time table/exclusion, advisory-locked create/update/delete RPCs, appointment conflict checks, select-only RLS, role and concurrency tests. | PARTIAL (minor) | Core paths are implemented and tested (`database.md:98-117`, `supabase/tests/010_blocked_times_matrix.test.sql`, `011_blocked_times_conflicts.test.sql`). `update_blocked_time` does not recheck active staff/branch/type on update; fix through a new migration and pgTAP cases (F-DB-2, `adjudication.md:56-61`). |
| Edge Functions: blocked-time actions are RPC-only, with no wrapper. | DONE | As specified at `plan/parts/11-delivery-plan.md:657`; `backend.md:55-69`. |
| Screens: per-staff/per-branch block form and list, RPC writes, read-only own blocks for staff, manager-created time off. | DONE | `frontend.md:140-170`; `apps/back-office/e2e/blocked-time.spec.ts:80-125`. |
| i18n/RTL: translated UI, Arabic plural forms, bidi isolation and direction-safe date inputs. | DONE | `frontend.md:158-162`; both locale test projects passed on the audited commit. |
| Tests: pgTAP roles/concurrency, Deno RPC checks and UI flows. | DONE | `supabase/tests/010_blocked_times_matrix.test.sql`, `011_blocked_times_conflicts.test.sql`, `supabase/functions/staff/blocked_time_test.ts`; gates recorded 536 pgTAP and 94 Deno tests passing. The missing active-record update cases are tracked as F-DB-2. |
| Dependencies: Phase 2.1 staff and Phase 1.2 blocked-time types. | DONE | Composite foreign keys and seeded types; `conformance.md:186-191`. |
| Backlog: database table/RPC/concurrency and role tests, block form/list. | DONE | All listed Phase 2.3 backlog items at `plan/parts/11-delivery-plan.md:673-679` are implemented; see the rows above. |

## 6. Deviations

Declared and justified:

- Appointment and appointment-item tables were pulled forward from Phase 5 to support Phase 2's locked cross-entity blocked-time check. `plan/REVISION_LOG.md:129-135` declares this work. The appointment staff-read policy is explicitly deferred to Phase 5.1. This is an intentional, justified pull-forward, not a Phase 2 defect (`adjudication.md:41,72`).
- ADR-53 requires managers to create time off on a staff member's behalf and excludes an in-app request/approval flow from the MVP. The implementation follows that decision (`plan/decisions.md:71`; `plan/parts/11-delivery-plan.md:647,661,667`).
- No other unjustified Phase 2 implementation deviation was accepted. The conformance report's statement that no later-phase work was pulled forward is corrected by the declared appointments work above.

## 7. Findings

### Accepted minor findings

#### F-BE-1: Invite-login recovery after an abrupt interruption

- Location: `supabase/functions/staff/handlers.ts:171-209`.
- Problem: Cleanup handles exceptions after invitation creation, but cannot run if the process terminates between creating the Auth user and granting memberships/linking the staff record. A later retry can find the existing Auth user, but this recovery path has no test.
- Fix: In `supabase/functions/staff/staff_test.ts`, pre-create the Auth user with the staff email but without staff membership/link, then call `staff/invite-login` and assert that it reuses that user, grants eligible memberships, links the staff row, and does not send another invitation. Document retry as the recovery procedure. An idempotency key is not required by the plan.
- Plan item: Phase 2.1 `staff/invite-login` and login-invitation acceptance criterion. Verifier ruling: `adjudication.md:49-54`.

#### F-DB-2: Blocked-time update does not revalidate active records

- Location: `supabase/migrations/20261006120200_blocked_time_rpcs.sql:210-221`.
- Problem: The update path checks authority and conflicts but does not confirm the staff member, existing branch, or changed blocked-time type is still active. Creation performs active-record checks.
- Fix: Add a new migration that updates `update_blocked_time` to reject inactive staff, an inactive non-null branch, and an inactive type when the type is changed, using the prerequisite-state error convention used by `create_blocked_time`. Add pgTAP update cases for each inactive state. Do not edit the applied migration.
- Plan item: Phase 2.3 locked blocked-time RPCs (`plan/parts/11-delivery-plan.md:648,652`). Verifier ruling: `adjudication.md:56-61`.

#### F-CON-2: Shift-copy HTTP tests omit the omitted/empty filter cases

- Location: `supabase/functions/staff/shifts_test.ts:85-92`; wrapper behavior at `supabase/functions/staff/shifts.ts:52-54`.
- Problem: The test helper always sends `staff_ids` as an array. The served function's omitted filter means all staff, while `[]` means no staff, but the HTTP tests verify neither behavior.
- Fix: Add served-function tests that omit `staff_ids` and assert all-staff copying, then send `staff_ids: []` and assert empty-selection behavior. The shared schema rejects explicit null; optionally assert that it returns validation error. Keep expectations clear in test names and assertions.
- Plan item: Phase 2.2 Deno tests for shift materialization (`plan/parts/11-delivery-plan.md:618,628`). Verifier ruling: `adjudication.md:63-68`.

### Rejected findings

- F-DB-1 (staff appointment read policy): Rejected as a Phase 2 defect. The appointment tables were declared as a pull-forward, and the staff read policy is assigned to Phase 5.1. Phase 2 schedule and My Day acceptance are separately demonstrated. `adjudication.md:72`.
- F-BE-2 (invite-login idempotency key): Rejected. The plan does not require an idempotency key for this operation, and the handler looks up an existing Auth user by email before inviting. No acceptance failure was demonstrated. `adjudication.md:73`.
- F-CON-1 (My Day role guard): Rejected. The product deliberately shows a no-staff-profile empty state; a redirect would contradict the tested behavior. RLS remains the data boundary. `adjudication.md:74`.
- F-FE-1 (gradient direction): Rejected. `to right` is gradient syntax, not a layout-property violation, and no user-visible defect was evidenced. `adjudication.md:75`.
- F-FE-2 (`rect.left`/`rect.right`): Rejected. These are DOM screen coordinates; the implementation branches on text direction for its calculation. `adjudication.md:76`.
- F-FE-3 (`left` variable name): Rejected as a naming suggestion only; no behavior or plan violation was shown. `adjudication.md:77`.

| Accepted finding | Severity | One-line title |
|---|---|---|
| F-BE-1 | Minor | Add a test for recovery after interrupted invite-login provisioning. |
| F-DB-2 | Minor | Recheck active staff, branch and type status when updating blocked time. |
| F-CON-2 | Minor | Test omitted and empty staff filters through the shift-copy endpoint. |

Counts: 0 blockers, 0 majors, 3 minors (`adjudication.md:83-94`).

## 8. Not verifiable locally

- Phase 5 consuming the `branch_staff_schedule` contract and Phase 16 using staff records are downstream work and are not acceptance conditions for Phase 2. The conformance report marks these downstream checks not verifiable locally (`conformance.md:271-277`). Verify them when those phases are implemented.
- No Phase 2-specific staging, production, Sentry, or uptime criterion was identified by the verifier (`adjudication.md:81`).
- The Playwright results are verified for `edfad11`, not the post-gate current HEAD `710eeda`. Before release, rerun the Playwright gate on current HEAD; this is a test-evidence freshness check, not an additional adjudicated phase finding.

## 9. Fix prompt

```text
Fix the Phase 2 audit findings below in /Users/fahadasad/glowdesk, in order.
Context: @plan/parts/11-delivery-plan.md @plan/decisions.md @plan/CONVENTIONS.md
Skills: /feature-delivery /spa-domain-glossary /spa-platform-architecture /supabase-database /supabase-edge-functions

1. F-BE-1: supabase/functions/staff/staff_test.ts - add a recovery test that pre-creates an Auth user for the staff email without a membership or staff link, calls staff/invite-login, then proves the existing user is reused, eligible staff memberships and the staff link are created, and no second invitation is sent. Document retry as the recovery procedure. Do not add an idempotency-key requirement.
2. F-DB-2: add a new migration replacing update_blocked_time behavior so it rejects inactive staff, an inactive non-null branch, and an inactive changed blocked-time type, using the prerequisite-state error convention in create_blocked_time. Add pgTAP update cases for all three. Do not edit the applied migration.
3. F-CON-2: supabase/functions/staff/shifts_test.ts - add served-function tests with staff_ids omitted (all staff copied) and staff_ids: [] (none copied); optionally verify explicit null is rejected by schema validation.

Rules: never edit an applied migration; keep both skill copies identical; use Conventional Commits. Done = every gate in this audit passes again and each fixed acceptance criterion is demonstrated by a test. Rerun Playwright on current HEAD 710eedadc6484a21bfd06873a4d0afe1eb391fbc as part of the verification.
```
