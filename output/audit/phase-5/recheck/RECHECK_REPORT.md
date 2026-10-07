# Phase 5 re-check report

## Verdict

Previous verdict: FAIL. Re-check verdict: FAIL, as decided by the verifier in `recheck/adjudication.md:3-5`.

The fixes resolved six of the eight Playwright failures, including all six Arabic failures, but the required browser gate still fails: 90 of 92 tests pass and two English tests fail. The settings test cannot find the saved tips checkbox after reload, and the staff test times out while looking for the sign-in form's Email field. Two minor accepted findings also remain unchanged: the redundant appointment-item foreign key and inaccurate `busy_range` skill documentation. Phase 5 is not ready for acceptance.

## What was re-checked

- Repository: `/Users/fahad/GlowDesk`.
- Previously audited branch and commit: `main`, `e552ed4618debb79d4d538ae655abb9db7d9d544` (previous audit, `AUDIT_REPORT.md:16-27`).
- Re-check gate branch and commit: `fix/phase-5-audit-e2e`, `cd9e67753498d2d786b6a57e1745595f5fc3fa00` (`recheck/gates/GATES.md:7-12`). The gate report records that commit as its HEAD and records all ten checks (`recheck/gates/GATES.md:73-86`).
- Fix commits after the audited commit:
  - `9b2b80d` — `test(e2e): retire leftover fixture staff before each run`.
  - `45cec54` — `fix(calendar): keep the chosen time while the slot picker narrows to one person`.
  - `8e7b15e` — `test(calendar): assert durable state before transient toasts`.
  - `cd9e677` — `docs(evidence): record the Phase 5 audit re-run`.
  These are listed in `recheck/recheck.md:12-19` and `recheck/gates/GATES.md:14-21`.
- At gate execution the working tree had untracked `.pnpm-store/` and `.seed-pw`, with no tracked changes recorded before or after the checks (`recheck/gates/GATES.md:12,58-59`).
- Scope note: when this report was prepared on 2026-10-07, the live checkout was instead on `feat/calendar-now-line` at `594475e976e0f59bc2ea10625c4bf6463d5a5b95`, with the same two untracked paths and no tracked changes (`git status --short --branch`, `git rev-parse HEAD`). That live checkout is not the `cd9e677` gate snapshot. This report's re-check verdict and gate results refer to the tested `cd9e677` fix branch; they do not certify the separate live checkout.

## Gates

The previous results below are from the original report's gate table (`AUDIT_REPORT.md:29-46`). Current results are from the re-check gate report (`recheck/gates/GATES.md:73-108`).

| Gate | Previous result | Re-check result | Key detail |
|---|---|---|---|
| `pnpm install --frozen-lockfile` | PASS | PASS | Nine workspace projects; already up to date (`GATES.md:77`). |
| `pnpm db:reset` | PASS | PASS | Current reset applied 45 migrations and seeded the database (`GATES.md:78`). The prior report counted 48 (`AUDIT_REPORT.md:36`); the re-check notes three seed-only migrations were consolidated and no Phase 5 schema migration changed (`recheck/recheck.md:149-161,199-202`). |
| `pnpm db:test` | PASS, 1,313/1,313 | PASS, 1,313/1,313 | 29 pgTAP files (`GATES.md:79,101`). |
| `pnpm db:lint` | PASS | PASS | No schema errors (`GATES.md:80`). |
| Type drift (`supabase gen types typescript --local`) | PASS | PASS | Only CLI banner differences; no type drift (`GATES.md:81`). |
| `pnpm fn:test` | PASS, 189/189 | PASS, 189/189 | Eight Deno suites, no failures (`GATES.md:82,102`). |
| `pnpm verify` | PASS; Vitest 447 tests | PASS; Vitest 449 tests | 56 files, zero failures; lint, typecheck, build, coverage, and size checks passed (`GATES.md:83,103`). |
| Playwright suite | FAIL, 84/92 passed, 8 failed | FAIL, 90/92 passed, 2 failed, 0 skipped | Both English and Arabic projects ran. Remaining English failures are the settings tips checkbox and staff Email-field lookup (`GATES.md:84,90-108`; error contexts listed below). |
| `scripts/perf/slots-bench.ts` | PASS; p95 36 ms | PASS; p95 40.4 ms | Current maximum was 49.7 ms against a 300 ms budget (`AUDIT_REPORT.md:43`; `GATES.md:85`). |
| Final `pnpm db:reset` | PASS | PASS | Clean reset completed for downstream consumers (`GATES.md:86`). |

The two remaining Playwright errors are specific: `settings.spec.ts` cannot find `getByLabel('Ask for a tip at checkout')` at its post-reload checked assertion (`recheck/gates/playwright-results/settings-owner-sets-up-a-branch-end-to-end-en/error-context.md:14-24,119-123`); `staff.spec.ts` times out waiting for `getByLabel('Email')` during `signIn()` (`recheck/gates/playwright-results/staff-an-owner-adds-a-staf-80e31--lists-and-by-Arabic-search-en/error-context.md:14-23,75-85`). The error evidence does not establish a more specific root cause.

## Previous findings

| Finding | Severity | Status now | Evidence |
|---|---|---|---|
| F-TEST-1 — required Playwright gate fails | Blocker | PARTIAL | Improved from 84/92 to 90/92, but the gate exits 1 with two English failures and no skips (`recheck/gates/GATES.md:84,90-104`). The settings and staff failures are detailed above. |
| F-VERIFIER-1 — exact-head gate evidence | Major | FIXED for the tested re-check snapshot | The gate report records `cd9e67753498d2d786b6a57e1745595f5fc3fa00` as the tested HEAD and documents all ten gate results (`recheck/gates/GATES.md:7-10,73-86`). This does not make the Playwright gate pass, and it does not certify the separate live checkout described above (`adjudication.md:11,18`). |
| F-DB-1 — redundant appointment-item foreign key | Minor | NOT FIXED | No migration changed in the fix range; the older FK remains in `supabase/migrations/20261006120000_create_appointments.sql:64`, alongside the branch-aware FK in `supabase/migrations/20261009100000_extend_appointments.sql:40-46` (`adjudication.md:19`; `recheck/recheck.md:81-96`). Add a new cleanup migration; do not edit an applied migration. |
| F-DB-2 — inaccurate `busy_range` skill documentation | Minor | NOT FIXED | Neither skill copy changed. `.cursor/skills/supabase-database/SKILL.md:148-160` still describes a generated column, while `supabase/migrations/20261006120000_create_appointments.sql:73-93` maintains the range with triggers (`adjudication.md:20`; `recheck/recheck.md:100-114`). Update both `.cursor` and `.claude` copies and keep them identical. |
| F-CONF-1 / F-CONF-2 / F-SLOT-1 — SQL slot-engine deviation | Minor | Prior justified ruling retained; no fix required | The branch-RLS rationale and SQL/Deno parity coverage remain in place; the deviation was accepted in the prior adjudication (`adjudication.md:21`; prior `adjudication.md:30`). |
| F-DESIGN-1 — schedule-x token name | Minor | Prior ruling retained; no fix required | `--sx-calendar-week-grid-padding-left` is a third-party library variable, not a directional CSS property (`adjudication.md:22`; prior `adjudication.md:31`). |

The original accepted SQL test-location item 5.2.10 remains a justified partial-by-location deviation; the equivalent behavior coverage is in pgTAP and Deno tests (`adjudication.md:31`).

## Criteria not previously rated DONE

| Criterion | Subphase | Status now | Evidence |
|---|---|---|---|
| EC-12 — full RTL calendar and drag behavior | Phase exit | DONE | All six previously failing Arabic Playwright cases now pass; both remaining failures are English (`adjudication.md:28`; `recheck/gates/GATES.md:90-108`). EC-12 is specifically the RTL behavior criterion; the overall Playwright gate independently remains failed under F-TEST-1. |
| 5.3.17 — walk-in booking | 5.3 | DONE | The Arabic walk-in journey now passes after the SlotPicker fix (`adjudication.md:29`; `recheck/gates/GATES.md:90-95`). |
| 5.3.20 — Playwright journeys | 5.3 | PARTIAL | The required full suite still has two failures, with 90 of 92 tests passing (`adjudication.md:30`; `recheck/gates/GATES.md:84,92-104`). |
| 5.2.10 — slot-engine test location | 5.2 | PARTIAL by location; justified | Tests are in SQL/Deno rather than `packages/core` following the accepted SQL-engine deviation; equivalent coverage remains (`adjudication.md:31`; prior `adjudication.md:30`). |

## New findings

### Minor

F-RC-1 — targeted retry around scrolling a calendar card (`apps/back-office/e2e/calendar-reschedule.spec.ts:69-72`, commit `8e7b15e`). The drag helper retries `scrollIntoViewIfNeeded` for up to five seconds because realtime refetches can redraw and detach a card. The durable appointment-state assertions remain in the test, and the previously failing assertions occurred later at toast checks; the verifier found no evidence that this retry hid those failures (`adjudication.md:36`; prior failure locations in `phase-5/gates/GATES.md:92-93`). No mandatory change is warranted on current evidence. Keep this retry limited to the scroll operation and retain the outcome assertions.

No new regression finding was rejected. The prior rejected findings remain rejected because the fix range introduced no relevant SQL/RLS/grant changes, and the previous ADR rulings are unchanged (`adjudication.md:24`). The regression review found no new tenant/branch-isolation or migration-integrity issue in the four fix commits (`adjudication.md:38`).

## Fix prompt

```text
Fix the remaining Phase 5 findings below in /Users/fahad/GlowDesk, in order.
Context: @plan/parts/11-delivery-plan.md @plan/decisions.md @plan/CONVENTIONS.md
Skills: /feature-delivery /spa-domain-glossary /spa-platform-architecture /react-frontend /i18n-rtl /supabase-database

1. F-TEST-1: Fix the English settings journey so the saved "Ask for a tip at checkout" checkbox is present and checked after reload. Fix the English staff journey so the expected sign-in form is available before the Email field is filled; diagnose the missing locator rather than masking it with a broad timeout. Keep all assertions and rerun the full English and Arabic Playwright projects.
2. F-DB-1: Add a new migration to drop the redundant appointment_items_appointment_fk after checking dependencies. Do not edit an applied migration.
3. F-DB-2: Correct both .cursor/skills/supabase-database/SKILL.md and .claude/skills/supabase-database/SKILL.md to describe trigger-maintained busy_range as canonical. Keep both copies identical.

Rules: never edit an applied migration; keep both skill copies identical; use Conventional Commits. Do not delete, skip, weaken or broadly retry tests to get a green gate. Done = every gate passes and each fixed acceptance criterion is demonstrated by a test.
```
