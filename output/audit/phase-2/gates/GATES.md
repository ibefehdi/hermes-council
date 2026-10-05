# Phase 2 Gates Report

## Repository state

- **Path**: `/Users/fahadasad/glowdesk`
- **Branch**: `main`
- **HEAD**: `edfad112962008246b818f9edf9c3c95591e05c2`
- **Commit message**: `test(evidence): demonstrate Phase 2 exit criteria`
- **Working tree**: CLEAN — no uncommitted changes at start or end (git-status-before.txt and git-status-after.txt both empty)

### Local branches

| Branch | Tip commit |
|---|---|
| `main` | `edfad11` test(evidence): demonstrate Phase 2 exit criteria |
| `feat/phase-2-evidence` | `edfad11` test(evidence): demonstrate Phase 2 exit criteria |
| `feat/blocked-time` | `aecbb59` feat(blocked-time): add blocked-time list and drawer via locked RPCs, and own blocks on My day |
| `db/blocked-times` | `b714dd0` db(blocked-time): add blocked_times with locked RPCs and early appointment tables |
| `feat/shift-grid` | `4b175f4` feat(shifts): add weekly shift grid with drawer, drag-to-draw, copy previous week and my-day shifts |
| `fn/shifts-materialize` | `66ee5e1` fn(staff): add shifts-materialize week copy |
| `db/shifts` | `8f80106` db(shifts): add shifts with manager-gated writes, copy_shift_week and branch_staff_schedule |
| `feat/staff-records` | `ff3899a` feat(staff): add staff list, editor and my-day screens |
| `fn/staff-records` | `b33ae93` fn(staff): add staff function with upsert and invite-login |
| `db/staff-records` | `922864e` db(staff): add staff_members, branch assignments and staff RPCs |
| (plus 11 earlier feature/db/fn branches) | |

`git log --oneline -20` saved in appendix below.

## Toolchain versions

| Tool | Version |
|---|---|
| node | v22.23.2 |
| pnpm | 11.24.0 |
| supabase | 2.119.0 |
| deno | 2.9.6 (stable) |
| docker | Docker version 29.4.0, build 9d7ad9f |

Supabase stack: started successfully from stopped state. All services running on standard local ports.

## Gates table

| # | Gate | Exit code | Result | Log file | Key lines |
|---|---|---|---|---|---|
| 1 | `pnpm install --frozen-lockfile` | 0 | PASS | `gates/pnpm-install.log` | "Already up to date" |
| 2 | `pnpm db:reset` | 0 | PASS | `gates/pnpm-db-reset.log` | 30 migrations applied, seed loaded |
| 3 | `pnpm db:test` (`supabase test db`) | 0 | PASS | `gates/pnpm-db-test.log` | "All tests successful. Files=12, Tests=536" |
| 4 | `pnpm db:lint` (`supabase db lint --level warning`) | 0 | PASS | `gates/pnpm-db-lint.log` | "No schema errors found" |
| 5 | Type drift check | 1* | PASS | `gates/type-drift.log` | Generated types match committed `packages/db/src/database.types.ts` (diff = 3 banner lines only) |
| 6 | `pnpm fn:test` | 0 | PASS | `gates/pnpm-fn-test.log` | 5 suites, 94 passed, 0 failed |
| 7 | `pnpm verify` | 0 | PASS | `gates/pnpm-verify.log` | skills:check, i18n:compile, typecheck (8 packages), lint, lint:css, test (177/177), build, size |
| 8 | Playwright E2E suite | 0 | PASS | `gates/playwright.log` | 48 passed (24 en + 24 ar) |
| — | `pnpm db:reset` (final clean) | 0 | PASS | (included in db-reset log) | All 30 migrations + seed applied cleanly |

\* Exit code 1 on diff is expected: the generated file has 3 informational banner lines that the committed file does not; the actual TypeScript is identical.

## Test counts

| Suite | Passed | Failed | Skipped |
|---|---|---|---|
| pgTAP (`supabase test db`) | 536 | 0 | 0 |
| Deno (Edge Functions, `fn:test`) | 94 | 0 | 0 |
| Vitest (unit tests, `pnpm test`) | 177 | 0 | 0 |
| Playwright (E2E) | 48 | 0 | 0 |

### Playwright projects

- `en` (Desktop Chrome, English locale): **24 tests passed**
- `ar` (Desktop Chrome, Arabic locale): **24 tests passed**

All 48 tests passed across all spec files: scope, password-reset, settings, blocked-time, members, shifts, smoke, staff, theme.

## pgTAP test files

| # | File | Result |
|---|---|---|
| 1 | `001_tenancy_schema.test.sql` | PASS |
| 2 | `002_tenancy_rls.test.sql` | PASS |
| 3 | `003_tenancy_matrix.test.sql` | PASS |
| 4 | `004_provisioning.test.sql` | PASS |
| 5 | `005_branch_config.test.sql` | PASS |
| 6 | `006_settings_matrix.test.sql` | PASS |
| 7 | `007_role_grants.test.sql` | PASS |
| 8 | `008_staff_matrix.test.sql` | PASS |
| 9 | `009_shifts_matrix.test.sql` | PASS |
| 10 | `010_blocked_times_matrix.test.sql` | PASS |
| 11 | `011_blocked_times_conflicts.test.sql` | PASS |

Phase 2 adds 4 new pgTAP test files (files 8-11: staff, shifts, blocked_times matrix + conflicts) on top of the Phase 1 foundation.

## Deno suites detail

| Suite | Tests | Passed | Failed |
|---|---|---|---|
| `_shared` | 39 | 39 | 0 |
| `_template` | 3 | 3 | 0 |
| `health` | 2 | 2 | 0 |
| `onboarding` | 30 | 30 | 0 |
| `staff` | 20 | 20 | 0 |

## Findings

**Repository integrity**: The working tree was clean before and after all gates. No generated files, lockfile changes, or artifacts were left in the repository. The Playwright test artifacts were written to the configured `--output` directory outside the repo (`gates/playwright-results/`).

**First-run fn:test issue**: The initial `pnpm fn:test` run had 3 suites failing (health, onboarding, staff) with 503 BOOT_ERROR because the functions runtime had not fully booted after `supabase start`. A `supabase stop && supabase start` resolved this, and all 94 Deno tests passed on second run. This is a known environmental quirk of the local Supabase CLI (also observed in Phase 1 gates).

---

## Appendix: `git log --oneline -20`

```
edfad11 test(evidence): demonstrate Phase 2 exit criteria
aecbb59 feat(blocked-time): add blocked-time list and drawer via locked RPCs, and own blocks on My day
b714dd0 db(blocked-time): add blocked_times with locked RPCs and early appointment tables
4b175f4 feat(shifts): add weekly shift grid with drawer, drag-to-draw, copy previous week and my-day shifts
66ee5e1 fn(staff): add shifts-materialize week copy
8f80106 db(shifts): add shifts with manager-gated writes, copy_shift_week and branch_staff_schedule
ff3899a feat(staff): add staff list, editor and my-day screens
b33ae93 fn(staff): add staff function with upsert and invite-login
922864e db(staff): add staff_members, branch assignments and staff RPCs
1051043 test(db): prove branches accept valid IANA time zones
02ef093 docs(skills): sync Claude skill copies and fail verify on drift
1800e3d test(fn): fail fast with a fix when the functions runtime is not serving
5476608 chore: run every Deno suite in fn:test before failing
3299b9a fn(onboarding): guard and report invite cleanup after failed provisioning
0fec7de feat(back-office): report crashes to Sentry with a lazy-loaded SDK
b5ce3b2 fn(_shared): report INTERNAL errors to Sentry behind captureException
916121f test(evidence): demonstrate Phase 1 exit criteria
a1b172d feat(members): members and roles with audited role grants and invite flow
134f389 feat(settings): settings hub, branch editor, hours editor and setup checklist
5d4b5c7 feat(db): settings hub RPCs, owner-only tenant settings, archived scope
```