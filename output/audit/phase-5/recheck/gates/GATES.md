# Phase 5 Gates Report (re-check)

## Repository state at gate execution

| Attribute | Value |
|---|---|
| Path | /Users/fahad/GlowDesk |
| Branch | fix/phase-5-audit-e2e |
| HEAD | cd9e67753498d2d786b6a57e1745595f5fc3fa00 |
| Basis | e552ed4 (Merge pull request #5 from ibefehdi/feat/phase-5-bookings) — the original main merge-base |

Working tree has uncommitted changes: **YES** (`.pnpm-store/`, `.seed-pw` — both untracked directories/files, present before and after gates; the audit covers the working tree as it is).

**Git log (last 20):**

```
cd9e677 docs(evidence): record the Phase 5 audit re-run
8e7b15e test(calendar): assert durable state before transient toasts
45cec54 fix(calendar): keep the chosen time while the slot picker narrows to one person
9b2b80d test(e2e): retire leftover fixture staff before each run
e552ed4 Merge pull request #5 from ibefehdi/feat/phase-5-bookings
b7038ed chore(bookings): add the Phase 5 gate run and council pack
0de2e5f test(bookings): cover the cross-branch conflict over HTTP
ffd09a3 docs(calendar): record Phase 5.4 review
ec55cb5 test(calendar): add the Phase 5 booking journeys in en and ar
ed76a0e chore(ci): add the busy-branch fixture and benchmarks
af0a155 feat(search): add appointments to global search
e5b8392 feat(api): add useRealtime and channel-authorization tests
717b2ba db(bookings): publish appointments for realtime and forbid hard deletes
23d3238 docs(calendar): record Phase 5.3 evidence and review
514365d feat(clients): show appointment history and no-show count
d6955e5 feat(calendar): add drag and keyboard reschedule with override confirm
d0510fd feat(calendar): add the appointment drawer and status actions
f98fc74 feat(calendar): add the new-booking drawer
6109c42 feat(calendar): add day, week and my-day appointment views
d4dd59c feat(calendar): promote BookingCalendar to the product calendar
```

**Local branches:**

| Branch | Tip commit |
|---|---|
| backup/main-before-reauthor | d3c2bad |
| db/bookings | ce17220 |
| db/clients | 6b43543 |
| feat/calendar-realtime | e551a4c |
| feat/calendar-ui | 977e85b |
| feat/ci-merge-gates | dcaf3ef |
| feat/clients-ui | af5d24b |
| feat/phase-4-evidence | 585316c |
| feat/phase-5-evidence | d3c2bad |
| fix/client-import-matcher-plan | 05c68bb |
| * fix/phase-5-audit-e2e | cd9e677 |
| fn/bookings | 2a38c95 |
| fn/clients | 59dd896 |
| main | e552ed4 |

**git-status-before**: saved to `gates/git-status-before.txt`. Only untracked `.pnpm-store/` and `.seed-pw`.
**git-status-after**: saved to `gates/git-status-after.txt`. No changes from before — gates did not modify the repository.

## Toolchain

| Tool | Version |
|---|---|
| node | v26.10.0 |
| pnpm | 11.24.0 |
| supabase | 2.119.0 |
| deno | 2.9.6 (stable) |
| docker | 29.4.0 |

**Supabase stack**: Started successfully. Services: DB (54322), API/Kong (54321), Studio (54323), Mailpit (54324), Realtime, Edge Runtime, Storage, Auth, all running.

## Gates

| # | Command | Exit code | Result | Log file | Key lines |
|---|---|---|---|---|---|
| 1 | `pnpm install --frozen-lockfile` | 0 | **PASS** | (inline) | "Already up to date" — 9 workspace projects |
| 2 | `pnpm db:reset` | 0 | **PASS** | `gates/db-reset.log` | 45 migrations applied cleanly + seed.sql seeded |
| 3 | `pnpm db:test` | 0 | **PASS** | `gates/db-test.log` | 1313 tests across 29 files — all successful. 5 wallclock secs. |
| 4 | `pnpm db:lint` | 0 | **PASS** | `gates/db-lint.log` | "No schema errors found" |
| 5 | Type drift (`supabase gen types typescript --local`) | 0 / diff 1 | **PASS** | `gates/database.types.generated.ts` | Generated types differ only by CLI banner lines ("Connecting to...", "Generated TypeScript is unformatted...", "A new version..."). No real type drift. |
| 6 | `pnpm fn:test` (Deno) | 0 | **PASS** | `gates/fn-test.log` | 8 suites: _shared 49, _template 3, bookings 61, catalogue 8, clients 16, health 2, onboarding 30, staff 20 = **189 passed, 0 failed** |
| 7 | `pnpm verify` | 0 | **PASS** | `gates/verify.log` | skills:check ✓, i18n:compile ✓, typecheck ✓ (8 workspaces), eslint ✓, stylelint ✓, vitest ✓ (56 files, 449 tests, 0 failures, 100% coverage), vite build ✓, size-limit ✓ (initial JS 230.08 kB / 250 kB, calendar 81.62 kB / 150 kB) |
| 8 | Playwright suite | 1 | **FAIL** (2 failed, 90 passed) | `gates/playwright-results/` | 92 tests total, 90 passed, 2 failed. See failures below. |
| 9 | Performance benchmark: `scripts/perf/slots-bench.ts` | 0 | **PASS** | `gates/perf-slots-bench.log` | p50 34.2 ms, p95 40.4 ms, max 49.7 ms (budget 300 ms). 30 staff per call, 60 calls after warm-up. Busy-branch fixture seeded: 30 staff, 3 services, 60 clients, 200 appointments. |
| 10 | Final `pnpm db:reset` | 0 | **PASS** | `gates/final-db-reset.log` | Clean reset for downstream consumers. |

### Playwright failure details

2 failures, both in the `en` locale. The previous audit had 8 failures (2 en, 6 ar) — 6 Arabic failures have been resolved.

| # | Test | Locale | Error summary |
|---|---|---|---|
| 1 | owner sets up a branch end to end | en | `expect(locator).toBeChecked()` failed: checkbox "Ask for a tip at checkout" not found after page reload. The page may have loaded incompletely or the checkbox was toggled off during save. |
| 2 | an owner adds a staff member without a login at two branches, found in both lists and by Arabic search | en | Test timeout of 30000ms exceeded: `locator.fill` for the Email field in the sign-in dialog timed out. The login dialog did not render the email field within 30s, suggesting an authentication/session issue on this branch's staff page. |

### Test counts

| Suite | Passed | Failed | Skipped | Notes |
|---|---|---|---|---|
| pgTAP (`db:test`) | 1313 | 0 | 0 | 29 files; includes RLS, concurrency, booking matrix, slots parity, realtime channel auth |
| Deno (`fn:test`) | 189 | 0 | 0 | 8 suites; includes shared lib, bookings handlers/rejection/concurrency/slots/realtime, catalogue, clients, onboarding, staff |
| Vitest (`pnpm test` via verify) | 449 | 0 | 0 | 56 files; 100% statement/branch/function/line coverage on 7 covered files |
| Playwright | 90 | 2 | 0 | 92 tests across projects `en` and `ar`; 2 en failures (settings checkbox, staff login dialog) |

### Playwright projects
- `en` — Desktop Chrome, appLocale "en"
- `ar` — Desktop Chrome, appLocale "ar"

Both projects ran in the same session. Results written to `gates/playwright-results/`.