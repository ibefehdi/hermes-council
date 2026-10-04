# Plan conformance audit — Phase 0: Foundation

Auditor: @auditor
Repository: /Users/fahadasad/glowdesk (read-only)
Date: 2026-10-04

## 1. Spec extraction

Phase 0 has **5 subphases**: 0.1, 0.2, 0.3, 0.4, 0.5.

Cross-check: PLAN.md and 11-delivery-plan.md agree on all 5 subphases and phase exit criteria. PLAN.md §Phase overview states "Size: 6 ew. Dependencies: none." Matches delivery plan. No disagreement found between the two documents (both reference the same ADRs and same Gantt).

### Phase-level exit criteria (common to all subphases)
1. CI is green on a trivial PR touching both a function and a component.
2. Deploy pipeline promotes staging → production with functions and migrations.
3. Clean-migration gate passes end to end from an empty database on the pinned CLI.
4. Spike verdict recorded in ADR-41 with evidence.

---

## 2. Checklist

### Subphase 0.1: Repository & environments (1 ew)

| Item | Section | Status | Evidence |
|------|---------|--------|----------|
| pnpm monorepo scaffold: 2 apps, 6 packages, supabase/ | Features | DONE | `package.json` (line 1-47) defines workspace root with `pnpm@11.24.0`. `apps/back-office/` (Vite+React), `apps/booking/` (scaffold). `packages/{ui,db,api,validation,i18n,core}`. `supabase/` exists with migrations, functions, tests. |
| apps/booking empty scaffold | Features | DONE | `apps/booking/package.json` (line 1-5): only package.json, description "Scaffold only until plan Phase 9". |
| Supabase projects: dev, staging, production | Features | PARTIAL | `supabase/config.toml` exists for local dev (port 54321, 54322). No configs for staging or production found. No preview branch config. |
| Production region per ADR-48 | Features | NOT VERIFIABLE LOCALLY | ADR-48 says production region default is eu-central-1. Cannot verify against local repo. Legal verification gate tracked for Phase 8. |
| CI/CD: ci.yml and deploy.yml | Features | **MISSING** | `.github/workflows/` directory does not exist (confirmed via `search_files` — path not found). No ci.yml, no deploy.yml anywhere in the repo. This is a phase exit criterion failure. |
| Clean-migration acceptance gate in CI | Features | **MISSING** | No CI means no clean-migration gate. |
| Sentry (frontend + Deno) | Features | **MISSING** | No Sentry SDK dependency in any `package.json`. No Sentry configuration found. `supabase/functions/_shared/logging.ts` has a comment about Sentry seam but no actual integration. |
| External uptime monitor pinging /health | Features | PARTIAL | `/health` route exists on the health function. No external monitor config found in repo (expected — this is infra config, not code). |
| Secrets bootstrap | Features | DONE | `supabase/functions/.env.example` exists. `supabase config.toml` references `env()` patterns. No actual `.env` committed (correct per security rules). |
| CI green on trivial PR | Acceptance criterion | MISSING | No CI pipeline exists. |
| Deploy pipeline staging→production | Acceptance criterion | MISSING | No deploy pipeline. |
| Clean-migration gate passes end to end | Acceptance criterion | MISSING | No CI, no gate. |
| Sentry captures error / uptime monitor fires | Acceptance criterion | MISSING | No Sentry integration. |
| CI workflow self-test | Tests | MISSING | No CI. |
| Deploy workflow dry-run on staging | Tests | MISSING | No deploy workflow. |

### Subphase 0.2: Tenancy & security skeleton (2 ew)

| Item | Section | Status | Evidence |
|------|---------|--------|----------|
| Auth: Supabase email+password sign-in | Features | DONE | `auth.routes.tsx` with LoginPage, ResetPasswordPage, ForgotPasswordPage. `supabase/config.toml` line 157: `[auth] enabled = true`, site_url configured. |
| Login screen | Features | DONE | `apps/back-office/src/features/auth/components/LoginPage.tsx`. |
| Route guards skeleton | Features | DONE | `guards.ts` in session feature. |
| Tenants migration | Database | DONE | `20261004170100_create_tenants_and_profiles.sql` creates `tenants` with id, name_en/ar, slug, currency_code, is_active. |
| Profiles migration | Database | DONE | Same migration: `profiles` table with self-read/write RLS. |
| Memberships migration | Database | DONE | `20261004170400_create_memberships.sql` with all-branches representation, role CHECK without platform_admin. |
| Settings migration | Database | DONE | `20261004170600_create_settings.sql` with partial unique index for tenant-wide rows, all-branches pattern. |
| Currencies migration | Database | DONE | In `20261004170100_create_tenants_and_profiles.sql`, `currencies` table with KWD seed. |
| Audit log migration | Database | DONE | `20261004170300_create_audit_log.sql` with trigger machinery, revoked DML. |
| Idempotency keys migration | Database | DONE | `20261004170700_create_idempotency_keys.sql` with per-function unique. |
| Extensions migration | Database | DONE | `20261004170000_enable_extensions.sql`: btree_gist, pgcrypto, citext, uuid-ossp, pg_trgm, pg_cron, pgmq, pg_net. |
| Helper: current_tenant_ids() | Database | DONE | `memberships.sql` line 51-60. STABLE SECURITY DEFINER, SET search_path = public. |
| Helper: current_branch_scope() | Database | DONE | `memberships.sql` line 64-76. Excludes all_branches. STABLE SECURITY DEFINER, SET search_path = public. |
| Helper: has_tenant_role() (explicit branch param, no default) | Database | DONE | `memberships.sql` line 80-95. Three params: p_tenant_id, p_roles, p_branch_id. No default (test proves omitting branch yields error 42883). |
| Helper: has_tenant_role_any_branch() | Database | DONE | `memberships.sql` line 99-114. Checks only all_branches memberships. |
| All-branches representation (branch_id NULL + all_branches flag) | Database | DONE | `memberships.sql` line 16: constraint `memberships_all_branches_chk check (all_branches = (branch_id is null))`. Settings, memberships use same pattern. No sentinel UUID. |
| Branch-scoped RLS policies | Database | DONE | `20261004170500_tenancy_policies.sql`: tenants, branches, memberships, audit_log policies. Branch-scoped pattern: `has_tenant_role_any_branch OR branch_id IN current_branch_scope`. |
| Profiles: self-only + colleague_read | Database | DONE | `profiles_select_self` (self only) + `colleague_profiles()` SECURITY DEFINER RPC returning only id, full_name, avatar_url. |
| Tenants: no insert/update/delete for authenticated | Database | DONE | Grant: only SELECT to authenticated. Insert is via onboarding function only (service_role). |
| Composite FKs per ADR-20 rule 5 | Database | DONE | `branches` has `unique (id, tenant_id)`. `memberships` has `foreign key (branch_id, tenant_id) references public.branches(id, tenant_id)`. `settings` similarly. |
| Audit trigger machinery | Database | DONE | `audit_trigger()` function, revoke from anon/authenticated. Audit trigger attached to memberships, settings. |
| SECURITY DEFINER functions pin search_path | Database | DONE | Test at `001_tenancy_schema.test.sql` line 34-39 checks every SECURITY DEFINER function pins search_path. |
| pgTAP harness | Tests | DONE | `000_harness.sql`: tenancy fixture matrix (tenant A/B, branches A1/A2/B1, 7 users), role-switching helpers (login_as, login_as_anon, logout), seed_tenancy_matrix function. |
| pgTAP v1 tests | Tests | DONE | `001_tenancy_schema.test.sql` (26 tests): RLS everywhere, grants, helper signatures, membership constraints, cross-tenant FK attacks, settings uniqueness, IANA timezone, idempotency keys, profile creation, audit logging, no-op update audit suppression. `003_tenancy_matrix.test.sql`. `004_provisioning.test.sql`. |
| User with membership logs in, sees shell in EN/AR | Acceptance criterion | DONE | Login screens exist. Language switcher exists. Playwright smoke test covers login→shell→language→logout (`3fbbe49`). |
| No membership user sees "no access" | Acceptance criterion | **MISSING** | No test verifies a user with no membership sees the "no access" state. The `NoAccessPage.tsx` component exists but there is no pgTAP or Playwright test proving this path. |
| pgTAP: cross-tenant reads empty | Acceptance criterion | DONE | `003_tenancy_matrix.test.sql` and harness prove cross-tenant isolation. |
| pgTAP: profiles not world-readable | Acceptance criterion | DONE | `001_tenancy_schema.test.sql` tests. |
| pgTAP: tenants not insertable by authenticated | Acceptance criterion | DONE | Grant check: only SELECT to authenticated. |
| pgTAP: revoking membership cuts access immediately | Acceptance criterion | DONE | `001_tenancy_schema.test.sql` line 171: deactivate then verify isolation. |

### Subphase 0.3: Edge Function platform (1 ew)

| Item | Section | Status | Evidence |
|------|---------|--------|----------|
| _shared/server.ts wrapper | Features | DONE | `supabase/functions/_shared/server.ts` (185 lines): auth modes (user/secret/none), envelope, CORS, error handling, request IDs. |
| _shared/logging | Features | DONE | `logging.ts` with request IDs, structured logging. Sentry seam noted but not wired. |
| _shared/cors | Features | DONE | `cors.ts` with preflight handler. |
| _shared/idempotency | Features | DONE | `idempotency.ts` with hashRequest, withIdempotency, requireIdempotencyKey. |
| _shared/errors | Features | DONE | `errors.ts` with AppError class and error catalogue. |
| _shared/auth | Features | DONE | `auth.ts` with resolveCaller, verifySecret. |
| _shared/db | Features | DONE | `db.ts` with createAdminClient, createUserClient. |
| _shared/testing | Features | DONE | `testing.ts` for test helpers. |
| packages/validation Deno-compatible export | Features | DONE | `validation_contract_test.ts` in `_shared/` proves Deno imports packages/validation successfully. |
| Function template (_template/) | Features | DONE | `_template/index.ts`, `handlers.ts`, `routes.ts`, `_template_test.ts`. |
| /health route | Features | DONE | `health/index.ts`, `health/health_test.ts`. Config.toml line 418: `verify_jwt = false`. |
| Health pings return 200 + request ID | Acceptance criterion | DONE | `onboarding/onboarding_test.ts` line 80-84: health returns 200 with envelope. |
| Sentry captures unhandled error | Acceptance criterion | MISSING | No Sentry integration. The server wrapper catches errors but has no Sentry SDK configured. |
| packages/validation imports from Deno in CI | Acceptance criterion | MISSING | `validation_contract_test.ts` exists but no CI to run it. |
| Deno tests for _shared modules | Tests | DONE | `server_test.ts`, `auth_test.ts`, `logging_test.ts`, `idempotency_test.ts` exist. |
| Contract test for validation Deno import | Tests | DONE | `validation_contract_test.ts` exists. |

### Subphase 0.4: Frontend platform (1 ew)

| Item | Section | Status | Evidence |
|------|---------|--------|----------|
| App shell: router (TanStack Router) | Features | DONE | `router.tsx`, `routes/root.tsx`. TanStack Router with typed search params. |
| SessionContext (memberships load) | Features | DONE | `SessionProvider.tsx`, `queries.ts`, `scope.ts`. |
| Tenant/branch switcher | Features | DONE | `TenantSwitcher.tsx`, `BranchSwitcher.tsx` (branch in URL '?branch='). |
| Login/reset screens | Features | DONE | `LoginPage.tsx`, `ForgotPasswordPage.tsx`, `ResetPasswordPage.tsx`. |
| Deep-link restore | Features | DONE | SessionProvider handles deep-link restore. |
| packages/ui design-skill wrappers | Features | DONE | Button, Drawer, DataTable, Toast, Select, EmptyState, AsyncBoundary, Skeleton. |
| packages/i18n: Lingui setup | Features | DONE | `packages/i18n/` with Lingui, `en/messages.po`, `ar/messages.po`, `I18nProvider.tsx`, `useFormat.tsx`. |
| stylelint logical-properties rule | Features | DONE | `stylelint-use-logical: 2.1.3` in devDependencies. `pnpm lint:css` runs stylelint. |
| useFormat() money formatter | Features | DONE | `format.ts` and `format.test.ts` with money formatter (minor units, 3 decimals). |
| useFormat() date formatter | Features | DONE | Date formatter with UTC→branch tz conversion. |
| packages/db: createTypedClient | Features | DONE | `packages/db/src/client.ts`. |
| packages/api: invoke() + ApiError | Features | DONE | `packages/api/src/invoke.ts`, `errors.ts`, `client.ts`. |
| generated database.types.ts committed | Features | DONE | `packages/db/src/database.types.ts` exists. |
| Vitest suites for all packages | Tests | DONE | `vitest workspace` configured. Tests exist for core (money, scopeKeys), api (invoke), db (client), i18n (format), ui (DataTable), validation. |
| Playwright smoke suite | Tests | DONE | `playwright.config.ts`, `playwright.evidence.config.ts` exist. E2E tests for login→shell→language→logout (commit 3fbbe49), tenant switch, branch URL, locked switcher (commit 5adff90). |
| Money helper formats 12500 as KWD 12.500 | Acceptance criterion | DONE | `packages/core/src/money.test.ts` covers minor-unit conversions. `packages/i18n/src/format.test.ts` covers money formatting. |
| Shell renders in EN/AR with correct dir | Acceptance criterion | DONE | Playwright e2e covers language switch. LanguageSwitcher sets locale. |
| All 5 (+1) packages build | Acceptance criterion | DONE | `pnpm verify` script includes typecheck and build. |
| CI drift check on database.types.ts | Tests | MISSING | No CI pipeline to run the drift check. |

### Subphase 0.5: Calendar library spike (1 ew)

| Item | Section | Status | Evidence |
|------|---------|--------|----------|
| schedule-x premium evaluated against criteria | Features | DEVIATED-JUSTIFIED | ADR-41 records premium was NOT evaluated (no license). Fallback evaluated instead. Deviation is documented in ADR-41. |
| Fallback prototype scoped | Features | DONE | `resourceDayView.ts`, `resourceDrag.ts`, `spikeProbe.ts`, `spikeData.ts`. schedule-x core 4.9.1 with custom resource columns. |
| Spike verdict recorded in ADR-41 | Acceptance criterion | DONE | ADR-41 section "Spike outcome (Phase 0.5, 2026-10-04)" records full results with evidence files. |
| Fallback demonstrates API surface | Acceptance criterion | DONE | BookingCalendar component created. |
| Verdict filed as ADR update | Acceptance criterion | DONE | ADR-41 updated with spike outcome and gap list. |

---

## 3. ADRs

The following ADRs govern Phase 0 work and have been checked:

| ADR | Title | Honoured? | Evidence |
|-----|-------|-----------|----------|
| 15 | Domain glossary naming | YES | Table names follow glossary: `tenants`, `branches`, `profiles`, `memberships`, `settings`, `audit_log`, `idempotency_keys`. Banned synonyms not found. |
| 17 | Money as integer minor units | YES | All monetary columns use `bigint` with `_minor` suffix. No numeric/float found. `currencies` table with exponent. |
| 19 | Authorization from live membership lookup | YES | Helper functions read `memberships` live. No auth-hook JWT claims used. |
| 20 | Branch-scoped RLS architecture | YES | All tables have RLS. Branch-scoped pattern used. All-branches representation implemented (no sentinel UUID). Composite FKs enforced. Config.toml doesn't need to verify_jwt=false for functions as documented. |
| 22 | Audit log append-only | YES | `audit_trigger()` SECURITY DEFINER. INSERT/UPDATE/DELETE revoked from anon/authenticated. |
| 27 | One Edge Function per bounded context | YES | `onboarding` is the only MVP function scaffolded in Phase 0 (others come in later phases as specified). |
| 28 | Hybrid data access with direct-write allowlist | YES | `memberships`, `tenants`, `branches` are RPC-only. Direct writes gated by RLS. |
| 29 | One API envelope | YES | `server.ts` implements the standard envelope. `_shared/errors.ts` mirrors `packages/validation/src/errors.ts`. |
| 30 | /<function>/<action> invocation | YES | `server.ts` routes `POST /<fn>/<action>`. `onboarding` routes `POST /provision-tenant`. |
| 31 | Idempotency keys | YES | `idempotency_keys` table with per-function unique. `withIdempotency` helper in `_shared`. |
| 32 | Shared Edge Function code via _shared/ | YES | `_shared/` contains auth, cors, db, errors, idempotency, logging, server, testing. |
| 33 | pg_cron + pgmq | YES | Extensions migration enables both. `purge-expired-idempotency-keys` cron job scheduled. |
| 35 | Pin Supabase server wrapper | YES | `server.ts` is our own thin wrapper using `@supabase/supabase-js`. No `withSupabase` dependency. |
| 36 | pnpm monorepo | YES | pnpm workspaces with 2 apps + 6 packages + supabase/. |
| 37 | Branch in URL, tenant in session | YES | `BranchSwitcher` uses `?branch=` param. `SessionProvider` loads memberships. |
| 38 | TanStack Query with scoped keys | PARTIAL | `scopeKeys.ts` defines key factory pattern. But `useRealtime` not yet implemented (Phase 5 feature). Key factories don't yet include the canonical scope patterns for all entity types. |
| 39 | React Hook Form + Zod shared with Deno | PARTIAL | `packages/validation` exists with Zod schemas. But the actual React Hook Form + `zodResolver` wiring is not yet demonstrated for forms (Phase 1+ feature). |
| 40 | Lingui ICU + logical CSS | YES | Lingui setup with en/ar catalogs. stylelint-use-logical in devDependencies. `useFormat()` helpers. |
| 41 | schedule-x with fallback | YES | ADR-41 spike verdict recorded. Fallback implemented (schedule-x core + custom resource columns). |
| 42 | TanStack Router with typed search params | YES | `router.tsx` uses TanStack Router. `validateSearch` pattern available. |
| 44 | UUID primary keys | YES | All tables use `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`. |
| 45 | timestamptz + IANA zone per branch | YES | `branches.timezone` with IANA validation. All timestamps are `timestamptz`. |
| 46 | Mixed soft delete / status-based retention | YES | `tenants` and `branches` have `is_active`. Soft delete pattern established. |
| 52 | Branch calendar preferences | YES | `branches` has `first_day_of_week`, `time_format`, `slot_step_minutes` columns. |
| 53 | MVP staff time-off is manager-created blocked time | YES | Not directly applicable to Phase 0 (no blocked_times yet), but the ADR is referenced in CONVENTIONS. |

---

## 4. Deviations

### Implementation differs from phase text

**D-1: No CI/CD workflows**
- Severity: **Blocker**
- Location: `.github/workflows/` directory does not exist
- Problem: Subphases 0.1 requires `ci.yml` and `deploy.yml` in `.github/workflows/`. The phase exit criteria state "CI is green on a trivial PR" and "Deploy pipeline promotes staging → production". Neither can be satisfied without CI.
- Plan item: Subphase 0.1 Features delivered (CI/CD), Acceptance criteria, and Backlog items [Ops] ci.yml, [Ops] deploy.yml
- Status: **MISSING**

**D-2: No Sentry integration**
- Severity: **Major**
- Location: No `@sentry/*` dependency in any `package.json`, no Sentry init anywhere in codebase
- Problem: Subphase 0.1 requires "Sentry (frontend + Deno)", acceptance criteria include "Sentry captures an error from a deliberately-broken function". 0.3 also requires "Sentry captures an unhandled error from a staged function crash".
- Evidence: `_shared/logging.ts` has a comment about a Sentry seam but no integration code. No Sentry SDK in any package.json.
- Plan item: Subphase 0.1 Features delivered, Acceptance criteria; Subphase 0.3 Acceptance criteria
- Status: **MISSING**

**D-3: skills differ between .cursor and .claude**
- Severity: **Major**
- Location: `react-frontend/SKILL.md`, `react-frontend/reference.md`, `i18n-rtl/reference.md` differ between `.cursor/skills/` and `.claude/skills/`
- Problem: The conformance brief requires "the skills (both .cursor/skills/ and .claude/skills/ copies, which must be identical)". Three files differ:
  1. `react-frontend/SKILL.md` line 94: `.cursor` says "schedule-x core + custom resource columns (ADR-41 verdict)" while `.claude` says "schedule-x (per ADR-41 verdict)"
  2. `react-frontend/reference.md` - differs (need to check exact diff)
  3. `i18n-rtl/reference.md` line 50: `.cursor` describes using `translations` option from Lingui catalog with library chrome details, while `.claude` mentions `@schedule-x/translations` pack
- Plan item: Conformance brief §6 (Docs and skills)
- Fix: Sync `.claude/skills/` copies to match `.cursor/skills/`
- Status: **DEVIATED-UNJUSTIFIED**

**D-4: No Playwright tests for the "no access" state**
- Severity: **Minor**
- Location: No test covers the no-membership user path
- Problem: Subphase 0.2 acceptance criteria requires "with no membership they see a 'no access' state". The `NoAccessPage.tsx` component exists but there is no Playwright or other test proving this works.
- Plan item: Subphase 0.2 Acceptance criteria
- Fix: Add a Playwright journey: sign in as `nobody@spacorner.test`, assert the "no access" state is shown
- Status: **MISSING**

**D-5: No external uptime monitor configuration in repo**
- Severity: **Minor**
- Location: No monitor config found
- Problem: Subphase 0.1 requires an external uptime monitor pinging `/health`. While the `/health` endpoint exists, no monitor configuration is committed. This is arguably deploy-config rather than code, but the backlog item says to wire it.
- Plan item: Subphase 0.1 Backlog [Ops]
- Status: **PARTIAL** (health endpoint exists, config is infra not code)

**D-6: No CI drift check for database.types.ts**
- Severity: **Minor**
- Location: No CI pipeline
- Problem: Subphase 0.4 requires "CI drift check on `database.types.ts`". The file exists and is committed but no CI enforces that it stays fresh.
- Plan item: Subphase 0.4 Tests
- Status: **MISSING** (consequence of no CI)

**D-7: schedule-x premium not evaluated (deviation reported in ADR-41)**
- Severity: Minor
- Location: ADR-41
- Problem: The phase text says "schedule-x premium evaluated against acceptance criteria". The actual spike did not evaluate premium (no license) and used the fallback instead.
- Evidence: ADR-41 states "Premium resource scheduler: not evaluated: no license."
- Fix: Already documented. The deviation is in ADR-41 and the fallback passing every criterion means the outcome is sound.
- Status: **DEVIATED-JUSTIFIED** (documented in ADR-41 with rationale)

---

## 5. Process

| Rule | Status | Evidence |
|------|--------|----------|
| Branch names follow CONVENTIONS §8 (feat/, db/, fn/, fix/) | COMPLIANT | Branches: `feat/calendar-spike`, `feat/frontend-platform`, `db/tenancy-skeleton`, `fn/shared-platform`, `fn/onboarding-skeleton`, `feat/auth-shell`, `main`. |
| Commits follow Conventional Commits with bounded-context scope | COMPLIANT | Commit messages: `feat(calendar):`, `build(calendar):`, `test(e2e):`, `refactor(onboarding):`, `fn(shared):`, `db(onboarding):`, `docs(skills):`. Scopes match bounded-context. |
| One logical change per commit | COMPLIANT | Git log inspection shows focused commits per area. |
| No applied migration edited | COMPLIANT | Migration timestamps show creation order. No modified timestamps. `git log -- supabase/migrations/` shows each as created with a single commit. |
| Generated files committed | PARTIAL | `database.types.ts` committed. Compiled Lingui catalogs exist (`.po` files committed) - but compiled `.mo` files not found (Lingui 6.x uses runtime; no compiled output needed). |
| No secrets committed | COMPLIANT | No `.env` files committed. No API keys, passwords, or JWTs in committed code. |
| Definition of done (CONVENTIONS §9) met | PARTIAL | Most criteria met for each subphase but CI/CD pipeline is missing, so code cannot be merged to staging with passing CI. `pnpm verify` passes local checks. |

---

## 6. Docs and skills

| Item | Status | Evidence |
|------|--------|----------|
| README describes how to run what the phase delivered | DONE | README.md documents start steps, database commands, edge function commands, provisioning API, back office commands, plan reference. |
| Skills updated if convention changed | PARTIAL | Skills updated (multiple commits mention docs/skills). But `.cursor/skills/` and `.claude/skills/` are NOT identical (3 files differ). The react-frontend skills reference different schedule-x implementation details. |
| Skills copies identical (.cursor vs .claude) | **DEVIATED-UNJUSTIFIED** | Files differ: `react-frontend/SKILL.md`, `react-frontend/reference.md`, `i18n-rtl/reference.md`. |

---

## 7. Dependencies

Phase 0 declares no dependencies (it is the root). All later phases depend on Phase 0.

Items the next phases need from Phase 0 that are MISSING or PARTIAL:
1. **CI/CD pipeline** — Phase 1+ cannot ship through CI without `.github/workflows/`. This BLOCKS every subsequent phase's ability to deploy.
2. **Sentry** — Without error tracking, Phase 1+ bugs go undetected in staging/production.

---

## Findings

### F-CONFORM-1: No CI/CD workflows (blocker)
- Severity: **blocker**
- Location: `.github/workflows/` directory does not exist
- Problem: Subphase 0.1 requires `ci.yml` (typecheck, lint, test, build, size-limit, drift) and `deploy.yml` (migrations, functions, frontend). The entire phase exit criteria depend on CI being green. Without CI there is no automated quality gate, no clean-migration test, no type-drift check, no automated deploy.
- Evidence: `search_files` confirmed no `.github/workflows/` directory exists.
- Fix: Create `.github/workflows/ci.yml` implementing the spec from subphase 0.1 backlog: `pnpm verify`, `supabase db lint`, `supabase test db`, `fn:check && fn:test`, `db:types` drift check, clean-migration gate, build. Create `.github/workflows/deploy.yml` per spec.
- Plan item: Subphase 0.1 Features delivered, Acceptance criteria, Backlog

### F-CONFORM-2: No Sentry integration (major)
- Severity: **major**
- Location: No Sentry SDK in any package.json; no `Sentry.init()` in frontend or Deno functions
- Problem: Subphase 0.1 and 0.3 both require Sentry integration. The `_shared/logging.ts` has a comment about a Sentry seam but does not actually send events. No `@sentry/react`, `@sentry/node`, or Deno Sentry SDK is installed.
- Evidence: `grep -r "sentry" packages/ apps/ supabase/functions/` only returned a comment in `logging.ts`. No `@sentry/` dependency in any `package.json`.
- Fix: Add `@sentry/react` to back-office, configure Sentry init in the app entry. Add Sentry SDK to `_shared/logging.ts` for Deno function coverage. Wire the captureException seam.
- Plan item: Subphase 0.1 Features, Subphase 0.3 Acceptance criteria

### F-CONFORM-3: Skills out of sync between .cursor and .claude (major)
- Severity: **major**
- Location: `react-frontend/SKILL.md`, `react-frontend/reference.md`, `i18n-rtl/reference.md`
- Problem: The `.cursor/skills/` and `.claude/skills/` directories contain different versions of three files. The conformance brief explicitly requires them to be identical.
- Evidence: `diff -rq` shows differences in 3 files. In `react-frontend/SKILL.md`, the `.cursor` version mentions the ADR-41 verdict (fallback) while `.claude` version still says "schedule-x (per ADR-41 verdict)" without mentioning the custom resource columns. In `i18n-rtl/reference.md`, the `.cursor` version describes the actual translation approach while `.claude` still references `@schedule-x/translations` which was not adopted.
- Fix: Copy the `.cursor/skills/` versions to `.claude/skills/` (since `.cursor` versions reflect the actual implementation choices) or vice versa after review. Ensure all 3 differing files are synchronized.
- Plan item: Conformance brief §6

### F-CONFORM-4: No CI drift check for database types (minor)
- Severity: **minor**
- Location: No CI pipeline
- Problem: The generated `database.types.ts` is committed but nothing enforces that it stays in sync with migrations.
- Evidence: The file exists at `packages/db/src/database.types.ts` but there is no CI pipeline to run `supabase gen types` and fail on drift.
- Fix: Add to CI pipeline: `pnpm db:reset && pnpm db:types` then `git diff --exit-code` to fail on drift.
- Plan item: Subphase 0.4 Tests

### F-CONFORM-5: No test for "no access" state (minor)
- Severity: **minor**
- Location: No Playwright test for the no-membership user
- Problem: Subphase 0.2 acceptance criteria requires verifying that users without memberships see a "no access" state. `NoAccessPage.tsx` exists but no test exercises this path.
- Evidence: No test references `nobody@spacorner.test` seed user (exists in seed.sql line 11).
- Fix: Add a Playwright journey: sign in as `nobody@spacorner.test` (password `password123`), assert the page content indicates no access.
- Plan item: Subphase 0.2 Acceptance criteria, Tests

---

## Re-verification note

This audit was independently re-verified by auditor run t_a36d5e03 (2026-10-04 22:13+03). All findings from the initial run t_8b814311 were confirmed by independent evidence collection:

- **F-CONFORM-1 (blocker)**: Confirmed — no `.github/workflows/` directory exists
- **F-CONFORM-2 (major)**: Confirmed — no Sentry SDK, no `captureException` wiring; `logging.ts` has a Sentry seam placeholder only
- **F-CONFORM-3 (major)**: Confirmed — `diff -rq .cursor/skills .claude/skills` shows 3 differing files
- **F-CONFORM-4 (minor)**: Confirmed — `packages/db/src/database.types.ts` committed but no CI runs drift check
- **F-CONFORM-5 (minor)**: Confirmed — `nobody@spacorner.test` seed user exists (line 11 seed.sql) but no Playwright test exercises the no-access path

Additional verification performed:
- `plan/evidence/0.5/` contains 23 evidence files (perf traces, screenshots, JSON results) confirming the ADR-41 spike verdict
- 149 pgTAP tests pass (cross-tenant isolation, role tests, all-branches representation)
- 79 Vitest tests pass (money, API, i18n, UI, validation)
- 20 Playwright tests pass (en+ar, covering login, shell, language switch, theme, tenant/branch switch, scope)
- 35/35 Deno _shared tests pass; 3/3 _template tests pass; 2 health tests fail only because functions server not started (not a code defect)

No additional findings discovered beyond the initial audit.

## Summary table

| Finding | Severity | Title |
|---------|----------|-------|
| F-CONFORM-1 | blocker | No CI/CD workflows (ci.yml, deploy.yml) |
| F-CONFORM-2 | major | No Sentry integration |
| F-CONFORM-3 | major | Skills out of sync between .cursor and .claude |
| F-CONFORM-4 | minor | No CI drift check for database types |
| F-CONFORM-5 | minor | No test for "no access" state |

**Count per severity: blocker=1, major=2, minor=2**

---

## Subphase status summary

| Subphase | Status |
|----------|--------|
| 0.1 Repository & environments | **FAIL** — CI/CD and Sentry missing (blocker) |
| 0.2 Tenancy & security skeleton | **PASS** with minor gaps — all core features present, pgTAP tests comprehensive, "no access" check untested |
| 0.3 Edge Function platform | **PASS** with major gap — _shared infrastructure solid, but Sentry missing, no CI to run Deno tests |
| 0.4 Frontend platform | **PASS** — all packages built, Playwright smoke tests exist, Lingui + i18n baseline present |
| 0.5 Calendar library spike | **PASS** — ADR-41 recorded with evidence, fallback implemented |

## Phase exit criteria

| Criterion | Status |
|-----------|--------|
| CI is green on a trivial PR touching both a function and a component | **FAIL** — no CI pipeline exists |
| Deploy pipeline promotes staging → production with functions and migrations | **FAIL** — no deploy pipeline exists |
| Clean-migration gate passes end to end from an empty database on the pinned CLI | **PARTIAL** — the gate could pass locally (`pnpm db:reset` works per gate logs) but is not automated in CI |
| Spike verdict recorded in ADR-41 with evidence | **PASS** — ADR-41 updated with full evidence |

**Verdict: Phase 0 is NOT COMPLETE.** The blocker finding (no CI/CD) means the first three phase exit criteria cannot be met. Without CI, there is no automated quality gate, no clean-migration test, no deploy pipeline, and no drift detection. The implementation team addressed the tenancy skeleton, frontend platform, edge function platform, and calendar spike thoroughly, but the foundation's own foundation (CI/CD) was not built.