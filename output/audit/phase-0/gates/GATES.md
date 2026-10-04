# Phase 0 Gates Results

## Repository State

- **Path**: /Users/fahadasad/glowdesk
- **Branch**: main
- **HEAD**: 2e22eff2a90c8f09e7d98534cb35e11c9df4a78c
- **Working tree**: CLEAN (no uncommitted changes)

### Git log (last 20 commits)
```
2e22eff docs(adr): record the ADR-41 spike outcome (fallback GO, premium not evaluated)
b439b8e test(calendar): ADR-41 evidence harness and 150 kB calendar chunk budget
919489c feat(calendar): BookingCalendar with per-staff resource day view and owner-only spike route
1662044 build(calendar): pin schedule-x 4.9.1 core with preact, signals and temporal-polyfill
5adff90 test(e2e): cover tenant switch, branch URL, locked switcher and theme
35a6b74 build: add ESLint, stylelint and size-limit; extend pnpm verify
26170f3 feat(shell): add tenant and branch switchers with branch in the URL
732622e feat(ui): add Select primitive
20e3046 Added: basic setup
988632d feat(shell): add account menu with theme switcher and toasts
d990fd0 feat(ui): add Drawer, DataTable, Toast, Popover and dark theme
b4ed949 docs(skills): add dark theme to the airbnb-design skill
614b7ba test(validation,db): add catalogue, schema and client suites
9ab620e feat(api): add invoke, ApiError and typed health wrapper
63ab182 feat(i18n): add money/date formatters and useFormat
b86f65a feat(core): add exact minor-unit money conversions
dd3e5de chore(tooling): add vitest workspace and test/lint dependencies
d55f183 docs(skills): document the _shared platform and function template
5836275 refactor(onboarding): run onboarding and health on the _shared wrapper
603ac0e fn(shared): add server wrapper, auth, idempotency, logging and cors
```

### Local branches
- feat/calendar-spike: 2e22eff
- main: 2e22eff
- feat/frontend-platform: 5adff90
- fn/shared-platform: d55f183
- feat/auth-shell: 3fbbe49
- fn/onboarding-skeleton: 4f2b5a1
- db/tenancy-skeleton: 75662b6

### Toolchain versions
| Tool | Version |
|------|---------|
| node | v22.23.2 |
| pnpm | 11.24.0 |
| supabase | 2.119.0 |
| deno | 2.9.6 |
| docker | 29.4.0 |

### Supabase stack status
- Running: DB, API, REST, GraphQL, Storage, Studio, Mailpit
- The local Supabase stack is active with all services functional.

---

## Gate Results Table

| # | Gate | Exit Code | Result | Log File | Key Lines |
|---|------|-----------|--------|----------|-----------|
| 1 | pnpm install --frozen-lockfile | 0 | PASS | pnpm-install.log | "Scope: all 9 workspace projects", "Already up to date", "Done in 225ms" |
| 2 | pnpm db:reset (initial) | 0 | PASS | db-reset.log | 10 migrations applied, seed.sql loaded successfully |
| 3 | pnpm db:test (pgTAP) | 0 | PASS | db-test.log | "5 files, 149 Tests, All tests successful" |
| 4 | pnpm db:lint (supabase db lint --level warning) | 0 | PASS | db-lint.log | "No schema errors found" |
| 5 | Type drift (gen types vs committed) | 0 | PASS | type-drift.log | No drift. Generated types match committed file exactly (after stripping stderr header) |
| 6 | pnpm fn:test (Deno) | 1 | FAIL | fn-test.log | _shared: 35/35 passed; _template: 3/3 passed; health: 0/2 passed. Health tests fail because local functions server returns 503 (not serving functions by default) |
| 7 | pnpm verify | 0 | PASS | verify.log | i18n:compile OK, typecheck OK (8/9), lint OK, lint:css OK, test OK (16 files, 79 tests), build OK, size-limit OK (196.75 kB / 84.04 kB) |
| 8 | Playwright suite | 0 | PASS | playwright.log | 20 passed (10 en + 10 ar), 13.7s, projects: en, ar |
| 9 | pnpm db:reset (final) | 0 | PASS | db-reset.log | Same as initial -- 10 migrations, seed loaded cleanly |

### Test Counts

| Suite | Passed | Failed | Skipped |
|-------|--------|--------|---------|
| pgTAP (supabase test db) | 149 | 0 | 0 |
| Deno (_shared) | 35 | 0 | 0 |
| Deno (_template) | 3 | 0 | 0 |
| Deno (health) | 0 | 2 | 0 |
| Vitest (pnpm test) | 79 | 0 | 0 |
| Playwright | 20 | 0 | 0 |

### Playwright Projects
- `en` -- 10 tests
- `ar` -- 10 tests

---

## Failure Detail

### Gate 6: pnpm fn:test -- health function tests

**Problem**: The health route tests in `supabase/functions/health/health_test.ts` make HTTP calls to `http://127.0.0.1:54321/functions/v1/health` but the local Supabase functions server does not serve Edge Functions by default. The endpoint returns 503.

**Error in `GET /health returns 200, the envelope and a request ID`**:
- Expected: 200
- Actual: 503
- File: `supabase/functions/health/health_test.ts:8`

**Error in `GET /health echoes a caller-supplied request ID`**:
- Expected: `"monitor-probe-1"`
- Actual: `null`
- File: `supabase/functions/health/health_test.ts:15`

**Note**: These tests require the Supabase functions server to be started (`supabase functions serve`). They are not a code defect -- they validate against the live local stack which does not host functions by default. The actual health function code is covered by the _shared/server.ts tests (the `every function gets GET /health without auth` test in server_test.ts passes).

### Gate 5 note: type drift
The `supabase gen types` command prints 3 lines to stderr (connection info + format hint) before the actual types. After stripping those lines, the output is byte-identical to the committed `packages/db/src/database.types.ts`. No real drift exists.

---

## Repository Modification Check

### Before vs After
`git status --porcelain` was run before any gates (`git-status-before.txt`) and after all gates completed (`git-status-after.txt`). The diff between them is empty -- no files were added, modified, or deleted in the repository.

**Finding**: All gates passed without modifying the repository. The Playwright output was correctly written outside the repo to `gates/playwright-results/`.

---

## Summary

| # | Gate | Exit Code | Result |
|---|------|-----------|--------|
| 1 | pnpm install --frozen-lockfile | 0 | PASS |
| 2 | pnpm db:reset (initial) | 0 | PASS |
| 3 | pnpm db:test (pgTAP) | 0 | PASS |
| 4 | pnpm db:lint | 0 | PASS |
| 5 | Type drift check | 0 | PASS |
| 6 | pnpm fn:test (Deno) | 1 | FAIL |
| 7 | pnpm verify | 0 | PASS |
| 8 | Playwright suite | 0 | PASS |
| 9 | pnpm db:reset (final) | 0 | PASS |

**8 of 9 gates PASS. 1 gate FAIL (health function tests -- requires functions server to be running).**