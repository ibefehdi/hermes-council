# Phase 5 Gates Report

## Repository state at gate execution

| Attribute | Value |
|---|---|
| Path | /Users/fahad/GlowDesk |
| Branch | main |
| HEAD | ca1f1942297cd6c7c94ac24ff9356c4c4553f0d1 |
| Ahead of origin/main | 33 commits |

Working tree has uncommitted changes: **YES** (`.pnpm-store/` — untracked directory, present before and after gates; the audit covers the working tree as it is).

**Git log (last 20):**

```
ca1f194 Merge branch 'feat/phase-5-evidence'
b1aa468 Merge branch 'feat/calendar-realtime'
e774128 Merge branch 'feat/calendar-ui'
fddf426 Merge branch 'fn/bookings'
c5bed1b Merge branch 'db/bookings'
d3c2bad chore(bookings): add the Phase 5 gate run and council pack
a63f8dd test(bookings): cover the cross-branch conflict over HTTP
e551a4c docs(calendar): record Phase 5.4 review
80a19c8 test(calendar): add the Phase 5 booking journeys in en and ar
8a4421a chore(ci): add the busy-branch fixture and benchmarks
c44a0dd feat(search): add appointments to global search
a7ea889 feat(api): add useRealtime and channel-authorization tests
d319d37 db(bookings): publish appointments for realtime and forbid hard deletes
977e85b docs(calendar): record Phase 5.3 evidence and review
64f8e04 feat(clients): show appointment history and no-show count
438d06d feat(calendar): add drag and keyboard reschedule with override confirm
00acef0 feat(calendar): add the appointment drawer and status actions
fc69fd8 feat(calendar): add the new-booking drawer
2fe35bb feat(calendar): add day, week and my-day appointment views
777df3b feat(calendar): promote BookingCalendar to the product calendar
```

**Local branches:**

| Branch | Tip commit |
|---|---|
| db/bookings | ce17220 |
| db/clients | 6b43543 |
| feat/calendar-realtime | e551a4c |
| feat/calendar-ui | 977e85b |
| feat/ci-merge-gates | dcaf3ef |
| feat/clients-ui | af5d24b |
| feat/phase-4-evidence | 585316c |
| feat/phase-5-evidence | d3c2bad |
| fix/client-import-matcher-plan | 05c68bb |
| fn/bookings | 2a38c95 |
| fn/clients | 59dd896 |
| * main | ca1f194 |

**git-status-before**: saved to `gates/git-status-before.txt`. Only untracked `.pnpm-store/`.
**git-status-after**: saved to `gates/git-status-after.txt`. No changes from before — gates did not modify the repository.

## Toolchain

| Tool | Version |
|---|---|
| node | v26.10.0 |
| pnpm | 11.24.0 |
| supabase | 2.119.0 |
| deno | 2.9.6 |
| docker | 29.4.0 (OrbStack) |

**Supabase stack**: Started successfully. Services: DB (54322), API/Kong (54321), Studio (54323), Mailpit (54324). Edge Functions runtime is serving all functions.

## Gates

| # | Command | Exit code | Result | Log file | Key lines |
|---|---|---|---|---|---|
| 1 | `pnpm install --frozen-lockfile` | 0 | **PASS** | (inline) | "Already up to date" — 9 workspace projects |
| 2 | `pnpm db:reset` | 0 | **PASS** | (inline) | 48 migrations applied cleanly + seed.sql seeded. |
| 3 | `pnpm db:test` | 0 | **PASS** | (inline) | 1313 tests across 29 files — all successful. 6 wallclock secs. |
| 4 | `pnpm db:lint` | 0 | **PASS** | (inline) | "No schema errors found" |
| 5 | Type drift (`supabase gen types typescript --local`) | 0 | **PASS** | `gates/database.types.generated.ts` | Generated types differ only by supabase CLI banner lines ("Connecting to...", "Generated TypeScript is unformatted...", "A new version..."). No real type drift. |
| 6 | `pnpm fn:test` (Deno) | 0 | **PASS** (after supabase restart) | (inline) | All 8 suites pass: _shared 49, _template 3, bookings 61, catalogue 8, clients 16, health 2, onboarding 30, staff 20 = **189 passed, 0 failed** |
| 7 | `pnpm verify` | 0 | **PASS** | (inline) | skills:check ✓, i18n:compile ✓, typecheck ✓ (8 workspaces), eslint ✓, stylelint ✓, vitest ✓ (56 files, 447 tests, 0 failures, 100% coverage), vite build ✓, size-limit ✓ (initial JS 230.09 kB / 250 kB limit, calendar 81.46 kB / 150 kB limit) |
| 8 | Playwright suite | 1 | **FAIL** (8 failed, 84 passed) | `gates/playwright-results/` | 92 tests total, 84 passed, 8 failed. See failures below. |
| 9 | Performance benchmark: `scripts/perf/slots-bench.ts` | 0 | **PASS** | `gates/perf-slots-bench.log` | p50 31.5 ms, p95 36 ms, max 37.5 ms (budget 300 ms). 30 staff per call, 60 runs after warm-up. Busy-branch fixture seeded: 30 staff, 3 services, 60 clients, 200 appointments. |
| 10 | Final `pnpm db:reset` | 0 | **PASS** | (inline) | Clean reset for downstream consumers. |

### Playwright failure details

8 failures (2 en, 6 ar). All are `expect(locator).toBeVisible()` or `expect(page).not.toHaveURL()` timeouts — mostly i18n toast message availability or session timing issues in the Arabic locale.

| # | Test | Locale | Error summary |
|---|---|---|---|
| 1 | calendar-appointment: confirm then cancel | en | Toaster "Status changed to Confirmed." not visible within 5s |
| 2 | calendar-reschedule: drag to taken slot, conflict, undo | en | Move confirmation toast not visible within 5s |
| 3 | blocked-time: manager adds time off at all branches | ar | Invitation-sent toast not visible within 5s |
| 4 | calendar-appointment: no-show then reopen | ar | Status-change toast not visible within 5s |
| 5 | calendar-booking: walk-in with anyone available | ar | 17:00 slot radio not found in drawer |
| 6 | calendar-reschedule: drag to taken slot, conflict, undo | ar | Move confirmation toast not visible within 5s |
| 7 | calendar: book from empty time on grid | ar | Appointment-booked toast not visible within 5s |
| 8 | catalogue: owner builds menu; manager changes branch | ar | Landing on /login (session not established) |

### Test counts

| Suite | Passed | Failed | Skipped | Notes |
|---|---|---|---|---|
| pgTAP (`db:test`) | 1313 | 0 | 0 | 29 files; includes RLS, concurrency, booking matrix, slots parity, realtime channel auth |
| Deno (`fn:test`) | 189 | 0 | 0 | 8 suites; includes shared lib, bookings handlers/rejection/concurrency/slots/realtime, catalogue, clients, onboarding (provision/members), staff/blocked-time/shifts |
| Vitest (`pnpm test` via verify) | 447 | 0 | 0 | 56 files; 100% statement/branch/function/line coverage on 7 covered files |
| Playwright | 84 | 8 | 0 | 92 tests across projects `en` and `ar`; 6 ar failures (toast visibility, slot picker, session), 2 en failures (toast visibility) |

### Playwright projects
- `en` — Desktop Chrome, appLocale "en"
- `ar` — Desktop Chrome, appLocale "ar"

Both projects ran in the same session. Results written to `gates/playwright-results/`.