# Phase 2 audit adjudication

Verdict: PASS

Phase 2 is complete against the binding plan, and the evidence supports the security and acceptance claims. All three subphases and all six phase-level exit criteria are DONE. The eight reported gates passed. Three accepted minor findings concern recovery/test coverage for invite-login, active-status validation when updating a blocked-time row, and an untested empty-versus-omitted staff filter on the shift-copy HTTP path. There are no accepted blockers or majors.

## Audit basis and repository state

- Specification: `/Users/fahadasad/glowdesk/plan/parts/11-delivery-plan.md:543-679`, including Phase 2 and subphases 2.1–2.3.
- Binding ADRs: `/Users/fahadasad/glowdesk/plan/decisions.md`; Phase 2 time-off behavior is explicitly governed by ADR-53 and ADR-24.
- Repository: `/Users/fahadasad/glowdesk`, branch `main`, HEAD `edfad112962008246b818f9edf9c3c95591e05c2` (`test(evidence): demonstrate Phase 2 exit criteria`, 2026-10-05). A fresh `git status --short --branch` showed `## main...origin/main` and no modified or untracked files.
- Gates were reviewed from `/Users/fahadasad/hermes-council/output/audit/phase-2/gates/GATES.md` and its referenced logs. No stateful gate or Playwright suite was rerun.
- Evidence review included all four auditor reports and their Kanban handoffs/comments. The root blackboard has topology plus frontend and database handoffs; backend and conformance reports were independently read.

## Gate decision

All eight gates are PASS, as reported in `gates/GATES.md:41-55`: frozen install; database reset; database tests; database lint; generated-type drift check (the documented exit code 1 is only the three banner-line diff); Deno tests; `pnpm verify`; and Playwright. Test totals in `gates/GATES.md:57-71` are 536 pgTAP, 94 Deno, 177 Vitest, and 48 Playwright (24 English and 24 Arabic), all with zero failures. The final database reset also passed. The first Deno attempt had three environment BOOT_ERROR failures; after restarting the local Supabase stack, the recorded rerun passed 94/94 (`GATES.md:101-105`). This is a resolved environment retry, not a failing gate.

## Scope and acceptance adjudication

The conformance report covers all three subphases. Its detailed checklist contains features, database work, Edge Functions, screens, acceptance criteria, tests, dependencies, and backlog for 2.1, 2.2, and 2.3. The frontend report supplements it for i18n/RTL and screen behavior. Each plan acceptance criterion was checked against the cited test or implementation evidence:

| Plan item | Ruling | Evidence checked |
|---|---|---|
| 2.1: staff assigned at two branches appears in both staff lists | DONE | `apps/back-office/e2e/staff.spec.ts:8-48` creates one staff member with two assignments and asserts the row in both lists. |
| 2.1: non-login staff can be created; login staff can be invited and see only their own day across branches | DONE | `staff.spec.ts:30-42` creates no-login staff; `staff.spec.ts:53-89` accepts an invite and verifies the staff member's own branches and denied staff-management access. |
| 2.1: Arabic staff names search with normalization | DONE | `staff.spec.ts:44-50` searches an unvowelled Arabic name and checks the result. |
| 2.2: copy-previous-week preserves dated wall times for an overnight shift in a DST-free Kuwait week | DONE | `apps/back-office/e2e/shifts.spec.ts:46-77` verifies overnight copy in the UI; `supabase/functions/staff/shifts_test.ts:114-163` checks copied Kuwait wall times; lines 165-208 exercise a synthetic DST zone. |
| 2.2: manager of branch A cannot see branch B shifts | DONE | `shifts.spec.ts:90-123` verifies a Hawally manager remains scoped to Hawally and cannot see the Jahra shift; `supabase/tests/009_shifts_matrix.test.sql` is also cited in `conformance.md:97-99`. |
| 2.3: typed blocked time appears in the calendar data endpoint | DONE | `supabase/functions/staff/blocked_time_test.ts:126-159` verifies a typed block is returned alongside a shift; `blocked-time.spec.ts:44-52` verifies the UI type and branch. |
| 2.3: overlapping blocks are rejected | DONE | `blocked_time_test.ts:61-79` races overlapping writes and requires exactly one success; `blocked-time.spec.ts:54-56` checks the user-facing conflict. |
| 2.3: a block over an appointment is rejected | DONE | `blocked_time_test.ts:93-124` checks an appointment buffer conflict and its free edge; `blocked-time.spec.ts:57-60` checks the UI conflict. |
| 2.3: manager creates time off on behalf of staff, visible on the staff schedule, without an approval flow | DONE | `blocked-time.spec.ts:80-125` verifies manager-created all-branch time off appears in both branches and on the staff member's read-only My Day. ADR-53 is recorded at `plan/decisions.md:71` and the plan rule at `11-delivery-plan.md:647,661,667`. |
| Phase exit: two-branch staff appears in both lists and shift grids | DONE | Staff-list assertions above; the two-branch shift setup and branch grid are in `shifts.spec.ts:99-118`. |
| Phase exit: manager of A cannot see branch B shifts | DONE | `shifts.spec.ts:110-123` and the pgTAP test cited above. |
| Phase exit: non-login staff can be created and scheduled | DONE | Creation is shown in `staff.spec.ts:30-42`; shift scheduling is shown in `shifts.spec.ts:29-44`. |
| Phase exit: typed blocked time appears in the calendar data endpoint | DONE | `blocked_time_test.ts:126-159`. |
| Phase exit: overlapping blocks are rejected | DONE | `blocked_time_test.ts:61-79`. |
| Phase exit: block over appointment is rejected | DONE | `blocked_time_test.ts:93-124`. |

The plan's Phase 2 heading has six semicolon-separated exit conditions (`11-delivery-plan.md:557`), not five. The conformance report's own exit table at lines 197-205 lists six and provides evidence for each; its top-level prose and Kanban metadata saying “5” are a count error, not a missing criterion. The database report describes the appointment tables as work pulled forward; this is explicitly declared in `plan/REVISION_LOG.md:129-135`, so the conformance report's statement “None” at `conformance.md:237-239` is incorrect and is corrected here. The pull-forward is justified and does not fail Phase 2.

Subphase statuses: 2.1 Staff records — done with minor fixes; 2.2 Shifts — done with minor fixes; 2.3 Blocked time — done with minor fixes. All six phase exit criteria are DONE.

## Findings adjudication

### Accepted findings

#### F-BE-1 — invite-login recovery after an abrupt interruption
- Ruling: Accept with a narrowed problem statement and revised fix; severity remains minor.
- Location: `supabase/functions/staff/handlers.ts:171-209`.
- Evidence: the function creates/invites an Auth user at lines 174-181 and only compensates for errors caught in the later `try/catch` at lines 184-209. A process termination between those operations cannot run that cleanup. A subsequent call does look up an existing user by email (`handlers.ts:96-100`) and can continue membership/link steps, which limits the impact, but there is no test for this recovery path.
- Fix: Add a Deno test that simulates the post-invite/pre-link state by pre-creating the Auth user with the staff email and no staff membership/link, then calls `staff/invite-login` and asserts it reuses the same user, grants the eligible staff memberships, links the staff record, and does not send a second invitation. Document retry as the recovery procedure. Do not add an idempotency requirement absent from the plan.
- Plan item: Phase 2.1 Edge Function `staff/invite-login` and acceptance criterion for login invitation.

#### F-DB-2 — update_blocked_time does not revalidate active records
- Ruling: Accept; severity remains minor.
- Location: `supabase/migrations/20261006120200_blocked_time_rpcs.sql:210-221`.
- Evidence: after write-authority validation, the update RPC validates the range/type only conditionally and checks conflicts, but does not verify that the staff member or the existing branch remains active. In contrast, creation checks active staff and branch, as cited in `database.md:352-366`.
- Fix: In `update_blocked_time`, after the authority check and before conflict checking, reject an inactive `staff_members` row and an inactive non-null `branches` row with the same prerequisite-state error convention used by `create_blocked_time`. Also reject a newly selected blocked-time type that is inactive even when validating a type change; add pgTAP cases for inactive staff, archived branch, and inactive type on update. Ship via a new migration; do not edit the applied migration.
- Plan item: Phase 2.3 locked blocked-time RPCs (`11-delivery-plan.md:648,652`).

#### F-CON-2 — shift-copy HTTP tests omit omitted/empty staff filter cases
- Ruling: Accept; severity remains minor.
- Location: `supabase/functions/staff/shifts_test.ts:85-92` and `supabase/functions/staff/shifts.ts:52-54`.
- Evidence: the HTTP-test body helper always sends `staff_ids` as an array, including `[]` (`shifts_test.ts:85-92`). The wrapper preserves `[]` but maps null/omitted input to null (`shifts.ts:52-54`); the report notes the RPC distinguishes those cases (`conformance.md:364-370`). Current HTTP tests do not demonstrate either all-staff copy or empty-selection behavior.
- Fix: Add served-function Deno tests that omit `staff_ids` and verify all-staff copy, and send `staff_ids: []` and verify empty-selection behavior. The shared schema at `packages/validation/src/shifts.ts:30-37` permits omission but not explicit `null`; optionally add a test asserting explicit null is rejected as validation error. Keep the expectations explicit in the test names and assertions.
- Plan item: Phase 2.2 Deno tests for shift materialization (`11-delivery-plan.md:618,628`).

### Rejected findings

- F-DB-1 (staff cannot read pulled-forward appointments): Reject as a Phase 2 defect. `plan/REVISION_LOG.md:129-135` declares the appointment tables as an intentional pull-forward and explicitly assigns the staff read policy to Phase 5.1. Phase 2's blocked-time endpoint and My Day acceptance are independently demonstrated by the blocked-time tests. No Phase 2 fix is warranted.
- F-BE-2 (invite-login lacks an idempotency key): Reject as stated. The plan does not require an idempotency key for this operation; ADR-31 covers money mutations. The code looks up an Auth user by email before inviting (`handlers.ts:96-100,171-181`), so a normal retry after a successful invite reuses the user rather than issuing another invitation. The report does not demonstrate duplicate invitations or another acceptance failure.
- F-CON-1 (My Day route lacks a role guard): Reject. The route intentionally allows a member without a staff profile to see an explanatory empty state: `apps/back-office/src/features/my-day/routes.tsx:4-9` documents that behavior, and `apps/back-office/e2e/staff.spec.ts:105-110` tests it for a manager. Adding a non-staff redirect as proposed would contradict the tested UX. RLS remains the data boundary.
- F-FE-1 (gradient uses `to right`): Reject. The auditor identifies no layout property violation or user-visible defect, and proposes no change. This is not an unmet Phase 2 requirement.
- F-FE-2 (`rect.left`/`rect.right` DOM coordinates): Reject. The cited code explicitly branches on direction and computes from the appropriate side (`frontend.md:253-259`); these are screen-coordinate values, not physical CSS declarations. No RTL failure is evidenced.
- F-FE-3 (`left` variable name): Reject as a naming suggestion only. No incorrect behavior or plan/convention violation is identified.

## Own sweep

The repository's current code and tests were spot-checked across staff upsert/invite, shift copy and branch scope, blocked-time RPC conflict handling, schedule output, and My Day. The database auditor reports 14/14 security attacks passing and 536 total pgTAP tests passing; gates also pass the full CI-style, Deno, unit, and bilingual Playwright suites. No additional cross-tenant or cross-branch leak, privilege escalation, direct-write bypass, double-booking path, missing Phase 2 subphase, or failing/skipped gate was identified in the reviewed evidence. All Phase 2 checklist categories appear in the conformance report; the frontend audit supplies the separate i18n/RTL evidence. No Phase 2-specific cloud-only acceptance criterion was identified. Future Phase 5/16 work is outside this phase and is not counted as a failure.

## Counts and ordered fixes

| Severity | Count |
|---|---:|
| Blocker | 0 |
| Major | 0 |
| Minor | 3 |

Ordered fix list (minors only; PASS remains the verdict):
1. F-BE-1 — `supabase/functions/staff/staff_test.ts`: add the interrupted-invite recovery test and document the retry path.
2. F-DB-2 — add a new migration that updates `update_blocked_time` with active staff/branch/type validation; add pgTAP update cases.
3. F-CON-2 — `supabase/functions/staff/shifts_test.ts`: test omitted versus empty `staff_ids` through the served function; verify explicit null is rejected if included.
