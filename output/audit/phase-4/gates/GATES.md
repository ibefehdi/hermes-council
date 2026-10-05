# Phase 4 Gates Results

## Repository state

- **Path**: /Users/fahad/GlowDesk
- **Branch**: feat/ci-merge-gates
- **HEAD**: dcaf3ef3343688a39c7adabada2d89f23d80f83c
- **Working tree**: CLEAN (no uncommitted changes)
- **Before/after status**: unchanged — no files modified by gates (see git-status-before.txt, git-status-after.txt)

### Recent commits (top 20)
```
dcaf3ef test(platform): cover appointment visibility, guards, idempotency and settings for the merge gates
8552d4a chore(ci): add the merge-gate workflow and the main branch ruleset
9efb74b chore(back-office): redeploy with the GitHub noreply author email
07e2a10 chore(back-office): redeploy with the repository owner as commit author
585316c docs(evidence): record the Phase 4 gate run on 39062c4 and the exit evidence
39062c4 test(evidence): add the Phase 4 exit spec and gate script
8fbf790 test(clients): scope the superuser counts in pgTAP 017 and 018 to the fixture tenants
af5d24b docs(clients): record the Epic 4.3 deviations
25a8c8b test(clients): cover create, duplicates, search, block, delete, import and staff access end to end
5b3c1cd feat(clients): link Clients in the sidebar and add global client search to the topbar
b55d54a feat(clients): add the list, editor, duplicate warning, profile, notes, block and import screens
4ebeeb5 feat(clients): add the clients data layer, safety flags contract and messages
9ed307a feat(ui): add Dialog and FileDrop primitives
59dd896 test(clients): keep the import fixture byte-exact
ba0b164 docs(clients): record the pgmq job pattern and the Phase 4 deviations
4e8d005 test(clients): add Deno route tests and the 1,000-row import fixture
ae08679 fn(clients): add the clients Edge Function with duplicate check, block, delete, anonymize and CSV import
22bbfd9 fn(clients): add typed clients wrappers to the api package
54508ac fn(clients): add client and CSV import rules to the shared validation package
6f402b1 test(clients): add client import pgTAP
```

### Local branches
| Branch | Tip commit |
|---|---|
| db/clients | 6b43543 |
| * feat/ci-merge-gates | dcaf3ef |
| feat/clients-ui | af5d24b |
| feat/phase-4-evidence | 585316c |
| fn/clients | 59dd896 |
| main | 9efb74b |

## Toolchain

| Tool | Version |
|---|---|
| node | v26.10.0 |
| pnpm | 11.24.0 |
| supabase | 2.119.0 |
| deno | 2.9.6 |
| docker | 29.4.0 |

Supabase stack: running (all containers up except imgproxy and pooler, which are optional).

---

## Gate results

| # | Gate | Command | Exit code | Result | Log file | Key lines |
|---|---|---|---|---|---|---|
| 1 | Install frozen-lockfile | `pnpm install --frozen-lockfile` | 0 | PASS | pnpm-install-frozen.log | "Already up to date" |
| 2 | Database reset (clean migration + seed) | `pnpm db:reset` | 0 | PASS | pnpm-db-reset.log | "Finished supabase db reset" — all 37 migrations applied, seed loaded |
| 3 | pgTAP database tests | `pnpm db:test` | 0 | PASS | pnpm-db-test.log | "All tests successful. Files=23, Tests=1018" |
| 4 | Database lint | `pnpm db:lint` | 0 | PASS | pnpm-db-lint.log | "No schema errors found" |
| 5 | Type drift | `supabase gen types typescript --local` → diff | 0 | PASS | database.types.generated.ts | Actual type content is identical. Only diff is the header lines ("Connecting to 127.0.0.1", "Generated TypeScript is unformatted..."). No real drift. |
| 6 | Edge Function tests | `pnpm fn:test` | 0 | PASS | pnpm-fn-test.log | "Deno suites: 7 passed, 0 failed" |
| 7 | Verify pipeline | `pnpm verify` | 0 | PASS | pnpm-verify.log | "skills:check OK, i18n:compile OK, typecheck OK (6 packages), lint OK, lint:css OK, vitest (35 files, 288 passed), build OK, size-limit OK" |
| 8 | Playwright E2E | `pnpm exec playwright test` (from apps/back-office) | 0 | PASS | playwright-test.log | "60 passed (20.6s)" |
| 9 | Final db:reset (clean handoff) | `pnpm db:reset` | 0 | PASS | (stdout redirected to terminal) | All 37 migrations applied + seed loaded |

### Gate 8 detail — Playwright

- **Projects**: `en` (Desktop Chrome), `ar` (Desktop Chrome)
- **Tests**: 60 total (30 per locale)
- **Result**: 60 passed, 0 failed

Spec files exercised:
- clients.spec.ts (CRUD + block/delete, staff access denial, CSV import)
- smoke.spec.ts (sign-in flow, no-access, deep-link, 403, 404)
- scope.spec.ts (tenant switching, branch URL persistence, branch locking)
- members.spec.ts (invite + accept, demotion)
- settings.spec.ts (branch setup, receptionist denied, manager read-only)
- settings-additional.spec.ts (branch closures, cancellation reasons)
- staff.spec.ts (add staff, invite with login, receptionist read-only, My Day)
- shifts.spec.ts (draw shift, overnight, copy week, manager restrictions, My Day)
- blocked-time.spec.ts (block, overlap detection, manager time off, My Day)
- catalogue.spec.ts (menu build, branch opt-out, manager edit, reception read)
- theme.spec.ts (persist across reloads)
- password-reset.spec.ts (forgot password flow)

### Test counts summary

| Suite | Framework | Passed | Failed | Skipped |
|---|---|---|---|---|
| pgTAP (database) | pgTAP / supabase test db | 1018 | 0 | 0 |
| Deno (Edge Functions) | deno test | 128 | 0 | 0 |
| Vitest (unit) | vitest | 288 | 0 | 0 |
| Playwright (E2E) | playwright | 60 | 0 | 0 |

**Total tests across all suites: 1,494 passed, 0 failed**

---

## Findings

No files in the repository were modified by the gate run. The git status before and after is identical (empty — clean working tree). The initially stopped services (imgproxy, pooler) remain stopped; they are not required for the gate suite.

All gates passed. The repository is ready for the downstream audit members.

---

*Gates executed: 2026-10-05 12:40 UTC+03 by auditor profile on feat/ci-merge-gates@dcaf3ef*