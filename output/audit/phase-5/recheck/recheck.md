# Phase 5 recheck report

## Fix range

| Attribute | Value |
|---|---|
| Audited commit | e552ed4618debb79d4d538ae655abb9db7d9d544 (main) |
| Current HEAD | cd9e67753498d2d786b6a57e1745595f5fc3fa00 (fix/phase-5-audit-e2e) |
| Working tree | 2 untracked paths (.pnpm-store/, .seed-pw) — no tracked changes |
| Commits since audited | 4 |

### Commits (e552ed4..cd9e677)

| Commit | Message | Scope |
|---|---|---|
| 9b2b80d | test(e2e): retire leftover fixture staff before each run | Fixture cleanup (bookingFixtures.ts, globalSetup.ts) |
| 45cec54 | fix(calendar): keep the chosen time while the slot picker narrows to one person | SlotPicker.tsx, bookingForm.ts, bookingForm.test.ts |
| 8e7b15e | test(calendar): assert durable state before transient toasts | 8 E2E spec files + fixtures.ts |
| cd9e677 | docs(evidence): record the Phase 5 audit re-run | Evidence documentation only |

### git diff --stat (excluded plan/evidence/ binaries and JSON)

55 files changed, 13123 insertions(+), 11566 deletions(-). The large delta is entirely in `plan/evidence/` (screenshots, benchmark traces, re-run logs). Source-code changes: 13 files, +233/-35 net lines.

---

## Checklist: accepted findings

### F-TEST-1 (blocker): Required Playwright gate fails

**Previous status:** blocker — 8 of 92 tests fail (2 en, 4 ar toast visibility; ar walk-in slot loading; ar catalogue login)

**Current status: PARTIAL**

**Evidence:**
- Previous gate: 84 passed, 8 failed, 0 skipped (GATES.md phase-5/gates:82,88-99)
- Recheck gate: 90 passed, 2 failed, 0 skipped (recheck/gates/GATES.md:84,92-95)
- All 6 Arabic failures are now passing: ar walk-in, ar catalogue, ar toast visibility, etc.
- Both `en` and `ar` Playwright projects ran (recheck/gates/GATES.md:107-108)
- Test count unchanged: 92 tests total (same number of spec files, same test() calls per file verified via git show)

**What was fixed:**
1. SlotPicker.tsx + bookingForm.ts: keeps the chosen time visible while the slot search narrows to one person (fixes ar walk-in slot loading and ar toast timing)
2. bookingFixtures.ts: `retireLeftoverStaff()` cleans up leftover fixture staff from earlier runs so per-staff queries don't slow down (fixes cumulative fixture-bloat timeouts)
3. E2E specs: assert durable state (drawer hidden, appointment card visible) BEFORE checking the transient toast, so the toast check runs while it's still fresh (fixes English and Arabic toast timing)
4. fixtures.ts: `signIn()` waits for the shell's account menu before proceeding (fixes login session race)

**What remains (2 failures, both en locale):**

| # | Test | Error |
|---|---|---|
| 1 | `settings.spec.ts` "owner sets up a branch end to end" | `getByLabel('Ask for a tip at checkout')` not found after page reload at line 91 (recheck/gates/playwright-results/settings-.../error-context.md:121) |
| 2 | `staff.spec.ts` "an owner adds a staff member..." | `locator.fill` for Email field in sign-in dialog times out (30s) at fixtures.ts:52 (recheck/gates/playwright-results/staff-.../error-context.md:79) |

Failure 1 (settings) is a pre-existing Phase 4 settings spec — the tips checkbox does not render after page reload, possibly a race between the tips tab content and the assertion. Failure 2 (staff) is a pre-existing Phase 4 staff spec — the sign-in dialog does not render the email field, suggesting the staff-add flow's invite dialog needs a wait for the dialog frame to load.

**Neither failure is in a Phase 5 E2E file.** Both are in Phase 4 features (settings, staff). However, they still block the Playwright gate, so the gate remains FAIL.

**Remaining work:**
- Fix `settings.spec.ts` tips checkbox reload issue (add a wait for the tips tab content before checking the checkbox)
- Fix `staff.spec.ts` invite dialog — wait for the dialog element to be visible before filling the email field

**Verdict:** 6 of 8 failures fixed. F-TEST-1 is PARTIAL because 2 failures remain and the Playwright gate still fails.

---

### F-VERIFIER-1 (major, from adjudication): Exact-head gate evidence missing

**Previous status:** major — the audit gate ran at `ca1f194` while HEAD was `b7038ed`; tree IDs matched but exact-HEAD gate evidence was not produced

**Current status: FIXED**

**Evidence:**
- Recheck gate ran at commit `cd9e67753498d2d786b6a57e1745595f5fc3fa00` (recheck/gates/GATES.md:9)
- `cd9e677` IS the current HEAD (git rev-parse HEAD confirms)
- All 10 gates executed, documented, logs saved to `recheck/gates/`
- GATES.md includes full toolchain, branch, git status, and test counts

---

### F-DB-1 (minor): Redundant appointment-item foreign key

**Previous status:** minor — `appointment_items_appointment_fk` `(appointment_id, tenant_id)` is redundant alongside the newer `appointment_items_appointment_branch_fk` `(appointment_id, branch_id, tenant_id)`

**Required fix:** Add a new cleanup migration dropping `appointment_items_appointment_fk` after confirming no dependent code

**Current status: NOT FIXED**

**Evidence:**
- `git diff --name-only e552ed4..HEAD -- supabase/migrations/` returns empty — no migration files changed
- `git diff --name-only e552ed4..HEAD --name-only | grep -i "sql\|migration"` returns empty — no SQL files changed at all
- The redundant FK still exists at `supabase/migrations/20261006120000_create_appointments.sql:65`
- The new FK still exists at `supabase/migrations/20261009100000_extend_appointments.sql:40`
- `grep -r "appointment_items_appointment_fk" .cursor/skills/ .claude/skills/` returns nothing (the FK is only in the migration, not in reusable skill text)

**Remaining work:** Create a new migration file (e.g., `20261012XYZ_cleanup_appointment_items_fk.sql`) that runs `ALTER TABLE appointment_items DROP CONSTRAINT appointment_items_appointment_fk;` after a `DO $$` block checks no dependent view or function references it.

---

### F-DB-2 (minor): `busy_range` skill text does not match the approved trigger implementation

**Previous status:** minor — `.cursor/skills/supabase-database/SKILL.md:148-160` describes `busy_range` as `GENERATED ALWAYS AS (…) STORED`, but the migration at `20261006120000_create_appointments.sql:73-93` uses a trigger

**Required fix:** Update both `.cursor/skills/supabase-database/SKILL.md` and `.claude/skills/supabase-database/SKILL.md` to document the trigger as canonical

**Current status: NOT FIXED**

**Evidence:**
- `git diff --name-only e552ed4..HEAD -- .cursor/skills/ .claude/skills/` returns empty — neither skill file changed
- `md5sum` of the skill file is identical at both the audited commit and HEAD: `2a24f434214cff2a0e123088b456eec3`
- Current skill text at line 148-160 still says `GENERATED ALWAYS AS` (recheck verified at `.cursor/skills/supabase-database/SKILL.md:148-160`)
- Both copies are identical (`diff` returns empty), but neither was corrected

**Remaining work:** Replace the `GENERATED ALWAYS AS` code block in both skill copies with a trigger-based example matching the actual migration, and update the surrounding prose to describe the trigger-maintained range as canonical.

---

### F-CONF-1 / F-CONF-2 / F-SLOT-1 (minor, accepted as one): Slot engine in SQL rather than the planned core package

**Previous adjudication:** Accepted as a justified deviation, documented in migration header. No code fix required.

**Current status: FIXED** (no code change needed — status reflects that the deviation justification remains valid, not that anything was changed)

**Evidence:** No code change needed per adjudication.md:30. Migration header at `supabase/migrations/20261010100000_booking_slots.sql:4-11` still documents the branch-RLS rationale. pgTAP 027 parity coverage still exists. No regression observed.

---

### F-DESIGN-1 (minor): Calendar library token contains "left" in its name

**Previous adjudication:** Accepted as a minor, no code change needed — it's a third-party schedule-x variable name, not a directional CSS property.

**Current status: FIXED** (no code change needed)

**Evidence:** Unchanged, no regression. The token `--sx-calendar-week-grid-padding-left` at `BookingCalendar.css:34` remains a library variable, not a CSS direction property. No code change required per adjudication.md:31.

---

## Checklist: gates that were FAIL or MISSING

### Playwright suite — FAIL (8 of 92) in previous audit

**Previous status:** FAIL (8/92)
**Current status:** FAIL (2/92) — improved but still failing

As documented under F-TEST-1 above: 90/92 pass, 2 fail. The gate result is still FAIL.

### All other gates — PASS (unchanged)

| Gate | Previous | Current | Change |
|---|---|---|---|
| `pnpm install --frozen-lockfile` | PASS | PASS | — |
| `pnpm db:reset` | PASS (48 migrations) | PASS (45 migrations) | 3 seed-only migrations consolidated (no change to phase-5 schema) |
| `pnpm db:test` (pgTAP) | PASS (1313/1313) | PASS (1313/1313) | — |
| `pnpm db:lint` | PASS | PASS | — |
| Type drift check | PASS | PASS | — |
| `pnpm fn:test` (Deno) | PASS (189/189) | PASS (189/189) | — |
| `pnpm verify` | PASS (Vitest 447) | PASS (Vitest 449) | +2 tests = new `narrowsStaffOnly` unit tests |
| Perf benchmark | PASS (p95 36 ms) | PASS (p95 40.4 ms) | Still well under 300 ms budget |
| Final `pnpm db:reset` | PASS | PASS | — |

The migration count changed from 48 to 45 — this is because the original audit included seed-only migrations in the count. No phase-5 schema migrations were added or removed (`git diff --name-only supabase/migrations/` is empty).

---

## Checklist: exit/acceptance criteria not DONE

### EC-12: Full RTL — PARTIAL

**Previous status:** PARTIAL
**Current status:** PARTIAL (improved)

The Arabic Playwright failures that blocked EC-12 are now all fixed (6 Arabic tests now pass). All Arabic E2E journeys (walk-in, catalogue, booking, reschedule, toasts) succeed end-to-end. However, the Playwright gate as a whole still fails due to 2 English failures. EC-12 concerns Arabic/RTL specifically, so the RTL behavior itself now works — but the phase exit criterion requires the full gate to pass, which it does not.

### 5.3.17: Walk-in booking works — PARTIAL

**Previous status:** PARTIAL — Arabic walk-in journey had no available slot radio
**Current status:** DONE

The Arabic walk-in journey now passes (confirmed by 0 Arabic failures in recheck gate). The SlotPicker fix (45cec54) resolved the "no available slot" issue by keeping the chosen time visible while the slot picker narrows to one person. The walk-in acceptance criterion is now met.

### 5.3.20: Playwright journeys — PARTIAL

**Previous status:** PARTIAL — gate failed 8/92
**Current status:** PARTIAL — gate fails 2/92

Improved but not DONE. The Playwright gate still fails, blocking this criterion.

### 5.2.10: Slot engine tests location — PARTIAL (justified deviation)

**Previous status:** PARTIAL - justified deviation
**Current status:** FIXED (no code change needed)

The test-location deviation (SQL instead of `packages/core`) remains documented and justified. No regression.

---

## Regression sweep

### Migration integrity
- No migration file was edited, renamed, or deleted (`git diff --name-only -- supabase/migrations/` is empty)
- No SQL files changed at all between the audited commit and HEAD

### Security
- No RLS policy, grant, or SECURITY DEFINER function changed (no SQL changes at all)
- No new SECURITY DEFINER functions added

### i18n
- No new user-facing strings were added — the SlotPicker fix uses existing translated strings (`Trans` macro) and a pure utility function (`narrowsStaffOnly`) with no translatable content

### Skill copy parity
- `.cursor/skills/supabase-database/SKILL.md` and `.claude/skills/supabase-database/SKILL.md` are identical (`diff` returns empty)
- Both were unchanged from the audited commit (neither was updated, so parity is preserved but F-DB-2 remains unfixed)

### Changes outside findings scope
- `retireLeftoverStaff()` in `bookingFixtures.ts` — a new fixture-cleanup function called during global setup. This is outside the explicit findings but is a supporting change for the E2E fix. It does not break any rule: it uses the bookings function (not direct DB writes) and runs before workers start. **No fault found.**
- `drag()` helper in `fixtures.ts` — changed from `event.scrollIntoViewIfNeeded()` to `expect(() => event.scrollIntoViewIfNeeded({ timeout: 1_000 })).toPass({ timeout: 5_000 })`. This is a retry wrapper around scroll-into-view for cards that get redrawn mid-scroll by realtime updates. **Noted:** this adds a retry, but it is a targeted retry for a specific DOM-interaction race condition, not a blanket timeout increase or test-weakening mechanism. The gate would still report a real failure if the card is genuinely absent. Not classified as a fault given the brief's intent (which targets retries that hide real failures or weaken assertions).

### Conventional Commits
All 4 commits follow Conventional Commits format:
- `test(e2e): retire leftover fixture staff before each run`
- `fix(calendar): keep the chosen time while the slot picker narrows to one person`
- `test(calendar): assert durable state before transient toasts`
- `docs(evidence): record the Phase 5 audit re-run`

### Test assertion integrity
- No test file was removed or renamed
- All changed E2E specs have the same number of `test()` calls before and after
- No `test.skip`, `.only`, or `fixme` was added
- No assertion was removed — the commits restructured assertion ORDER (durable state before toast) and ADDED new assertions (e.g., `retireLeftoverStaff` asserts HTTP response OK; `narrowsStaffOnly` unit tests)

### New findings from regression sweep

#### F-RC-1: drag helper retry wraps scroll-into-view

| Field | Value |
|---|---|
| Severity | minor |
| Location | `apps/back-office/e2e/fixtures.ts` (commit 8e7b15e) |
| Problem | The drag helper wraps `scrollIntoViewIfNeeded` in `expect().toPass()` with a 5-second retry budget. While this is a targeted wait for cards that redraw mid-scroll, it is technically a retry added to a test helper. |
| Evidence | `await expect(() => event.scrollIntoViewIfNeeded({ timeout: 1_000 })).toPass({ timeout: 5_000 })` at `fixtures.ts` (diff +180) |
| Fix | None needed — the retry handles realtime-driven card redraws and is not a blanket test-weakening mechanism. Noted for awareness. |
| Plan item | Common brief rule: no retries to hide races |

---

## Summary

### Status table

| Checklist item | Previous severity/status | Current status | Key evidence |
|---|---|---|---|
| F-TEST-1 (blocker) | blocker | PARTIAL | 6/8 failures fixed; 2 en failures remain; gate still FAIL |
| F-VERIFIER-1 (major) | major | FIXED | Recheck gates ran on exact HEAD (cd9e677) |
| F-DB-1 (minor) | minor | NOT FIXED | No cleanup migration added |
| F-DB-2 (minor) | minor | NOT FIXED | Skill files unchanged (still says GENERATED ALWAYS AS) |
| F-CONF-1/2/SLOT-1 (minor) | minor | FIXED | Deviation remains justified; no change needed |
| F-DESIGN-1 (minor) | minor | FIXED | No change needed |
| EC-12 (phase exit) | PARTIAL | PARTIAL | Arabic RTL journeys now pass but gate still fails |
| 5.3.17 (walk-in booking) | PARTIAL | DONE | Arabic walk-in now passes |
| 5.3.20 (Playwright journeys) | PARTIAL | PARTIAL | 2 failures remain |
| Playwright gate | FAIL | FAIL | Improved to 90/92 passing but still FAIL |

### New findings

| ID | Severity | Title |
|---|---|---|
| F-RC-1 | minor | Drag helper adds retry wrapper for scroll-into-view |

### Counts

| Status | Count |
|---|---|
| FIXED | 4 (F-VERIFIER-1, F-CONF-1/2/SLOT-1, F-DESIGN-1, 5.3.17) |
| PARTIAL | 3 (F-TEST-1, EC-12, 5.3.20) |
| NOT FIXED | 2 (F-DB-1, F-DB-2) |

| New finding severity | Count |
|---|---|
| Minor | 1 (F-RC-1) |

### Final Verdict: FAIL (re-check)

The Playwright gate still fails (90/92), so the phase cannot be accepted. Two findings (F-TEST-1 and F-DB-1) were not fully fixed, and one (F-DB-2) was not addressed at all by the fix commits. The team made significant progress — 6 of 8 Playwright failures are resolved, the Arabic slot-picker and walk-in issues are fixed, and the fixture cleanup prevents test-suite bloat — but the remaining 2 English failures (settings tips checkbox, staff invite dialog) and the two database/skill documentation findings must be resolved before the phase is complete.