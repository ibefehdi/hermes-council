# Phase 3 Gates Report

## Repository state

| Field | Value |
|---|---|
| Repository path | /Users/fahadasad/glowdesk |
| Current branch | main |
| HEAD commit | bfb3a3957893f55a87bb60d660a1ac5f9b65c6b0 |
| Subject | chore(back-office): add Vercel config with SPA fallback rewrite |
| Working tree | CLEAN (no uncommitted changes) |

### Git log (last 20 commits)

```
bfb3a39 chore(back-office): add Vercel config with SPA fallback rewrite
bfde257 docs(evidence): record Phase 3 gate run on be599a9
be599a9 test(evidence): build raw function URLs through a helper to satisfy the ADR-30 lint rule
d6af910 test(evidence): demonstrate Phase 3 exit criteria
ae298ca test(catalogue): add Arabic catalog, mapper and permission tests, and the catalogue journey
1ff039e feat(catalogue): add catalogue hub, service editor and category drawer
740b3ac feat(ui): add Tabs primitive with RTL-aware keyboard navigation
cc94f0a feat(api): add catalogue upsertService and reorder wrappers
74d6ea1 fn(catalogue): add upsert-service and reorder with contract and acceptance tests
d4f2866 feat(validation): add catalogue schemas for services, overrides, categories and reorder
e3cffe3 db(catalogue): add upsert_service and reorder_catalogue RPCs with pgTAP
26f0109 db(catalogue): use RFC 4122 variant ids for the seeded catalogue
8bfa6c2 docs(skills): add staff eligibility term and service_categories to the allowlist
01fc01f db(catalogue): seed the SpaCorner catalogue and regenerate types
787d3aa feat(core): add effective-service resolver and round-robin picker
308ca48 test(db): cover the catalogue RLS matrix and resolution
4131919 db(catalogue): add resolve_service and effective-values views
89c2763 db(catalogue): add service_branch_overrides and service_staff
4b120dd db(catalogue): add service_categories and services with RLS and audit
474cff9 docs(evidence): record Phase 1 gate run on 710eeda
```

### Local branches (with tip commits)

| Branch | Tip | Subject |
|---|---|---|
| db/blocked-times | b714dd0 | db(blocked-time): add blocked_times with locked RPCs and early appointment tables |
| db/catalogue | 26f0109 | db(catalogue): use RFC 4122 variant ids for the seeded catalogue |
| db/provisioning-schema | bcc2819 | feat(db): add branch hours, closed periods, invoice counters and plans |
| db/settings-catalogues | 5d4b5c7 | feat(db): settings hub RPCs, owner-only tenant settings, archived scope |
| db/shifts | 8f80106 | db(shifts): add shifts with manager-gated writes, copy_shift_week and branch_staff_schedule |
| db/staff-records | 922864e | db(staff): add staff_members, branch assignments and staff RPCs |
| db/tenancy-skeleton | 75662b6 | docs(skills): align supabase-database templates with migrations |
| feat/auth-shell | 3fbbe49 | test(e2e): add login-shell-language-logout smoke |
| feat/blocked-time | aecbb59 | feat(blocked-time): add blocked-time list and drawer via locked RPCs, and own blocks on My day |
| feat/calendar-spike | 2e22eff | docs(adr): record the ADR-41 spike outcome (fallback GO, premium not evaluated) |
| feat/catalogue-ui | ae298ca | test(catalogue): add Arabic catalog, mapper and permission tests, and the catalogue journey |
| feat/frontend-platform | 5adff90 | test(e2e): cover tenant switch, branch URL, locked switcher and theme |
| feat/members-roles | 916121f | test(evidence): demonstrate Phase 1 exit criteria |
| feat/phase-2-evidence | edfad11 | test(evidence): demonstrate Phase 2 exit criteria |
| feat/phase-3-evidence | bfde257 | docs(evidence): record Phase 3 gate run on be599a9 |
| feat/settings-hub | 134f389 | feat(settings): settings hub, branch editor, hours editor and setup checklist |
| feat/shift-grid | 4b175f4 | feat(shifts): add weekly shift grid with drawer, drag-to-draw, copy previous week and my-day shifts |
| feat/staff-records | ff3899a | feat(staff): add staff list, editor and my-day screens |
| fix/phase-0-audit | 1051043 | test(db): prove branches accept valid IANA time zones |
| fix/phase-1-audit | 710eeda | test(e2e): run against a non-watching dev server and assert sign-in field values |
| fn/catalogue | cc94f0a | feat(api): add catalogue upsertService and reorder wrappers |
| fn/onboarding-provisioning | d9a9463 | feat(onboarding): idempotent tenant provisioning and provision-branch |
| fn/onboarding-skeleton | 4f2b5a1 | fn(onboarding): add platform-admin provisioning skeleton |
| fn/shared-platform | d55f183 | docs(skills): document the _shared platform and function template |
| fn/shifts-materialize | 66ee5e1 | fn(staff): add shifts-materialize week copy |
| fn/staff-records | b33ae93 | fn(staff): add staff function with upsert and invite-login |
| main | bfb3a39 | chore(back-office): add Vercel config with SPA fallback rewrite |

## Toolchain versions

| Tool | Version |
|---|---|
| node | v22.23.2 |
| pnpm | 11.24.0 |
| supabase | 2.119.0 |
| deno | 2.9.6 |
| docker | 29.4.0 |

## Supabase stack

Stack started successfully. Linked project: TryGlowDesk (tphohlcobpzprqmobyox).

## Gates table

| # | Gate | Command | Exit code | Result | Log file | Key lines |
|---|---|---|---|---|---|---|
| 1 | Frozen lockfile install | `pnpm install --frozen-lockfile` | 0 | PASS | gates/install.log | "Already up to date / Done in 245ms" |
| 2 | DB reset (initial) | `pnpm db:reset` | 0 | PASS | gates/db-reset.log | "Finished supabase db reset on branch main." — 33 migrations applied, seed loaded |
| 3 | DB test (pgTAP) | `pnpm db:test` | 0 | PASS | gates/db-test.log | "All tests successful. Files=15, Tests=684" |
| 4 | DB lint | `pnpm db:lint --level warning` | 0 | PASS | gates/db-lint.log | "No schema errors found" |
| 5 | Type drift | `supabase gen types typescript --local` diff committed types | 0 | PASS (no drift) | gates/database.types.generated.ts | `diff` exit code 0 — generated and committed types are identical (ignoring whitespace) |
| 6 | Edge Function tests | `pnpm fn:test` (bash scripts/fn-test.sh) | 0 | PASS | gates/fn-test.log | "Deno suites: 6 passed, 0 failed" |
| 7 | pnpm verify | `pnpm verify` | 0 | PASS | gates/verify.log | All sub-steps PASS: skills:check ✓, i18n:compile ✓, typecheck (8 packages) ✓, lint ✓, lint:css ✓, vitest 224/224 ✓, build ✓, size-limit ✓ |
| 8 | Playwright E2E | `pnpm exec playwright test --output gates/playwright-results --reporter=list` | 0 | PASS | gates/playwright.log | "50 passed (40.1s)" — 25 en + 25 ar |
| 9 | DB reset (final) | `pnpm db:reset` | 0 | PASS | gates/db-reset-final.log | "Finished supabase db reset on branch main." — clean seeded state for downstream members |

### Gate details

**Gate 1: Frozen lockfile install**
Already up to date. Lockfile integrity confirmed.

**Gate 2: DB reset (initial)**
33 migrations applied in order, from 20261004170000_enable_extensions to 20261007110000_catalogue_rpcs. Seed data loaded successfully. All containers restarted.

**Gate 3: DB test (pgTAP)**
15 test files, 684 tests total, all PASS. Catalogue-specific tests:
- 012_catalogue_matrix.test.sql — RLS matrix for catalogue tables
- 013_catalogue_resolution.test.sql — effective-values resolution
- 014_catalogue_rpcs.test.sql — upsert_service and reorder_catalogue RPCs

**Gate 4: DB lint**
No schema errors found across extensions, public, and tests schemas. Lint level: warning.

**Gate 5: Type drift**
Generated types match committed `packages/db/src/database.types.ts` exactly. No drift detected.

**Gate 6: Edge Function tests**
6 suites, all PASS:
- _shared: 39/39 passed (auth, idempotency, logging, server wrapper)
- _template: 3/3 passed (401, health, echo)
- catalogue: 8/8 passed (health, upsert-service with overrides/eligibility, branch scope denial, reorder)
- health: 2/2 passed (health endpoint)
- onboarding: 30/30 passed (provision-tenant, provision-branch, members/invite, concurrency)
- staff: 20/20 passed (blocked-time, shifts-materialize, staff upsert, invite-login)

**Gate 7: pnpm verify**
All sub-steps passed:
- skills:check — skills directories in sync
- i18n:compile — message catalogs compiled
- typecheck — 8 packages typechecked without errors
- lint — ESLint passed
- lint:css — stylelint passed
- test (Vitest) — 29 test files, 224 tests, all passed
- build — vite build succeeded (back-office SPA)
- size-limit — initial JS 220.44 kB (limit 250 kB), calendar chunk 61.96 kB (limit 150 kB)

**Gate 8: Playwright E2E**
50 tests, all PASS:
- 25 tests in [en] (Desktop Chrome, LTR)
- 25 tests in [ar] (Desktop Chrome, RTL)
- Specs covered: catalogue, smoke, staff, shifts, blocked-time, members, settings, scope, theme, password-reset
- Duration: 40.1s
- Catalogue-specific test: `the owner builds the menu; one branch opts out; the manager changes only their branch; reception reads` — passed in both locales

**Gate 9: DB reset (final)**
Clean, seeded database ready for downstream council members.

## Test counts summary

| Test suite | Passed | Failed | Skipped | Notes |
|---|---|---|---|---|
| pgTAP | 684 | 0 | 0 | 15 test files, all PASS |
| Deno (Edge Functions) | 102 | 0 | 0 | 6 suites: _shared(39) + _template(3) + catalogue(8) + health(2) + onboarding(30) + staff(20) |
| Vitest (unit) | 224 | 0 | 0 | 29 test files, all PASS |
| Playwright (E2E) | 50 | 0 | 0 | 2 projects: en(25) + ar(25) |

## Repository modification check

Git status before and after is identical (empty porcelain output). No files were modified by the gates.

## Findings

No findings — all gates PASS. The repository is clean, all tests pass, type drift is absent, and the final db:reset left a seeded database for the other council members.