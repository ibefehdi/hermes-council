# Phase 5 re-check adjudication

## Verdict: FAIL (previous verdict: FAIL)

The re-check evidence is sufficient to adjudicate the fix branch, but the phase is still not acceptable: the required Playwright gate remains failed at 90/92, so blocker F-TEST-1 is only PARTIAL. The two remaining failures are the English settings-tip checkbox after reload and the English staff invite sign-in dialog (`recheck/gates/GATES.md:84,92-95`; corresponding error contexts under `recheck/gates/playwright-results/`). F-DB-1 and F-DB-2 also remain unfixed, though both are minor.

## Scope and evidence

The re-check report covers every previous accepted finding, the previously failed Playwright gate, and the criteria previously not rated DONE: F-TEST-1, F-VERIFIER-1, F-DB-1, F-DB-2, the accepted SQL slot-engine deviation group, F-DESIGN-1, EC-12, 5.3.17, 5.3.20, and the justified partial test-location item 5.2.10 (`recheck/recheck.md:27-29,67-70,81-82,100-101,118-120,128-129,138-188`). The fresh gate report records all ten gates, 9 passing and Playwright failing; both English and Arabic projects ran, and both remaining failures are English (`recheck/gates/GATES.md:73-86,88-108`).

The gate report identifies `cd9e67753498d2d786b6a57e1745595f5fc3fa00` as the tested HEAD and documents the pre/post gate status (`recheck/gates/GATES.md:7-12,58-59`). That commit resolves in the repository and its four-commit range from the audited commit is available. This adjudication is scoped to that tested fix branch. At verifier time, `/Users/fahad/GlowDesk` itself was checked out at `e552ed4618debb79d4d538ae655abb9db7d9d544` and had additional tracked/untracked working-tree changes (including `calendar-views.spec.ts`, `BookingCalendar` and time helpers). The gate snapshot does not certify those later live-checkout changes; do not describe `cd9e677` as the live HEAD at the time of this adjudication.

## Rulings on previous findings

| Item | Ruling | Evidence |
|---|---|---|
| F-TEST-1 — blocker, Playwright gate | PARTIAL; blocker remains | Gate improved from 84/92 to 90/92, but exit code is 1 with two failures and zero skipped (`recheck/gates/GATES.md:84,90-104`). The settings failure cannot find the tips checkbox after reload; the staff failure times out locating the email field (`settings-.../error-context.md:14-24,119-123`; `staff-.../error-context.md:14-23,75-85`). Neither failure may be discounted because it is in a Phase 4 screen: the accepted finding is the required full-suite gate. |
| F-VERIFIER-1 — major, exact-head gate evidence | FIXED for the tested fix branch | Fresh gate report names `cd9e677...` as HEAD and records the full ten-gate run (`recheck/gates/GATES.md:7-10,73-86`). Git resolves that commit. The gate is not a pass overall because Playwright still fails, already covered by F-TEST-1. |
| F-DB-1 — minor, redundant appointment-item FK | NOT FIXED | The fix-commit range changes no migrations. The old FK remains in `supabase/migrations/20261006120000_create_appointments.sql:64`; the branch-aware FK was added in `20261009100000_extend_appointments.sql:40-46` (previous audit ruling: `AUDIT_REPORT.md:177-182`; re-check: `recheck/recheck.md:81-96`). Add a new cleanup migration; do not edit an applied migration. |
| F-DB-2 — minor, inaccurate `busy_range` skill documentation | NOT FIXED | Neither skill copy changed in the fix range; `.cursor/skills/supabase-database/SKILL.md:148-160` still describes a generated column, while the migration maintains it through `set_appointment_item_busy_range` and `set_busy_range_appointment_items` (`20261006120000_create_appointments.sql:73-93`). Update both skill copies and keep them identical. |
| F-CONF-1 / F-CONF-2 / F-SLOT-1 — accepted SQL-engine deviation | Retain prior ruling; no corrective code change required | The migration's branch-RLS rationale and the SQL/Deno parity coverage remain unchanged as documented in the prior adjudication (`phase-5/adjudication.md:30`; `phase-5/AUDIT_REPORT.md:191-195`). The brief permits this justified deviation. |
| F-DESIGN-1 — library token name | Retain prior ruling; no corrective code change required | It remains a third-party schedule-x variable, not a directional CSS property (`phase-5/adjudication.md:31`; `phase-5/AUDIT_REPORT.md:197-201`). |

The prior rejected findings remain rejected: the fix range adds no SQL/RLS/grant changes that would reopen F-DB-3, F-layout-1, F-CONF-3, or F-SLOT-2, and the CSS token ruling is unchanged (`recheck/recheck.md:197-213`; previous rulings: `phase-5/adjudication.md:32-35`).

## Criteria and gates

- EC-12, full RTL: DONE. The plan criterion is specifically “full RTL calendar; drag works in RTL” (`plan/parts/11-delivery-plan.md:1065,1072`). All six previous Arabic Playwright failures are now passing; the only two reported remaining failures are English (`recheck/recheck.md:35-46,48-57`; `recheck/gates/GATES.md:90-95,106-108`). The re-checker's PARTIAL ruling incorrectly made EC-12 depend on the entire cross-locale suite being green; the global gate still independently fails under F-TEST-1.
- Subphase 5.3.17, walk-in booking: DONE. The formerly failing Arabic walk-in journey now passes in the fresh gate; the SlotPicker change keeps the chosen time available while the query narrows (`recheck/recheck.md:35-45,174-179`; `recheck/gates/GATES.md:90-95`).
- Subphase 5.3.20, Playwright journeys: PARTIAL. The required suite is still 90/92, not green (`recheck/recheck.md:181-186`; `recheck/gates/GATES.md:84,92-104`).
- Subphase 5.2.10, test location: remains PARTIAL by location, accepted under the documented SQL deviation with equivalent coverage (`phase-5/adjudication.md:30`; `phase-5/AUDIT_REPORT.md:116,148-149`).
- The remaining nine gates pass: install, database reset/tests/lint, type drift, Deno, verify, performance and final reset (`recheck/gates/GATES.md:77-86`).

## New finding and regression sweep

F-RC-1, the `expect(...).toPass()` wrapper around `scrollIntoViewIfNeeded` in `apps/back-office/e2e/calendar-reschedule.spec.ts` (commit `8e7b15e`), is accepted as a minor synchronization concern, not as a blocker. It retries a specific scroll operation when realtime redraw detaches a card, but the test still asserts the resulting appointment state and the visible confirmation. The prior reschedule failures were reported at the later toast assertion, after the drag had already run (`phase-5/gates/GATES.md:92-93`; `recheck/recheck.md:233-242`). There is no evidence that this retry caused the formerly failing assertions to pass, and it does not delete, skip, or weaken them. Keep the retry targeted; do not extend it or use it to substitute for an outcome assertion.

I reviewed the fix diff for database and test-scope regressions. The re-checker's range comparison shows no migration or skill-file edits and no SQL change; its E2E diff reorders toast checks after durable-state assertions, adds the SlotPicker/fixture fixes, and preserves the relevant expected-state assertions (`recheck/recheck.md:42-46,197-229`; gate report test totals at `recheck/gates/GATES.md:101-108`). No new tenant/branch-isolation or migration-integrity regression was found in the fix commits. The later uncommitted live-checkout changes are outside that tested commit range and are not certified here.

## Remaining work, in order

1. **F-TEST-1 — blocker:** fix the English settings tips persistence/rendering failure and the English staff invite/login-dialog email-field timeout; rerun the full English and Arabic Playwright suite with all assertions retained. The exact failures are in `recheck/gates/GATES.md:92-95` and the two error-context files named above.
2. **F-DB-1 — minor:** add a new migration dropping redundant `appointment_items_appointment_fk` after checking dependencies; do not edit existing migrations (`phase-5/AUDIT_REPORT.md:177-182`).
3. **F-DB-2 — minor:** update both `.cursor/skills/supabase-database/SKILL.md` and `.claude/skills/supabase-database/SKILL.md` to describe trigger-maintained `busy_range` as canonical (`phase-5/AUDIT_REPORT.md:184-189`).
4. **F-RC-1 — minor:** no mandatory change on current evidence; retain it as targeted synchronization only and keep the final state assertions (`recheck/recheck.md:233-242`).
