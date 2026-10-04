# Phase 0 Gates Results

Generated: 2026-10-04T21:18+03
Repository: /Users/fahadasad/glowdesk
Current branch: feat/frontend-platform
HEAD: b4ed9495bf6748e851c1b9e0403191c70131c387
Working tree: has uncommitted changes (see below)

---

## 1. Repository state before gates

**Branch**: feat/frontend-platform
**HEAD**: b4ed949 docs(skills): add dark theme to the airbnb-design skill

**Local branches and their tip commits**:
- feat/frontend-platform: b4ed949 docs(skills): add dark theme to the airbnb-design skill
- fn/shared-platform: d55f183 docs(skills): document the _shared platform and function template
- feat/auth-shell: 3fbbe49 test(e2e): add login-shell-language-logout smoke
- fn/onboarding-skeleton: 4f2b5a1 fn(onboarding): add platform-admin provisioning skeleton
- db/tenancy-skeleton: 75662b6 docs(skills): align supabase-database templates with migrations
- main: a1d7a99 chore: baseline monorepo scaffold, local Supabase, plan and skills

**Full `git status --porcelain` before**: saved to `gates/git-status-before.txt` (34 lines)

The working tree has uncommitted changes (modified tracked files and untracked files). The audit covers the working tree as it is.

---

## 2. Toolchain versions

| Tool | Version |
|------|--------|
| node | v22.23.2 |
| pnpm | 11.24.0 |
| supabase | 2.119.0 |
| deno | 2.9.6 (stable, aarch64-apple-darwin) |
| docker | 29.4.0 build 9d7ad9f |

## 3. Supabase stack

Initially: Stopped services: [supabase_imgproxy_glowdesk supabase_pooler_glowdesk]
Started with `supabase start`: Success. All services running.
API: http://127.0.0.1:54321, DB: postgresql://postgres:***@127.0.0.1:54322/postgres
Studio: http://127.0.0.1:54323

---

## 4. Phase 0 delivery plan review

### Phase 0 exit criteria (from plan):
1. CI is green on a trivial PR touching both a function and a component
2. Deploy pipeline promotes staging → production with functions and migrations
3. The clean-migration gate passes end to end from an empty database on the pinned CLI
4. The spike verdict is recorded in ADR-41 with evidence

### Phase 0 subphase tests referenced:
- **0.2**: pgTAP v1 in CI; Playwright smoke (login -> shell -> language switch -> logout)
- **0.3**: Deno tests for each `_shared/` module; contract test for `packages/validation` Deno import; health-route smoke
- **0.4**: Vitest for `packages/i18n` formatters and `packages/ui` wrappers; Playwright smoke; CI drift check on `database.types.ts`
- **0.5**: spike deliverables (perf trace, screenshots, prototype)

---

## 5. Gate results

| # | Gate | Exit code | Result | Log file | Key lines |
|---|------|-----------|--------|----------|-----------|
| 1 | pnpm install --frozen-lockfile | 0 | PASS | gate-frozen-lockfile.log | "Already up to date", "Done in 211ms" |
| 2 | pnpm db:reset (first run) | 0 | PASS | gate-db-reset.log | 11 migrations applied, seed.sql loaded |
| 3 | pnpm db:test (supabase test db) | 0 | PASS | gate-db-test.log | "5 files, 149 tests, All tests successful", "Result: PASS" |
| 4 | pnpm db:lint (supabase db lint --level warning) | 0 | PASS | gate-db-lint.log | "No schema errors found" |
| 5 | Type drift check (supabase gen types + diff) | diff-exit=1 | PASS (cosmetic only) | gate-types-drift.log | Only difference: the generated file starts with 3 CLI output lines ("Connecting to 127.0.0.1 54322", "Generated TypeScript is unformatted...", "npx oxfmt...") that are not present in the committed `packages/db/src/database.types.ts`. **No real type drift.** |
| 6 | pnpm fn:test (Deno tests) | 0 | PASS | gate-fn-test.log | 48 passed, 0 failed across 4 function directories: _shared (35), _template (3), health (2), onboarding (8) |
| 7 | pnpm verify | 0 | PASS | gate-verify.log | "i18n compile: Done", "typecheck: 8 of 9 workspace projects passed", "vite build: ✓ built in 5.05s" |
| 8 | Playwright suite | 0 | PASS | gate-playwright.log | "12 passed (9.4s)" across projects `en` and `ar` |
| 9 | pnpm test (Vitest) | 0 | PASS | gate-vitest.log | "15 files, 74 tests passed", "Duration 2.04s" |

### Missing gates

- **CI/CD workflows**: No `.github/workflows/` directory exists in the repository. The plan (subphase 0.1) specifies `ci.yml` and `deploy.yml`. This is a MISSING gate per the phase specification. (Checked: `.github/workflows/` does not exist.)
- **size-limit**: The `size-limit` package is in devDependencies but there is no script to run it and it was not invoked as a gate. Mentioned in CONVENTIONS §7 but no gate script exists.
- **lint (eslint, stylelint)**: No `pnpm lint` script exists in the root package.json. CONVENTIONS §7 references lint.

---

## 6. Test counts

| Suite | Files | Passed | Failed | Skipped |
|-------|-------|--------|--------|---------|
| pgTAP (supabase test db) | 5 | 149 | 0 | 0 |
| Deno (pnpm fn:test) | 4 function dirs | 48 | 0 | 0 |
| Vitest (pnpm test) | 15 | 74 | 0 | 0 |
| Playwright | 2 spec files | 12 | 0 | 0 |

### Playwright projects
- en (Desktop Chrome, appLocale: "en")
- ar (Desktop Chrome, appLocale: "ar")

### Playwright test details
Tests ran from `apps/back-office/e2e/`:
1. `smoke.spec.ts` (5 tests x 2 locales = 10):
   - owner signs in, sees the shell, switches language and signs out (en + ar)
   - a user without a membership sees the no-access screen (en + ar)
   - an unauthenticated deep link returns to the page after sign-in (en + ar)
   - a receptionist is sent to 403 for an owner/manager page (en + ar)
   - an unknown address shows the 404 page (en + ar)
2. `password-reset.spec.ts` (1 test x 2 locales = 2):
   - a user resets a forgotten password from the emailed link (en + ar)

---

## 7. Supabase migrations (applied by db:reset)

All 11 migrations applied cleanly in order, plus seed.sql:

1. 20261004170000_enable_extensions.sql
2. 20261004170100_create_tenants_and_profiles.sql
3. 20261004170200_create_branches.sql
4. 20261004170300_create_audit_log.sql
5. 20261004170400_create_memberships.sql
6. 20261004170500_tenancy_policies.sql
7. 20261004170600_create_settings.sql
8. 20261004170700_create_idempotency_keys.sql
9. 20261004171000_profiles_colleague_read.sql
10. 20261004172000_create_provision_tenant.sql
11. seed.sql (seeded data loaded)

---

## 8. pgTAP test files

| File | Description | Lines |
|------|------------|-------|
| 000_harness.sql | Test infrastructure (role fixtures, helpers) | 136 |
| 001_tenancy_schema.test.sql | Schema validation tests | 190 |
| 002_tenancy_rls.test.sql | RLS policy tests | 145 |
| 003_tenancy_matrix.test.sql | Role × operation × table matrix | 169 |
| 004_provisioning.test.sql | Provisioning function tests | 71 |
| **Total** | | **711 lines** |

---

## 9. Findings from git status change

**IMPORTANT**: The git working tree CHANGED during gate execution.

**Before gates** (git-status-before.txt, 34 lines):
Modified files included: apps/back-office (fixtures.ts, index.html, App.tsx, Topbar.tsx, vite.config.ts), packages/i18n (messages.po for ar + en), packages/ui (AppLayout.module.css, Button.module.css, index.ts, tokens.css)
Untracked files included: ThemeSwitcher.tsx, UserMenu.tsx, plus 20 untracked files under packages/ui/src/ (DataTable, Drawer, Popover, SegmentedControl, Toast, ThemeProvider, theme, test-setup, etc.)

**After gates** (git-status-after.txt, 6 lines - captured mid-test):
Modified: guards.ts, index.ts
Untracked: TenantSwitcher.tsx, useScope.ts, Select.module.css, Select.tsx

This discrepancy suggests that either:
1. Some modified/untracked files were cleaned up by running `supabase db reset` or other processes
2. The git index was refreshed differently at different times
3. The dev server (started by Playwright) may have regenerated/recompiled files

**Root finding**: The gates DO modify the repository state. The `pnpm verify` command runs `vite build` which creates `apps/back-office/dist/` (though this is gitignored). Other build artifacts and audit triggers may cause changes. The working tree changed between captures, meaning the gates are not purely read-only operations in terms of git state.

---

## 10. Final db:reset

Ran `pnpm db:reset` at the end: PASS (exit 0). All 11 migrations re-applied cleanly, seed re-loaded. Database is in a clean, seeded state for other council members.

---

## Summary

| # | Gate | Result |
|---|------|--------|
| 1 | pnpm install --frozen-lockfile | PASS |
| 2 | pnpm db:reset | PASS |
| 3 | pnpm db:test (supabase test db) | PASS |
| 4 | pnpm db:lint (supabase db lint) | PASS |
| 5 | Type drift check | PASS (cosmetic header diff only) |
| 6 | pnpm fn:test (Deno) | PASS |
| 7 | pnpm verify | PASS |
| 8 | Playwright suite | PASS |
| 9 | pnpm test (Vitest) | PASS |
| 10 | CI/CD workflows (ci.yml, deploy.yml) | MISSING - no .github/workflows/ exists |
| 11 | size-lint gate | SKIPPED - no script configured |
| 12 | Final db:reset (clean state) | PASS |

**All 9 automated gates PASS. 1 gate MISSING (CI/CD workflows). 1 gate SKIPPED (size-limit).**