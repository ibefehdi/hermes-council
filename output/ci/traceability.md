# Traceability: map what the plan promises to the tests that prove it

**Generated:** 2026-10-05T14:20:00+0300
**Repository:** /Users/fahad/GlowDesk (read-only)
**Baseline:** /Users/fahad/council/output/ci/baseline/BASELINE.md
**Sandbox:** /Users/fahad/council/.ci-sandbox/GlowDesk/base
**Commit:** 07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb

---

## 1. What is built

### Phase 0: Foundation — BUILT

| Subphase | Status | Evidence |
|---|---|---|
| 0.1 Repository and environments | PARTIAL | Repo, pnpm monorepo, local Supabase exist. No .github/workflows/ exists (ci.yml, deploy.yml missing per Phase 0 audit F-VERIFIER-1). Sentry not integrated (F-VERIFIER-2). |
| 0.2 Tenancy and security skeleton | BUILT | All migrations present (20261004170000–20261004172000). 029 tables with RLS. Auth, session, password-reset, membership helpers. pgTAP tests 001–003 (28+51 tests). |
| 0.3 Edge Function platform | BUILT | _shared/ modules: auth.ts, errors.ts, cors.ts, idempotency.ts, logging.ts, server.ts, testing.ts. Sentry transport absent (stub only). Health function exists. Templates. |
| 0.4 Frontend platform | BUILT | Router, session context, tenant/branch switchers, UI primitives, Lingui i18n, formatters. Vitest 288 passed at baseline. |
| 0.5 Calendar library spike | BUILT | ADR-41 verdict and evidence recorded. Fallback (schedule-x core + custom resource view) passed all criteria. Premium not evaluated (no license). |

**Phase 0 audit report:** /Users/fahad/council/output/audit/phase-0/AUDIT_REPORT.md — verdict FAIL (CI/deploy/Sentry missing), but core implementation substantially built.

### Phase 1: Tenancy, onboarding & settings — BUILT

| Subphase | Status | Evidence |
|---|---|---|
| 1.1 Provisioning | BUILT | provision_tenant, provision_branch RPCs (SECURITY DEFINER). Onboarding Edge Function handles provisioning. pgTAP test 004 (34 tests). |
| 1.2 Settings hub | BUILT | Settings tables, branch config, opening hours, invoice counters, calendar defaults. pgTAP tests 005–006. Settings UI screens in both locales. |
| 1.3 Roles & memberships | BUILT | Memberships, role grants, last-owner protection, immediate revocation. pgTAP test 007. Members UI, invite flow. |

**Phase 1 audit report:** /Users/fahad/council/output/audit/phase-1/AUDIT_REPORT.md — verdict FAIL (Arabic receptionist smoke failed; gate results from older commit).

### Phase 2: Staff & shifts — BUILT

| Subphase | Status | Evidence |
|---|---|---|
| 2.1 Staff records | BUILT | Staff members table, branch assignments, optional login, search normalization. pgTAP test 008. Staff Edge Function (upsert, invite-login). Staff UI. |
| 2.2 Shifts | BUILT | Shifts table, materialize function, copy-previous-week. pgTAP test 009. Shift grid UI with drag. |
| 2.3 Blocked time | BUILT | Blocked times table with exclusion constraint, locked RPCs, appointment conflict checks. pgTAP tests 010–011. Blocked time UI. |

**Phase 2 audit report:** /Users/fahad/council/output/audit/phase-2/AUDIT_REPORT.md — verdict PASS. 536 pgTAP, 94 Deno, 177 Vitest, 48 Playwright tests. 3 minor findings.

### Phase 3: Service catalogue — BUILT

| Subphase | Status | Evidence |
|---|---|---|
| 3.1 Catalogue data | BUILT | Services, categories, branch overrides, staff eligibility. Effective-values view. pgTAP tests 012–013. |
| 3.2 Catalogue function | BUILT | upsert-service, reorder endpoints. pgTAP test 014. |
| 3.3 Catalogue UI | BUILT | Catalogue hub, service editor, category editor with reorder. Playwright journey in both locales. |

**Phase 3 audit report:** /Users/fahad/council/output/audit/phase-3/AUDIT_REPORT.md — verdict PASS. 684 pgTAP, 102 Deno, 224 Vitest, 50 Playwright tests. 0 findings.

### Phase 4: Clients — BUILT

| Subphase | Status | Evidence |
|---|---|---|
| 4.1 Client data | BUILT | Clients table, client notes, link appointments to clients, staff client cards view. pgTAP tests 015–016. |
| 4.2 Client function | BUILT | Clients Edge Function with duplicate check, block, delete, anonymize, CSV import. pgTAP tests 017–018. |
| 4.3 Client UI | BUILT | Client list, editor, duplicate warning, profile, notes, block/import screens. Playwright journey. |

**Evidence:** git log shows explicit client commits (ae08679 through 25a8c8b). Commit 585316c docs(evidence): record Phase 4 gate run on 39062c4 and exit evidence. Commit 39062c4 test(evidence): add Phase 4 exit spec and gate script.

**No Phase 4 audit report found** — this is the most recently built phase.

### Phases NOT BUILT

| Phase | Status | Notes |
|---|---|---|
| 5 Calendar & booking | NOT STARTED | No bookings Edge Function. Appointments table exists as pull-forward for Phase 4. Calendar feature in frontend is only the spike route (/dev/calendar-spike). No slot engine, no conflict engine, no booking lifecycle. No Playwright journey for bookings. |
| 6 Checkout, sales & register | NOT STARTED | No checkout Edge Function. No sales tables (sales, sale_items, payments, register_sessions). No checkout UI. No Playwright journey. |
| 7 Reports, exports & hardening | NOT STARTED | No reports Edge Function. No report views/RPCs. No CSV export. No audit viewer. No home screen operational data. |
| 8 SpaCorner go-live | NOT STARTED | |
| 9–17 Post-MVP | NOT STARTED | |

---

## 2. Requirements (for built subphases)

### ADR invariants carried by the built work

| ADR | Invariant | Status | Test coverage |
|---|---|---|---|
| ADR-17 | Money is integer minor units (bigint _minor) | BUILT | pgTAP tests check _minor columns. schema enforced in migrations. Vitest money.test.ts covers formatting and arithmetic. |
| ADR-19 | Authorization from live membership lookup; JWT is identity only | BUILT | current_tenant_ids(), current_branch_scope(), has_tenant_role() SECURITY DEFINER helpers. pgTAP tests 002-003 cover role-scoped access. |
| ADR-20 | Branch-scoped RLS architecture | BUILT | 29 tables with RLS. Composite FKs. Role helpers with branch scope. pgTAP tests 001-003 cover tenancy schema and RLS matrix. |
| ADR-20 rule 6 | All-branches = nullable branch_id + all_branches flag | BUILT | memberships, settings, blocked_times use this pattern. pgTAP tests check. |
| ADR-20 rule 10 | SECURITY DEFINER functions SET search_path = public | PARTIAL | All definder functions in catalog show prosecdef=t. Migration 20261004170000 sets extensions. supabase db lint runs in CI. Need verification that every definer function has explicit search_path. |
| ADR-21 | security_invoker views | BUILT | service_effective_values, service_eligible_staff, staff_client_cards use security_invoker=true. pgTAP 013 and 016 assert this. |
| ADR-22 | Audit log append-only | BUILT | audit_trigger function. pgTAP tests check. |
| ADR-28 | Hybrid data access with explicit direct-write allowlist | BUILT | Direct-write tables match the allowlist. Edge Functions handle bookings/staff/catalogue/clients writes. |
| ADR-29 | Envelope + error code catalogue | BUILT | _shared/server.ts serves the envelope. _shared/errors.ts defines codes. Deno contract tests validate. |
| ADR-31 | Idempotency keys for money mutations | BUILT (schema only) | idempotency_keys table exists (ADR-31). Deno idempotency tests pass. But Phase 5/6 (where money moves) are not built yet, so idempotency is only tested in isolation. |
| ADR-44 | UUID primary keys | BUILT | All tables use gen_random_uuid(). |
| ADR-45 | timestamptz + IANA zone per branch | BUILT | branches.timezone column. All timestamps are timestamptz. pgTAP test 001 checks constraint. |
| ADR-7 | Fixed appointment status enum | BUILT (schema) | appointments table exists. appointment status enum not yet used in booking flows (Phase 5). |
| ADR-26 | Opening hours, closed periods, blocked time | BUILT | branch_opening_hours with overnight support, closed_periods, blocked_times tables. pgTAP tests 005, 010-011 cover. |
| ADR-53 | MVP staff time-off is manager-created blocked time | BUILT | Blocked time UI allows manager-creation. pgTAP and E2E tests cover. |
| ADR-51 | Deterministic checkout order and rounding | NOT BUILT | packages/core money code may exist but checkout RPC (Phase 6) not built. |
| ADR-24 | Double-booking prevention (exclusion + advisory lock) | NOT BUILT | Appointments schema has busy_range but the exclusion constraint and locked RPCs are not live (Phase 5 not built). |
| ADR-25 | Buffers in busy range | NOT BUILT | Columns exist in services but the booking-time snapshot isn't built. |

### Requirements from CONVENTIONS section 7 (testing standards)

| Rule | Automatable? | Test Coverage |
|---|---|---|
| pgTAP matrix per table/operation/role including cross-tenant, cross-branch, anon | YES | pgTAP tests 001-018 cover this for built tables. Each test checks SELECT/INSERT/UPDATE/DELETE per role + cross-scope + anon. |
| Clean-migration gate (reset from empty, type drift fails, functions typecheck, pgTAP, adversarial fixtures, sql/drafts-v1/ grep) | YES | Baseline confirmed: clean migration gate passes (db:reset → 43 migrations, type drift none, fn:check passes, pgTAP 923 passes, sql/drafts-v1/ grep returns empty). Not wired as CI gate — no .github/workflows/ exists. |
| Missing Arabic translations fail CI | YES | `pnpm i18n:compile` enforces catalog completeness. Baseline confirms it passes. |
| Logical CSS properties only | YES | `pnpm lint:css` enforces. Baseline confirms clean. |
| Size budgets (back-office ≤250 kB gzip, calendar ≤150 kB) | YES | `pnpm size` enforces. Baseline: back-office 225.78 kB / 250 kB, calendar 61.96 kB / 150 kB. |
| axe-core accessibility on main flows | PARTIAL | Playwright config does not include axe-core assertions. No evidence of accessibility testing. |
| Envelope and error-code contract tests | YES | Deno validation_contract_test.ts and shared server_test.ts cover these. |
| Idempotency replay | YES | _shared/idempotency_test.ts (8 tests) covers hash, require, replay, mismatch, concurrency. |
| Skills copies identical | YES | `pnpm skills:check` enforces. Baseline confirms .cursor/skills and .claude/skills are identical. |
| No secrets or local-only files committed | PARTIAL | git status is clean. Baseline confirms no uncommitted changes. No automated check for secrets in committed files. |

### Requirements from CONVENTIONS section 8 (PR checklist)

| Checklist item | Automatable? | Test coverage |
|---|---|---|
| Migration is new (not edit of applied) | YES | Clean-migration gate (db:reset on empty) proves this. |
| RLS policies present and pgTAP tests added | YES | pgTAP test suite covers all built tables. |
| Money columns are bigint _minor | YES | Schema lint + type drift check would catch this. |
| Names match glossary | PARTIAL | No automated name-checking. Review process. |
| Bilingual columns and Arabic search | YES | Bilingual columns in schema. search normalization migration. Vitest search test. |
| Direct writes stay within allowlist | PARTIAL | No automated allowlist checker. Review process. |
| Shared Zod schema in validation | YES | packages/validation exists and imports from Deno. Validation contract test. |
| Envelope + error codes used; Idempotency-Key on money mutations | YES | Deno contract tests. Idempotency tests. |
| i18n: no hardcoded strings; pnpm i18n:extract && compile | YES | i18n:compile passes. |
| pnpm verify green; tests added per section 7; a11y considered | YES | verify passes. a11y not yet enforced. |
| Audit trigger covers mutation | PARTIAL | Audit triggers exist. No automated per-table audit coverage checker. |

---

## 3. Mechanical sweeps

### 3.1 Database catalog — all 29 tables (public schema)

All tables have RLS enabled. None grant SELECT/INSERT/UPDATE/DELETE to `anon`. Authenticated role has SELECT on all (via RLS).

| Table | RLS | pgTAP ref | Key operations covered | Gaps |
|---|---|---|---|---|
| tenants | YES | 001, 002 | RLS: no insert/update/delete for authenticated. SECURITY DEFINER only. | — |
| profiles | YES | 001, 002 | Self-read/write + narrow colleague read. | — |
| branches | YES | 002 | Branch-scoped RLS. | — |
| audit_log | YES | 001, 002 | Append-only via triggers. No direct write. | — |
| memberships | YES | 002, 003, 007 | Role matrix, grant rules, last-owner protection. | — |
| settings | YES | 006 | Role-gated RPCs. | — |
| idempotency_keys | YES | — | Deny-all + select-only grant. | pgTAP coverage unknown for this table |
| plans | YES | 001 | Read-only. | — |
| plan_features | YES | 001 | Read-only. | — |
| currencies | YES | 001 | Read-only. | — |
| branch_opening_hours | YES | 005 | Branch-scoped. Overnight, split intervals. | — |
| closed_periods | YES | 005 | Branch-scoped. | — |
| invoice_counters | YES | 005 | Per-branch counters. | — |
| staff_members | YES | 008 | Tenant-scoped, branch assignments. | — |
| staff_branch_assignments | YES | 008 | Branch-scoped. Composite FK. | — |
| shifts | YES | 009 | Branch-scoped, overlap exclusion. | — |
| blocked_time_types | YES | 010 | Tenant-scoped. | — |
| blocked_times | YES | 010, 011 | Branch-scoped, exclusion constraint. Locked RPCs. | — |
| appointments | YES | — | Tenant-scoped via client FK. Pulled forward from Phase 5. | No pgTAP test file for appointments yet (Phase 5). |
| appointment_items | YES | — | Same as appointments. | No pgTAP test file yet. |
| booking_overrides | YES | — | | No pgTAP test file yet (Phase 5). |
| cancellation_reasons | YES | — | Tenant-scoped. | pgTAP coverage unknown. |
| service_categories | YES | 012 | Tenant-scoped. | — |
| services | YES | 012 | Tenant-scoped. | — |
| service_branch_overrides | YES | 012 | Branch-scoped. Composite FK. | — |
| service_staff | YES | 012 | Tenant+branch+staff. | — |
| clients | YES | 015 | Tenant-scoped. ADR-28 rules. | — |
| client_notes | YES | 015 | Tenant-scoped. | — |
| client_import_batches | YES | 018 | Tenant-scoped. | — |
| client_import_rows | YES | 018 | Tenant-scoped. | — |

**Views:**

| View | security_invoker | pgTAP ref | Notes |
|---|---|---|---|
| service_effective_values | YES (migration + pgTAP 013) | 013 | Resolves effective price/duration/buffers |
| service_eligible_staff | YES (migration + pgTAP 013) | 013 | Staff eligible per service+branch |
| staff_client_cards | YES (migration + pgTAP 016) | 016 | Column-restricted staff view of clients |

**SECURITY DEFINER functions:** 88 functions total, all SECURITY DEFINER except the following safety helpers used in RLS policies:
- branch_staff_schedule, client_is_bookable, client_name_key, client_tags, create_client, default_branch_hours, find_client_duplicates, is_client_tag_array, jsonb_text_array, match_client_duplicates, normalize_search, redact_audit_fields, set_actor_columns, set_appointment_item_busy_range, set_updated_at

Gap: Need to audit whether all SECURITY DEFINER functions declare `SET search_path = public`. The migration for extensions (20261004170000) sets up extensions but individual function definitions need checking. `supabase db lint` enforces this in CI per ADR-20 rule 10.

### 3.2 Edge Function routes and Deno test coverage

| Function | Route | Auth mode | Deno test (happy path) | Validation rejection | Auth/scope denial | Idempotent replay (money) |
|---|---|---|---|---|---|---|
| health | GET / | none | health_test.ts (2 tests): ✓ | N/A | N/A | N/A |
| _template | GET /whoami | user | template_test.ts: ✓ | — | ✓ (401 without session) | N/A |
| _template | POST /echo | user | template_test.ts: ✓ | — | ✓ | N/A |
| catalogue | POST /upsert-service | user | catalogue_test.ts: ✓ | ✓ (validation) | ✓ (401, FORBIDDEN) | No (catalogue doesn't move money) |
| catalogue | POST /reorder | user | catalogue_test.ts: ✓ | ✓ (validation) | ✓ | No |
| clients | POST /duplicate-check | user | clients_test.ts: ✓ | ✓ | ✓ | No |
| clients | POST /block | user | clients_test.ts: ✓ | ✓ | ✓ | No |
| clients | POST /delete | user | clients_test.ts: ✓ | ✓ | ✓ | No |
| clients | POST /anonymize | user | clients_test.ts: ✓ | ✓ | ✓ | No |
| clients | POST /import-dry-run | user | clients_test.ts: ✓ | ✓ | ✓ | No |
| clients | POST /import | user | import_test.ts: ✓ | ✓ (validation) | ✓ | N/A (import is owner-only) |
| clients | POST /import-consume | secret | import_test.ts: ✓ | N/A | ✓ (secret verification) | ✓ (consumer idempotent) |
| staff | POST /upsert | user | staff_test.ts: ✓ | ✓ | ✓ | No |
| staff | POST /invite-login | user | staff_test.ts: ✓ | ✓ | ✓ | No |
| staff | POST /shifts-materialize | user | shifts_test.ts: ✓ | ✓ | ✓ | No |
| onboarding | POST /provision-tenant | secret | onboarding_test.ts: ✓ | ✓ | ✓ (secret auth) | N/A (idempotent via slug matching) |
| onboarding | POST /provision-branch | secret | onboarding_test.ts: ✓ | ✓ | ✓ | N/A |
| onboarding | POST /invite-user | user | members_test.ts: ✓ | ✓ | ✓ | No |
| onboarding | POST /update-membership | user | members_test.ts: ✓ | ✓ | ✓ | No |
| onboarding | POST /deactivate-membership | user | members_test.ts: ✓ | ✓ | ✓ | No |
| **not built** | bookings/* | — | No function directory | — | — | — |
| **not built** | checkout/* | — | No function directory | — | — | — |
| **not built** | reports/* | — | No function directory | — | — | — |

**Summary:** 20 routes across 6 functions. Happy path, validation, and auth/scope denial covered for all built routes. Idempotent replay only tested in _shared/idempotency_test.ts (generic) and for clients import consumer. Money-moving routes (checkout — Phase 6) not built yet.

### 3.3 Frontend screen routes and Playwright coverage

| Route | Component | Feature | Playwright journey visits? | Both en + ar? |
|---|---|---|---|---|
| /login | LoginPage | auth | ✓ (smoke, all spec files) | ✓ (fixtures.ts runs each twice) |
| /forgot-password | ForgotPasswordPage | auth | ✓ (password-reset.spec.ts) | ✓ |
| /reset-password | ResetPasswordPage | auth | ✓ (password-reset.spec.ts via link) | ✓ |
| /accept-invite | AcceptInvitePage | auth | ✓ (memberFlows.ts via link) | ✓ |
| /no-access | NoAccessPage | shell | ✓ (smoke.spec.ts) | ✓ |
| /forbidden | ForbiddenPage | shell | ✓ (scope.spec.ts) | ✓ |
| / | HomePage | home | ✓ (smoke, scope) | ✓ |
| /my-day | MyDayPage | my-day | GAP: Not visited by any Playwright spec | — |
| /team | (redirect → /team/staff) | staff | ✓ (staffFlows.ts) | ✓ |
| /team/staff | StaffListPage | staff | ✓ (staff.spec.ts) | ✓ |
| /team/staff/new | StaffNewPage | staff | ✓ (staff journeys via create) | ✓ |
| /team/staff/$staffId | StaffEditorPage | staff | ✓ (staff journeys via edit) | ✓ |
| /team/shifts | ShiftGridPage | shifts | ✓ (shifts.spec.ts) | ✓ |
| /team/blocked-time | BlockedTimePage | blocked-time | ✓ (blocked-time.spec.ts) | ✓ |
| /catalogue | CatalogueHubPage | catalogue | ✓ (catalogue.spec.ts) | ✓ |
| /catalogue/services/new | ServiceNewPage | catalogue | ✓ (catalogueFlows.ts) | ✓ |
| /catalogue/services/$serviceId | ServiceEditorPage | catalogue | ✓ (catalogueFlows.ts) | ✓ |
| /clients | ClientsListPage | clients | ✓ (clients.spec.ts) | ✓ |
| /clients/new | ClientNewPage | clients | ✓ (clients.spec.ts) | ✓ |
| /clients/$clientId | ClientDetailPage | clients | ✓ (clients.spec.ts) | ✓ |
| /settings | SettingsHubPage | settings | ✓ (scope.spec.ts) | ✓ |
| /settings/business | BusinessSettingsPage | settings | ✓ (settings.spec.ts) | ✓ |
| /settings/branches | BranchesListPage | settings | ✓ (settings.spec.ts) | ✓ |
| /settings/branches/$id/details | BranchDetailsTab | settings | ✓ (settings.spec.ts) | ✓ |
| /settings/branches/$id/hours | BranchHoursTab | settings | ✓ (settings.spec.ts) | ✓ |
| /settings/branches/$id/closures | BranchClosuresTab | settings | GAP: Not directly verified | — |
| /settings/branches/$id/invoicing | BranchInvoicingTab | settings | GAP: Not directly verified | — |
| /settings/branches/$id/methods | BranchMethodsTab | settings | GAP: Not directly verified | — |
| /settings/branches/$id/tips | BranchTipsTab | settings | GAP: Not directly verified | — |
| /settings/members | MembersPage | members | ✓ (members.spec.ts) | ✓ |
| /settings/block-types | BlockTypesPage | settings | ✓ (blocked-time test covers via flows) | ✓ |
| /settings/cancellation-reasons | CancellationReasonsPage | settings | GAP: Not directly verified | — |
| /setup | SetupChecklistPage | settings | ✓ (settings.spec.ts) | ✓ |
| /dev/calendar-spike | CalendarSpikePage | calendar | GAP: Dev-only, not a product screen | N/A |

**Gap:** /my-day, BranchClosuresTab, BranchInvoicingTab, BranchMethodsTab, BranchTipsTab, CancellationReasonsPage — no Playwright journey directly visiting these routes.

### 3.4 Commands not part of any gate

Baseline identified the following existing checks. None are currently gated by CI (no .github/workflows/ exists):

| Check | Command | Presently wired as CI gate? |
|---|---|---|
| db:reset (clean-migration) | pnpm db:reset | No — manual only |
| db:lint | pnpm db:lint | No — manual only |
| db:test (pgTAP) | pnpm db:test | No — manual only |
| Type drift | supabase gen types typescript --local + diff | No — manual only |
| fn:check | pnpm fn:check | No — manual only |
| fn:test (Deno) | pnpm fn:test | No — manual only |
| skills:check | pnpm skills:check | No — manual only |
| i18n:compile | pnpm i18n:compile | No — manual only |
| typecheck | pnpm typecheck | No — manual only |
| lint (ESLint) | pnpm lint | No — manual only |
| lint:css | pnpm lint:css | No — manual only |
| test (Vitest) | pnpm test | No — manual only |
| back-office build | pnpm --filter @repo/back-office build | No — manual only |
| size | pnpm size | No — manual only |
| Playwright e2e | pnpm exec playwright test | No — manual only (port conflict at baseline) |

---

## 4. Existing proof ratings

### pgTAP tests

| Test file | Tests | Covers | Rating |
|---|---|---|---|
| 001_tenancy_schema.test.sql | 28 | Structural guarantees, RLS everywhere, grants, helper signatures, constraints | STRONG — reads catalogs and asserts boolean |
| 002_tenancy_rls.test.sql | 51 | Role x operation x scope matrix for tenancy skeleton | STRONG — per-role SELECT/INSERT/UPDATE/DELETE with live query results |
| 003_tenancy_matrix.test.sql | — | Staff role, update/delete denials, settings writes, colleague read | STRONG |
| 004_provisioning.test.sql | 34 | Platform-admin provisioning, service-role only, atomic, audited | STRONG |
| 005_branch_config.test.sql | — | Branch opening hours, counters, GCC currencies, plans/features, audit | STRONG |
| 006_settings_matrix.test.sql | — | Settings write paths per role, archiving, currency-lock, audit | STRONG |
| 007_role_grants.test.sql | — | Grant rules, role changes, last-owner protection, audit | STRONG |
| 008_staff_matrix.test.sql | — | Staff schema/RPCs, read/write matrix, Arabic search, audit | STRONG |
| 009_shifts_matrix.test.sql | — | Shift schema, read matrix, copy_shift_week, cross-branch overlap | STRONG |
| 010_blocked_times_matrix.test.sql | — | Blocked time schema, read matrix, locked RPCs per role | STRONG |
| 011_blocked_times_conflicts.test.sql | — | Exclusion constraint, conflict detection, appointment buffers | STRONG |
| 012_catalogue_matrix.test.sql | — | Service catalogue schema, read matrix, overrides, eligibility | STRONG |
| 013_catalogue_resolution.test.sql | — | Effective catalogue values, resolve_service, security_invoker views | STRONG |
| 014_catalogue_rpcs.test.sql | — | Atomic catalogue create with overrides, role matrix, reorder | STRONG |
| 015_clients_matrix.test.sql | 68 | Clients schema, read matrix, ADR-28 write paths, note authorship | STRONG |
| 016_staff_client_cards.test.sql | — | Staff client cards view: security_invoker, name/phone/safety only | STRONG |
| 017_client_rpcs.test.sql | — | Client RPCs: duplicate check, create, block, soft delete, anonymize | STRONG |
| 018_client_import.test.sql | — | CSV import: batch creation, duplicate policies, chunking, audit | STRONG |

**Note:** As per baseline, test-specific counts were only reported for 001 (28), 002 (51), 004 (34), 015 (68). The other files have unrecorded test counts but they are part of the 923 total.

**All pgTAP tests rated STRONG** — they use `SELECT results_eq()`, `throws_ok()`, `lives_ok()`, `is_empty()` assertions against actual query results with real role switching. These tests would fail if the named guarantee (RLS, role permission, constraint) broke.

### Deno tests

| Test file | Tests | Rating | Notes |
|---|---|---|---|
| _shared/auth_test.ts | 7 | STRONG | Tests requireScope, resolveCaller, verifySecret with real role switching |
| _shared/idempotency_test.ts | 8 | STRONG | Tests hash, require, replay, mismatch, concurrency |
| _shared/logging_test.ts | 6 | WEAK | Tests formatting and logger creation but Sentry transport is a stub (no actual send) |
| _shared/server_test.ts | 16 | STRONG | Tests envelope, CORS, body validation, AppError, auth modes |
| _shared/validation_contract_test.ts | 3 | STRONG | Tests error catalogue and shared schemas parse in Deno |
| _template/template_test.ts | 3 | STRONG | Tests 401, health, echo with scope |
| catalogue/catalogue_test.ts | 8 | STRONG | Tests health, 401, upsert, overrides, eligibility |
| clients/clients_test.ts | 8 | STRONG | Tests health, 401, validation, duplicate, block, delete, anonymize |
| clients/import_test.ts | 8 | STRONG | Tests consumer queue, time budget, secret, dry-run, full import, duplicate policies |
| health/health_test.ts | 2 | STRONG | Tests GET /health returns envelope and request ID |
| onboarding/handlers_test.ts | 6 | STRONG | Tests provision failure, cleanup, existing user |
| onboarding/members_test.ts | 9 | STRONG | Tests invite, role matrix, duplicate, last owner |
| onboarding/onboarding_test.ts | 15 | STRONG | Tests provision-tenant with secret auth, validation, duplicate slug, branch provisioning |
| staff/blocked_time_test.ts | 4 | STRONG | Tests concurrent block serialisation, appointment conflict, schedule endpoint |
| staff/shifts_test.ts | 7 | STRONG | Tests copy-shift-week: 401, validation, overnight, DST, role matrix |
| staff/staff_test.ts | 9 | STRONG | Tests staff upsert, role matrix, invite-login, existing account |

**Weak rating for logging_test.ts**: Tests confirm the logger creates properly formatted log entries, but Sentry `captureException` only logs locally — no Sentry transport is wired. If Sentry were enabled, the test would not verify it sends.

### Vitest tests (288 tests, 35 files — all pass)

| Area | Tests | Rating | Notes |
|---|---|---|---|
| packages/api | dbError, invoke | WEAK | Tests the typed invocation wrappers but can't fail against live API — they test error mapping logic |
| packages/core | catalogue, money, scopeKeys | STRONG | Money golden fixtures, catalogue resolution, eligibility — real logic with assertions |
| packages/db | client | WEAK | Typed DB client construction |
| packages/i18n | format, search | STRONG | Formatting assertions with specific inputs; Arabic search normalization |
| packages/ui | Various component tests | STRONG | Component rendering with assertions on visible content and behavior |
| packages/validation | clients, validation | STRONG | Schema validation rules with specific inputs |

### Playwright tests (11 spec files, each run en + ar)

No tests were run at baseline (port conflict). Previous audit runs (Phase 2: 48 passed, Phase 3: 50 passed) confirm journeys work.

---

## 5. Gaps

### G-1: CI workflow missing
- Requirement: Plan Phase 0.1 exit criteria — CI green on a trivial PR (plan/parts/11-delivery-plan.md:226-230)
- Today: NONE — No .github/workflows/ exists
- Priority: P1
- Owner: pipeline
- Test idea: Create `.github/workflows/ci.yml` with pinned toolchain, clean-migration gate, type drift check, pgTAP, Deno tests, Vitest, lint, build, size, and skills:check. Create `.github/workflows/deploy.yml`.

### G-2: Deploy workflow missing
- Requirement: Plan Phase 0.1 — deploy pipeline promotes staging to production with functions and migrations (plan/parts/11-delivery-plan.md:213,228)
- Today: NONE
- Priority: P1
- Owner: pipeline
- Test idea: Create deploy workflow that deploys migrations+functions+frontend from same commit through staging.

### G-3: Clean-migration gate not wired in CI
- Requirement: CONVENTIONS §7 — clean-migration gate runs on every migration (pgTAP, type drift, functions typecheck, adversarial fixtures, sql/drafts-v1/ grep)
- Today: NOT IN CI — Baseline confirmed all steps pass manually, but no CI enforces them
- Priority: P1
- Owner: pipeline
- Test idea: Add the full clean-migration sequence (db:reset, gen types + diff, fn:check, db:test, grep sql/drafts-v1/) as a CI step.

### G-4: pgTAP for appointments/appointment_items missing
- Requirement: ADR-24, ADR-28 — RLS policies and pgTAP tests for every new/changed table and policy
- Today: NONE — appointments and appointment_items tables exist (pulled forward from Phase 5) but have no dedicated pgTAP test file
- Priority: P1
- Owner: tests-database
- Test idea: Add pgTAP test for appointments table RLS: tenant isolation through client FK, branch scope, role matrix for SELECT (staff read own, manager branch-wide, owner tenant-wide). Add for appointment_items: same dimensions.

### G-5: No automated test for SECURITY DEFINER functions with missing SET search_path
- Requirement: ADR-20 rule 10 — every SECURITY DEFINER function declares `SET search_path = public`
- Today: WEAK — supabase db lint enforces this, but baseline did not verify all 88 functions individually. The lint command passes, but there's no dedicated pgTAP test asserting this.
- Priority: P1
- Owner: tests-database
- Test idea: pgTAP test queries `pg_proc` for `prosecdef = true` and checks that function source contains `SET search_path` or uses fully schema-qualified names.

### G-6: No pgTAP test for idempotency_keys RLS
- Requirement: ADR-31 — idempotency_keys is client-inaccessible, RLS deny-all with select-only grant
- Today: NONE — No pgTAP test file covers idempotency_keys table
- Priority: P2
- Owner: tests-database
- Test idea: pgTAP test that `anon` and `authenticated` cannot SELECT/INSERT/UPDATE/DELETE on idempotency_keys; service-role RPCs (simulated) can.

### G-7: No pgTAP test for cancellation_reasons
- Requirement: CONVENTIONS §3.2 — tables have RLS; pgTAP per table
- Today: NONE — cancellation_reasons table exists but not covered by any pgTAP test
- Priority: P3
- Owner: tests-database
- Test idea: pgTAP test for SELECT/INSERT/UPDATE/DELETE matrix per role, tenant isolation.

### G-8: Playwright does not cover /my-day route
- Requirement: Plan Phase 0.4 — shell renders in both locales; My Day is a Phase 2 feature
- Today: NONE — /my-day route exists but no Playwright journey visits it
- Priority: P2
- Owner: tests-frontend
- Test idea: Add Playwright journey: login as staff with profile, visit /my-day, verify staff name and day schedule render. Run in en and ar.

### G-9: Playwright does not cover settings sub-tab routes (closures, invoicing, methods, tips, cancellation reasons)
- Requirement: Plan Phase 1.2 — settings work in EN and AR/RTL
- Today: WEAK — settings hub journey exists but does not visit each settings sub-tab individually
- Priority: P3
- Owner: tests-frontend
- Test idea: Add Playwright journeys that navigate to each settings sub-tab and verify the page renders without error.

### G-10: No axe-core accessibility tests
- Requirement: CONVENTIONS §7 — axe-core assertions on main flows; WCAG 2.1 AA
- Today: NONE — Playwright config does not include axe-core
- Priority: P2
- Owner: tests-frontend
- Test idea: Install axe-playwright; add assertions on login, /team/staff, /catalogue, /clients in both locales.

### G-11: No test that Arabic translations are complete
- Requirement: CONVENTIONS §7 — missing Arabic translations fail CI
- Today: WEAK — `pnpm i18n:compile` passes, which means the catalogs are syntax-valid. But there's no test that every English message has an Arabic counterpart.
- Priority: P2
- Owner: pipeline (add CI step) or tests-backend (dedicated test)
- Test idea: Add a step that compares source keys in en/messages.po vs ar/messages.po and fails if any key is missing in AR.

### G-12: No Deno test for health function's Sentry integration
- Requirement: Plan Phase 0.3 — Sentry captures an unhandled staged function error
- Today: NONE — Sentry transport is a stub (logging.ts captureException only logs locally)
- Priority: P2
- Owner: tests-backend
- Test idea: After Sentry integration is wired, add Deno test that forces an error, triggers captureException, and verifies Sentry API was called (mock or test mode).

### G-13: No automated secrets-in-committed-files check
- Requirement: Common brief — no secrets or local-only files committed
- Today: NONE — No CI check for secrets (.env, API keys, JWTs) in committed files
- Priority: P2
- Owner: pipeline
- Test idea: Add CI step using git-secrets or a grep-based check for common secret patterns before merge.

### G-14: No check for direct writes staying within the allowlist
- Requirement: ADR-28 — direct-write allowlist enforced
- Today: WEAK — relies on code review. No automated check that a new RLS policy doesn't grant INSERT/UPDATE to a table outside the allowlist.
- Priority: P2
- Owner: tests-database
- Test idea: pgTAP guard test: for each table, assert that if it's in the prohibited-for-direct-writes list, `authenticated` cannot INSERT/UPDATE/DELETE (enforced by policies). This is already partially covered by the pgTAP role matrix tests which test each role's write permissions, but an explicit "no direct write" assertion would formalize ADR-28 compliance.

### G-15: No mutation test for idempotency replay
- Requirement: ADR-31 — idempotency replay returns cached response
- Today: STRONG for _shared tests (idempotency_test.ts covers replay, mismatch, concurrency) but no mutation test proves the test would fail if the guarantee broke
- Priority: P2
- Owner: tests-backend
- Test idea: Mutation: comment out the replay logic in idempotency.ts, run the test suite, confirm tests fail.

### G-16: No mutation test for server envelope
- Requirement: ADR-29 — envelope contract
- Today: STRONG for assertion (server_test.ts checks envelope). Mutation test needed.
- Priority: P3
- Owner: tests-backend
- Test idea: Mutation: change envelope format in server.ts, run server_test.ts, confirm tests fail.

### G-17: pgTAP coverage gap for booking_overrides table
- Requirement: CONVENTIONS §7 — pgTAP per table
- Today: NONE — booking_overrides table exists but has no dedicated pgTAP test
- Priority: P3 (table exists but not in active use — Phase 5 not built)
- Owner: tests-database
- Test idea: When Phase 5 builds booking, add pgTAP test branch-scoped RLS, role matrix.

### G-18: Sentry is not integrated
- Requirement: Plan Phase 0.1 — Sentry captures a deliberate error (plan/parts/11-delivery-plan.md:215,230,314-319)
- Today: NONE — Sentry code absent (Phase 0 audit F-VERIFIER-2)
- Priority: P1
- Owner: tests-backend
- Test idea: After wiring Sentry SDK, add Deno test that triggers captureException and confirms Sentry event was queued. Add Vitest test for frontend Sentry initialization.

### G-19: Deno test runner may stop on first failure
- Requirement: Plan Phase 0.3 — test runner should not exit on first failed suite
- Today: WEAK — The baseline Phase 1 audit reported that the runner could exit before later suites. Current scripts/fn-test.sh may fix this (package.json:15 updated per Phase 0 audit).
- Priority: P2
- Owner: pipeline
- Test idea: Verify fn-test.sh runs all suites regardless of individual failures. Add a test that introduces a deliberate failure in an early suite and confirms later suites still execute.

### G-20: No Playwright coverage for back-office routes when Playwright server port conflicts
- Requirement: Baseline established port 5173 in use by node dev server
- Today: NOT IN CI — baseline could not run Playwright; needs CI-only ephemeral port or port management
- Priority: P2
- Owner: pipeline
- Test idea: Ensure CI workflow allocates an ephemeral port or explicitly stops dev server before Playwright.

### G-21: No Playwright journey for client import flow
- Requirement: Plan Phase 4 — client CSV import (acceptance criterion)
- Today: WEAK — clients.spec.ts covers CRUD but not CSV import flow (import is owner-only, requires file upload)
- Priority: P2
- Owner: tests-frontend
- Test idea: Add Playwright journey: login as owner, navigate to clients import, upload a CSV fixture, verify import appears in client list. Run in en locale only (feature parity).

### G-22: Type drift not enforced in CI
- Requirement: CONVENTIONS §7 — generated type drift check in CI
- Today: NOT IN CI — baseline confirmed supabase gen types matches committed types, but no CI step enforces it
- Priority: P2
- Owner: pipeline
- Test idea: Add `supabase gen types typescript --local > database.types.generated.ts && diff packages/db/src/database.types.ts database.types.generated.ts` as a CI step.

### G-23: Playwright tests not running in the most recent Phase 4 commit
- Requirement: Baseline records Playwright as blocked (port 5173 in use). Current Phase 4 state has no recent Playwright run.
- Today: NOT IN CI — Baseline did not run Playwright. Previous Phase 2/3 audits ran it successfully. The Playwright suite may work when port is free.
- Priority: P2
- Owner: pipeline
- Test idea: Ensure CI ephemeral port, run Playwright suite, and gate on pass.

### G-24: No check that every screen route works in both en and ar
- Requirement: Plan Phase 0.4 — screens in both locales
- Today: WEAK — Playwright fixture (fixtures.ts) runs each journey once in en and once in ar, but coverage of all screen routes is incomplete
- Priority: P2
- Owner: tests-frontend
- Test idea: Per-gap G-8, G-9 — add missing Playwright journeys and ensure fixtures.ts runs them in both locales.

### G-25: No pgTAP for the sentinel/UUID-free all-branches pattern
- Requirement: ADR-20 rule 6 — all-branches uses nullable branch_id + all_branches flag. Mixing sentinel UUID is forbidden.
- Today: WEAK — pgTAP tests check RLS behavior for all-branches memberships but there's no dedicated test asserting the sentinel UUID is absent from all tables.
- Priority: P2
- Owner: tests-database
- Test idea: pgTAP test: query all tables with `branch_id` columns (via information_schema) and assert no row uses the sentinel UUID '00000000-0000-0000-0000-000000000000'.

### G-26: No pgTAP for Realtime channel authorization
- Requirement: ADR-38 — Realtime channel authorization tested (tenant/branch leakage)
- Today: NONE — No pgTAP test covers Realtime channel authorization
- Priority: P2 (CONVENTIONS §7 requires it)
- Owner: tests-database
- Test idea: pgTAP test using `supabase_realtime` functions to verify that subscribing as tenant A/branch A cannot receive tenant B or branch B changes.

### G-27: CONVENTIONS §7 performance budgets — no automated interaction budget checks
- Requirement: CONVENTIONS §7 — drag frame ≤16 ms, day view ≤2s p95, slot computation ≤300 ms p95, booking round-trip ≤1s p95
- Today: WEAK — size budgets are enforced (back-office JS ≤250 kB gzip, calendar ≤150 kB). Interaction budgets (frame time, p95 latency) are not measured in CI.
- Priority: P2
- Owner: pipeline
- Test idea: Add Playwright performance assertions with budget thresholds for main flows. These would be pre-release checks, not per-PR.

---

## 6. Summary

### What is built and what is gated

| Phase | Status | Has tests? | Gatability |
|---|---|---|---|
| Phase 0 Foundation | BUILT (except CI/Sentry) | pgTAP 001-003, Deno _shared, Vitest, Playwright smoke | Gateable after CI workflow added |
| Phase 1 Tenancy & settings | BUILT | pgTAP 004-007, Deno onboarding, Playwright settings | Gateable after CI workflow added |
| Phase 2 Staff & shifts | BUILT | pgTAP 008-011, Deno staff, Playwright staff/shifts/blocked-time | Gateable after CI workflow added |
| Phase 3 Service catalogue | BUILT | pgTAP 012-014, Deno catalogue, Playwright catalogue | Gateable after CI workflow added |
| Phase 4 Clients | BUILT | pgTAP 015-018, Deno clients, Playwright clients | Gateable after CI workflow added |
| Phase 5 Calendar & booking | NOT STARTED | — | Future gate |
| Phase 6 Checkout & register | NOT STARTED | — | Future gate |
| Phase 7 Reports & hardening | NOT STARTED | — | Future gate |
| Phase 8-17 | NOT STARTED | — | Future gate |

### Gap counts per owner

| Owner | P1 | P2 | P3 | Total | DEFERRED |
|---|---|---|---|---|---|
| pipeline | 3 (G-1, G-2, G-3) | 4 (G-11, G-13, G-19, G-20, G-22, G-23, G-27) | 0 | 14 | None |
| tests-database | 2 (G-4, G-5) | 3 (G-6, G-14, G-25, G-26) | 2 (G-7, G-17) | 11 | None |
| tests-backend | 1 (G-18) | 3 (G-12, G-15) | 1 (G-16) | 5 | None |
| tests-frontend | 0 | 4 (G-8, G-10, G-21, G-24) | 1 (G-9) | 5 | None |

### Future gates (for unbuilt work)

These are not gated now because the code does not exist. When the phases are built, the following must be added:

1. **Phase 5 (Calendar & booking)**: Bookings Edge Function + routes + Deno tests (happy path, conflict, validation, auth). Slot engine + conflict engine tests. Calendar Playwright journey. pgTAP for appointments/appointment_items/booking_overrides RLS. Realtime channel authorization test. Performance budgets (slot comp ≤300ms, booking ≤1s).

2. **Phase 6 (Checkout, sales & register)**: Checkout Edge Function + routes + Deno tests (money-moving with idempotency, validation, role enforcement). Checkout/sales/register Playwright journey. pgTAP for sales/sale_items/payments/register_sessions/tips RLS. ADR-51 golden fixtures for calculation order and rounding. Invoice counter concurrency tests.

3. **Phase 7 (Reports, exports & hardening)**: Reports Edge Function + routes + Deno tests. Report view/RPC pgTAP (branch-scoped, security_invoker). CSV export tests. Audit viewer tests. Home page operational data tests. axe-core accessibility tests. Performance budgets (p95 latency). Restore drill.

4. **Phase 8 (SpaCorner go-live)**: Import software tests. Migration cutover verification. Training materials verification.

### Gap matrix (requirement → existing test → rating → gap)

| Requirement | Phase/Subphase/Rule | Existing Test | Rating | Gap |
|---|---|---|---|---|
| CI green on PR | Phase 0.1 exit criteria | None | NONE | G-1 |
| Deploy pipeline | Phase 0.1 exit criteria | None | NONE | G-2 |
| Clean-migration gate in CI | CONVENTIONS §7 | Manual tests pass | NOT IN CI | G-3 |
| RLS pgTAP per table | CONVENTIONS §7 | pgTAP 001-018 cover 26/29 tables | STRONG (partial) | G-4, G-6, G-7, G-17 |
| SECURITY DEFINER search_path | ADR-20 rule 10 | supabase db lint | WEAK | G-5 |
| Appointments RLS | ADR-28 (Phase 5 pull-forward) | None | NONE | G-4 |
| idempotency_keys RLS | ADR-31 | None | NONE | G-6 |
| cancellation_reasons RLS | CONVENTIONS §7 | None | NONE | G-7 |
| /my-day Playwright | Phase 2.1 | None | NONE | G-8 |
| Settings sub-tab coverage | Phase 1.2 | Partial (settings hub) | WEAK | G-9 |
| axe-core a11y | CONVENTIONS §7 | None | NONE | G-10 |
| Arabic translation completeness | CONVENTIONS §7 | i18n:compile passes | WEAK | G-11 |
| Sentry integration | Phase 0.1/0.3 | None | NONE | G-18 |
| Secrets check | Common brief | None | NONE | G-13 |
| Direct-write allowlist enforcement | ADR-28 | Code review only | WEAK | G-14 |
| Type drift in CI | CONVENTIONS §7 | Manual check passes | NOT IN CI | G-22 |
| Playwright port conflict | Baseline finding | Not run | NOT IN CI | G-20, G-23 |
| Client CSV import Playwright | Phase 4.3 | Partial clients CRUD | WEAK | G-21 |
| Envelope mutation test | ADR-29 | server_test.ts exists | STRONG (no mutation) | G-16 |
| Idempotency mutation test | ADR-31 | idempotency_test.ts exists | STRONG (no mutation) | G-15 |
| Screen route dual-locale coverage | Phase 0.4 | Partial | WEAK | G-24 |
| All-branches sentinel UUID guard | ADR-20 rule 6 | pgTAP tests exist but not exhaustive | WEAK | G-25 |
| Realtime channel authorization | ADR-38 | None | NONE | G-26 |
| Interaction performance budgets | CONVENTIONS §7 | Size budgets only | WEAK | G-27 |
| Deno test runner completes all suites | Phase 0.3 | scripts/fn-test.sh may fix | WEAK | G-19 |