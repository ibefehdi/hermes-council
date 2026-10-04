# Phase 0 Audit Report

**Phase:** 0 — Foundation
**Repository:** /Users/fahadasad/glowdesk
**Auditor:** @auditor
**Date:** 2026-10-04

---

## Verdict: PHASE NOT COMPLETE

The implementation covers 4 of 5 subphases substantively, but a **blocker** (no CI/CD) and a **major** gap (no Sentry) mean the phase exit criteria cannot be satisfied. Without CI the team cannot ship changes with automated quality gates, and without Sentry they cannot observe errors in staging/production.

### Subphase progress

| Subphase | Result |
|----------|--------|
| 0.1 Repo & environments | **FAIL** — CI/CD and Sentry are MISSING |
| 0.2 Tenancy & security skeleton | **PASS** (minor gap: no "no access" test) |
| 0.3 Edge Function platform | **PASS** (major gap: no Sentry, no CI) |
| 0.4 Frontend platform | **PASS** (minor gap: no CI drift check) |
| 0.5 Calendar spike | **PASS** (deviation in ADR-41 documented and justified) |

### Exit criteria

| Criterion | Status |
|-----------|--------|
| CI green on trivial PR | **FAIL** — no CI pipeline exists |
| Deploy pipeline staging→production | **FAIL** — no deploy pipeline exists |
| Clean-migration gate from empty DB on pinned CLI | **PARTIAL** — works locally but not automated |
| Spike verdict in ADR-41 with evidence | **PASS** |

---

## Findings

| ID | Severity | Title |
|----|----------|-------|
| F-CONFORM-1 | **blocker** | No CI/CD workflows (.github/workflows/ missing) |
| F-CONFORM-2 | **major** | No Sentry integration (frontend or Deno) |
| F-CONFORM-3 | **major** | .cursor/skills/ and .claude/skills/ out of sync (3 files differ) |
| F-CONFORM-4 | **minor** | No CI drift check for database.types.ts |
| F-CONFORM-5 | **minor** | No test for "no access" state (nobody user) |

### F-CONFORM-1: No CI/CD workflows (blocker)
- **Location:** `.github/workflows/` does not exist
- **Problem:** Subphase 0.1 requires `ci.yml` (typecheck, lint, test, build, size-limit, drift check, clean-migration gate) and `deploy.yml` (migrations, functions, frontend). Phase exit criteria depend on CI. Without it there is no automated testing, no clean-migration validation, no type-drift detection, and no deploy pipeline.
- **Evidence:** `search_files` confirmed no `.github/workflows/` directory.
- **Fix:** Create `.github/workflows/ci.yml` with `pnpm verify`, `supabase db lint`, `supabase test db`, `fn:check && fn:test`, `db:types` drift check, clean-migration gate, and build. Create `.github/workflows/deploy.yml` per spec.

### F-CONFORM-2: No Sentry integration (major)
- **Location:** No Sentry SDK in any package.json; no `Sentry.init()` in frontend or Deno functions
- **Problem:** Subphase 0.1 and 0.3 require Sentry. `_shared/logging.ts` comments about a Sentry seam but does not actually send events to Sentry. No `@sentry/react` or Deno Sentry SDK installed.
- **Evidence:** `grep -r "sentry" packages/ apps/ supabase/functions/` only found a comment in `logging.ts`. No Sentry dependency in any package.json.
- **Fix:** Add `@sentry/react` to back-office, configure Sentry init in app entry point. Add Sentry SDK to `_shared/logging.ts`, wire `captureException`.

### F-CONFORM-3: Skills out of sync (major)
- **Location:** `react-frontend/SKILL.md`, `react-frontend/reference.md`, `i18n-rtl/reference.md`
- **Problem:** The `.cursor/skills/` and `.claude/skills/` copies contain different versions of three files. Conformance brief requires them to be identical. `.cursor` versions reflect the actual ADR-41 fallback decision; `.claude` versions still reference outdated calendar library choices.
- **Evidence:** `diff -rq` confirmed 3 differ. Key example: `react-frontend/SKILL.md` line 94 says "schedule-x core + custom resource columns (ADR-41 verdict)" in `.cursor` but "schedule-x (per ADR-41 verdict)" in `.claude`.
- **Fix:** Sync `.claude/skills/` to match `.cursor/skills/` (the cursor versions reflect actual implementation decisions).

### F-CONFORM-4: No CI drift check for database types (minor)
- **Location:** No CI pipeline
- **Problem:** Subphase 0.4 requires a CI drift check on `database.types.ts`. The file is committed but nothing enforces it stays current with migrations.
- **Evidence:** `packages/db/src/database.types.ts` exists but there is no CI to run `supabase gen types` and fail on drift.
- **Fix:** Add `pnpm db:reset && pnpm db:types && git diff --exit-code` to CI pipeline.

### F-CONFORM-5: No "no access" test (minor)
- **Location:** No test covers the no-membership user path
- **Problem:** Subphase 0.2 acceptance criteria requires verifying users without memberships see a "no access" state. The `NoAccessPage.tsx` exists but no test exercises this path.
- **Evidence:** No test references `nobody@spacorner.test` seed user (exists in seed.sql line 11).
- **Fix:** Add a Playwright journey signing in as `nobody@spacorner.test` and asserting the no-access state is shown.

---

## What was done well

1. **Tenancy skeleton is thorough.** 10 migrations covering extensions, tenants, profiles, memberships, branches, audit log, settings, idempotency keys, colleague read, and provisioning. The all-branches representation (no sentinel UUID) is correctly implemented. pgTAP harness with 7-user fixture matrix and 190-line test suite covering 26+ assertions including cross-tenant FK attack tests.

2. **Helper functions follow the spec precisely.** `has_tenant_role` takes an explicit branch parameter with no default (test proves omitting branch raises 42883). All SECURITY DEFINER functions pin `search_path = public`. `colleague_profiles` exposes only id, name, avatar.

3. **Edge Function platform is solid.** `_shared/server.ts` implements the envelope, auth modes, CORS, request IDs, and idempotency. Function template and health route are present. `packages/validation` has a Deno-compatible export contract test.

4. **Frontend platform complete.** Six packages, TanStack Router, Lingui i18n with en/ar catalogs, money/date formatters, login/reset screens, session context with tenant/branch switchers, Playwright smoke suite, and design-skill wrapper components.

5. **ADR-41 spike fully documented.** Even though premium was not evaluated, the fallback evidence is comprehensive (render times, keyboard, RTL, drag performance, bundle size) and the gap list is documented.

---

## Blocking issues

The blocker (no CI/CD) means Phase 0 **cannot exit**. Every later phase depends on CI to:
- Run pgTAP tests (regression on RLS)
- Run Deno tests (regression on Edge Functions)
- Run Vitest and Playwright suites
- Detect type drift between migrations and generated types
- Verify the clean-migration gate
- Deploy to staging/production

Until `.github/workflows/ci.yml` and `.github/workflows/deploy.yml` exist and pass, Phase 0 remains incomplete regardless of the code quality.

---

## Recommendation to the chair

**Return phase 0 to the implementation team** with the blocker and two major findings. The tenancy, frontend, and edge function work is solid and should not require rework. The three actionable items are:

1. Create `.github/workflows/ci.yml` and `.github/workflows/deploy.yml` meeting the subphase 0.1 spec.
2. Integrate Sentry (frontend + Deno) and wire `captureException`.
3. Sync `.claude/skills/` with `.cursor/skills/` (3 files differ).

The minor findings (drift check, no-access test) can be fixed in the same pass.