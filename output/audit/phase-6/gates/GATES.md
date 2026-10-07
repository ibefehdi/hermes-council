# Phase 6 Gates Summary

## Repository State

- **Path**: /Users/fahad/GlowDesk
- **Branch**: feat/sales-register-ui
- **HEAD**: 925f516ce9cdce2610ef7c43baa77e2b660663e3
- **HEAD msg**: docs(evidence): 6.4-T6 sales and register evidence, review and build note
- **Working tree**: DIRTY (3 modified files, 2 untracked dirs)

### Uncommitted changes (pre-existing, not caused by gates)
- M apps/back-office/src/features/calendar/lib/time.ts
- M apps/back-office/src/features/calendar/mappers.ts
- M packages/i18n/src/format.ts
- ?? .pnpm-store/
- ?? .seed-pw

The working tree had these uncommitted changes before any gate ran. The audit covers the working tree as-is, including these local modifications.

### Local branches with tip commits
- backup/main-before-reauthor    d3c2bad chore(bookings): add the Phase 5 gate run and council pack
- db/bookings                    ce17220 docs(bookings): record Phase 5.1 deviations and pgTAP evidence
- db/checkout                    9b0855e docs(checkout): add 6.1 evidence and review
- db/clients                     6b43543 test(clients): cover revocation, second-receptionist notes, merged bookability
- feat/calendar-now-line         594475e feat(calendar): mark the current time on today's columns
- feat/calendar-realtime         e551a4c docs(calendar): record Phase 5.4 review
- feat/calendar-ui               977e85b docs(calendar): record Phase 5.3 evidence and review
- feat/checkout-ui               6bd52ee docs(checkout): add 6.3 evidence, review and build note (6.3-T6)
- feat/ci-merge-gates            dcaf3ef test(platform): cover appointment visibility, guards, idempotency and settings for the merge gates
- feat/clients-ui                af5d24b docs(clients): record the Epic 4.3 deviations
- feat/phase-4-evidence          585316c docs(evidence): record the Phase 4 gate run on 39062c4 and the exit evidence
- feat/phase-5-evidence          d3c2bad chore(bookings): add the Phase 5 gate run and council pack
- feat/phase-6-checkout          925f516 docs(evidence): 6.4-T6 sales and register evidence, review and build note
- feat/phase-6-evidence          925f516 docs(evidence): 6.4-T6 sales and register evidence, review and build note
- feat/sales-register-ui*        925f516 docs(evidence): 6.4-T6 sales and register evidence, review and build note
- fix/ci-pin-supabase-cli        4d54e51 fix(ci): pin the Supabase CLI with setup-cli's version input
- fix/client-import-matcher-plan 05c68bb fix(clients): keep the duplicate matcher on its indexes without fresh statistics
- fix/phase-5-audit-e2e          cd9e677 docs(evidence): record the Phase 5 audit re-run
- fn/bookings                    2a38c95 docs(bookings): record Phase 5.2 review
- fn/checkout                    7e37976 docs(checkout): add 6.2 evidence, review and build note
- fn/clients                     59dd896 test(clients): keep the import fixture byte-exact
- main                           a40218b Merge pull request #8 from ibefehdi/fix/ci-pin-supabase-cli

## Toolchain

| Tool | Version |
|---|---|
| node | v26.10.0 |
| pnpm | 11.24.0 |
| supabase | 2.119.0 |
| deno | 2.9.6 |
| docker | 29.4.0 |

Supabase stack: Running (DB, API, Studio, Functions). Services `imgproxy` and `pooler` were stopped (started when needed by `supabase start`).

## Results Table

| # | Gate | Command | Exit Code | Result | Log File | Key Lines |
|---|---|---|---|---|---|---|
| 1 | Frozen lockfile | pnpm install --frozen-lockfile | 0 | PASS | pnpm-install.log | "Already up to date" |
| 2 | Database reset | pnpm db:reset | 0 | PASS | db-reset.log | 49 migrations applied, seed loaded, all ok |
| 3 | pgTAP tests | pnpm db:test | 0 | PASS | db-test.log | 36 files, 1730 tests, all successful |
| 4 | Database lint | pnpm db:lint | 0 | PASS (warnings) | db-lint.log | Warnings in 4 functions (type casts, IMMUTABLE/STABLE, shadowed vars) — no errors |
| 5 | Type drift | supabase gen types + diff | 0 | PASS (no drift) | type-drift.log | Generated types identical to committed database.types.ts (only cosmetic header/footer lines differ) |
| 6 | Deno function tests | pnpm fn:test | 0 | PASS | fn-test.log | 9 suites, all passed (see suite breakdown below) |
| 7 | Full verify | pnpm verify | 0 | PASS | verify.log | skills:check PASS, i18n:compile PASS, typecheck PASS, lint PASS, lint:css PASS, test PASS (74 files/626 tests/100% coverage), build PASS, size-limit PASS (236.53 kB gzipped < 250 kB) |
| 8 | Playwright E2E | pnpm exec playwright test | 0 | PASS | playwright.log | 128 passed (64 en + 64 ar), 0 failed, 45.9s |
| 9 | Database reset (final) | pnpm db:reset | 0 | PASS | (final log inline) | 49 migrations applied, seed loaded — clean seeded DB for other members |

## Deno Function Test Suite Breakdown

| Suite | Passed | Failed | Key Results |
|---|---|---|---|
| _shared | 32 | 0 | Auth, idempotency, logging, route guards, envelope validation |
| _template | 3 | 0 | Health, session, scope |
| bookings | 62 | 0 | Create/reschedule/cancel/no-show, scope, blocked client, overrides, parallel races, idempotency, realtime channel auth, slot engine parity (DST, overnight, closed periods) |
| catalogue | 8 | 0 | Upsert-service transactional, scope denial, reorder |
| checkout | 46 | 0 | Full checkout journey, golden fixtures (G01-G20), tamper detection, refund/void role gating, register day cycle, idempotency replay, reconciliation, concurrency races |
| clients | 16 | 0 | Duplicate check, block role enforcement, soft delete, anonymize, import pipeline (dry-run, 1000 rows with 50 bad), duplicate policies |
| health | 2 | 0 | Health endpoint |
| onboarding | 30 | 0 | Provision-tenant/branch (idempotent), invite-user role grants, cleanup |
| staff | 20 | 0 | Staff upsert scope, invite-login, shift materialization (DST, overnight), blocked-time races |

Total: 9 Deno suites, 0 failures

## Playwright Test Counts

| Project | Passed | Failed | Skipped |
|---|---|---|---|
| en (Desktop Chrome) | 64 | 0 | 0 |
| ar (Desktop Chrome) | 64 | 0 | 0 |
| **Total** | **128** | **0** | **0** |

## Test Counts by Framework

| Framework | Passed | Failed | Skipped | Notes |
|---|---|---|---|---|
| pgTAP | 1730 | 0 | 0 | 36 files, 6 wallclock secs |
| Deno | 219 | 0 | 0 | 9 suites consolidated |
| Vitest | 626 | 0 | 0 | 74 files, 100% coverage |
| Playwright | 128 | 0 | 0 | 64 en + 64 ar |

## Git Status Integrity

git-status-before.txt and git-status-after.txt are identical. The gates did not modify the repository.

Pre-existing uncommitted changes (still present after all gates):
- M apps/back-office/src/features/calendar/lib/time.ts
- M apps/back-office/src/features/calendar/mappers.ts
- M packages/i18n/src/format.ts
- ?? .pnpm-store/
- ?? .seed-pw