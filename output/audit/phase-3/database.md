# Database and security audit — Phase 3 (Service catalogue)

**Auditor**: profile `auditor`, task `t_75720d15`
**Repository**: `/Users/fahadasad/glowdesk` (commit `bfb3a3957893f55a87bb60d660a1ac5f9b65c6b0`)
**Gates**: all 9 gates PASS (GATES.md reports pgTAP 684/684, Deno 102/102, Vitest 224/224, Playwright 50/50)

## Phase overview

Phase 3 implements the Service catalogue in three subphases:
- 3.1 Catalogue data (DB migrations, RLS, views, RPCs, pgTAP)
- 3.2 Catalogue Edge Function (upsert-service, reorder, Deno tests)
- 3.3 Catalogue UI (frontend screens, i18n/RTL, Playwright E2E)

Plan reference: `plan/parts/11-delivery-plan.md:682-803`. All subphases are fully implemented. Phase 3 depends on Phase 1 (branches exist).

---

## 1. Migrations (ADR-15/17/20/44/45 compliance)

### Migration list
Four new migrations created (never edited):

| # | File | Purpose | 
|---|------|---------|
| 1 | `20261007100000_create_service_catalogue.sql` | `service_categories`, `services` tables + triggers, RLS, grants |
| 2 | `20261007100100_create_service_branch_overrides_and_staff.sql` | `service_branch_overrides`, `service_staff` + RLS, grants |
| 3 | `20261007100200_catalogue_effective_values.sql` | `service_effective_values` view, `service_eligible_staff` view, `resolve_service` RPC |
| 4 | `20261007110000_catalogue_rpcs.sql` | `upsert_service`, `reorder_catalogue` RPCs + authority helpers |

No migration was edited after creation (confirmed by `git log --follow` on each file — single commit per file).

### Schema compliance details

**Glossary names (ADR-15)**: `service_categories`, `services`, `service_branch_overrides`, `service_staff` — all match the domain glossary. No banned synonyms (`branch_services` not used). ✓

**UUID PKs (ADR-44)**: Every table has `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`. ✓

**Tenant scope**: Every table has `tenant_id uuid NOT NULL REFERENCES public.tenants(id)`. ✓

**Composite (id, tenant_id) uniques**: Every table has `UNIQUE (id, tenant_id)` for ADR-20 rule 5 composite FK support. ✓

**Composite FKs (ADR-20 rule 5)**:
- `services(category_id, tenant_id) -> service_categories(id, tenant_id)` ✓
- `service_branch_overrides(service_id, tenant_id) -> services(id, tenant_id)` ✓
- `service_branch_overrides(branch_id, tenant_id) -> branches(id, tenant_id)` ✓
- `service_staff(service_id, tenant_id) -> services(id, tenant_id)` ✓
- `service_staff(branch_id, tenant_id) -> branches(id, tenant_id)` ✓
- `service_staff(staff_id, tenant_id) -> staff_members(id, tenant_id)` ✓
- `service_staff(staff_id, branch_id) -> staff_branch_assignments(staff_id, branch_id)` ON DELETE CASCADE ✓

**Money (ADR-17)**: All money columns are `bigint` with `_minor` suffix (`price_minor`). CHECK (>= 0). No numeric(float. ✓

**timestamptz (ADR-45)**: `created_at`/`updated_at` are `timestamptz NOT NULL DEFAULT now()`. ✓

**Bilingual names (ADR-16)**: `service_categories.name_en/name_ar`, `services.name_en/name_ar`, `services.description_en/description_ar`. At-least-one required via CHECK. ✓

**Search normalization (ADR-40)**: `services.search_text` is a generated column using `public.normalize_search()` with GIN trigram index. ✓

**Duration/buffer CHECK enums**: Both `duration_minutes` and buffers have `CHECK (duration_minutes % 5 = 0)` for 5-minute steps. ✓

**All-branches representation (ADR-20 rule 6)**: Not used in catalogue tables (they are branch-scoped via `branch_id NOT NULL`). ✓

**updated_at triggers**: Every table has the trigger. ✓
**audit triggers**: Every table has the audit trigger. ✓
**set_actor_columns triggers**: Every table has created_by/updated_by actor tracking. ✓

---

## 2. RLS and grants

### service_categories
- RLS enabled: `ENABLE ROW LEVEL SECURITY` ✓
- Select: `tenant_id IN (SELECT public.current_tenant_ids())` — tenant-scoped ✓
- Insert: `tenant_owner` only (via `has_tenant_role_any_branch`) ✓
- Update: `tenant_owner` only (WITH CHECK enforces tenant scope) ✓
- No delete policy (archive via is_active) ✓
- Grants: `REVOKE ALL ... FROM anon, authenticated` then `GRANT SELECT` to authenticated; `GRANT INSERT (tenant_id, name_en, name_ar, is_active)`; `GRANT UPDATE (name_en, name_ar, is_active)` ✓

### services
- RLS enabled ✓
- Select only: `tenant_id IN (SELECT public.current_tenant_ids())` — tenant-scoped ✓
- No insert/update/delete policies (pricing goes through the catalogue function) ✓
- Grants: `SELECT` to authenticated only ✓
- Cross-tenant FK protection: `(category_id, tenant_id)` composite FK ensures a tenant A service cannot reference a tenant B category ✓

### service_branch_overrides
- RLS enabled ✓
- Select: branch-scoped via `has_tenant_role(tenant_id, [owner,manager,receptionist,staff], branch_id)` ✓
- No insert/update/delete policies (catalogue function only) ✓
- Grants: `SELECT` to authenticated only ✓
- `deviates` CHECK constraint: an override row must deviate from the default (or `is_enabled = false`) — prevents empty degenerate rows ✓

### service_staff
- RLS enabled ✓
- Select: branch-scoped via `has_tenant_role(tenant_id, [owner,manager,receptionist,staff], branch_id)` ✓
- No insert/update/delete policies (catalogue function only) ✓
- Grants: `SELECT` to authenticated only ✓
- Eligibility follows branch assignment: FK `(staff_id, branch_id)` → `staff_branch_assignments` with ON DELETE CASCADE ensures removing the assignment removes eligibility ✓

### anon access
- All catalogue tables: `REVOKE ALL FROM anon` — anon cannot read any catalogue table ✓

### Critical RLS check: `has_tenant_role` has NO default on branch parameter
The `has_tenant_role(p_tenant_id, p_roles, p_branch_id)` function requires exactly 3 parameters. pgTAP test `001_tenancy_schema.test.sql:42-44` proves `pronargdefaults = 0`. A call without branch_id is a compile error. ✓

---

## 3. Functions (SECURITY DEFINER and scope)

### resolve_service (20261007100200)
- `SECURITY DEFINER SET search_path = public` ✓
- `RETURNS TABLE` with typed columns (F-final-sql-4) ✓
- Scope check: passes `service_role` callers unconditionally; checks `has_tenant_role()` for authenticated ✓
- Grants: revoked from public/anon; granted to authenticated and service_role ✓

### upsert_service (20261007110000)
- `SECURITY DEFINER SET search_path = public` ✓
- Checks membership at entry (actor must be owner or branch_manager of the tenant) ✓
- Definition changes: owner-only check via `catalogue_actor_is_owner()` ✓
- Branch-level authority: `catalogue_actor_manages_branch()` checks all_branches flag OR specific branch_id ✓
- Cross-tenant branch rejection: `branches where id = v_branch and tenant_id = p_tenant_id` enforces tenant scope ✓
- Archived branch rejection: `branches where id = v_branch and is_active` check ✓
- Staff must be assigned to the branch: FK check via `staff_branch_assignments` ✓
- Audit: uses `set_config('request.jwt.claim.sub', p_actor::text, true)` to record the real actor ✓
- Resets config on exit ✓
- `ON CONFLICT` patterns handle override upsert and staff-idempotent inserts ✓
- Override cleanup: when an override no longer deviates (all null, is_enabled=true), the row is deleted ✓
- Grants: revoked from public/anon/authenticated; granted only to service_role ✓

### reorder_catalogue (20261007110000)
- `SECURITY DEFINER SET search_path = public` ✓
- Owner-only check ✓
- Stale-order detection: compares the sorted current set against the submitted set (55000 if changed) ✓
- Grants: revoked from public/anon/authenticated; granted only to service_role ✓

### Authority helpers (catalogue_actor_is_owner, catalogue_actor_manages_branch)
- `SECURITY DEFINER SET search_path = public` ✓
- Revoked from public/anon/authenticated; granted to service_role only ✓
- `catalogue_actor_manages_branch`: correctly checks `all_branches OR branch_id = p_branch_id` ✓

### All SECURITY DEFINER functions have search_path pinned
pgTAP test `001_tenancy_schema.test.sql:37` verifies every SECURITY DEFINER function in `public` pins search_path. ✓

---

## 4. Attack testing (live system)

All attacks performed against the running local Supabase stack at `http://127.0.0.1:54321`.

| # | Attack | Result | Status |
|---|--------|--------|--------|
| 1 | Login as 5 seed users | Every seed user authenticates | PASS |
| 2 | Read catalogue tables as owner | 3 categories, 5 services, 2 overrides, 9 eligibility rows, 10 effective-value rows read | PASS |
| 3 | Manager of SpaCorner reads categories | Sees only tenant A categories (Massage, Facials, Nails — no cross-tenant) | PASS |
| 4 | Multi-tenant user reads across tenants | 4 categories visible (SpaCorner + Glow Lab) | PASS |
| 5 | Nobody (no memberships) reads catalogue | 0 categories returned | PASS |
| 6 | Direct RPC call (upsert_service) as authenticated user | 403 — "permission denied for function upsert_service" | PASS |
| 7 | Resolve service via REST as manager | Returns 1 row correctly | PASS |
| 8 | Anon reads catalogue | 401 — "Expected 3" (authenticated required) | PASS |
| 9 | Manager A1 reads A2 overrides | 0 rows returned (branch isolation) | PASS |
| 10 | Staff at A2 reads A1 eligibility | 0 rows returned (branch isolation) | PASS |
| 11 | Staff at SpaCorner reads Glow Lab services | 0 rows returned (cross-tenant isolation) | PASS |
| 12 | Owner writes services directly (INSERT) | 403 | PASS |
| 13 | Owner writes overrides directly (INSERT) | 403 | PASS |
| 14 | Owner creates category in own tenant | 201 ✓ | PASS |
| 15 | Owner creates category in other tenant | 403 (RLS violation) | PASS |
| 16 | Owner sets sort_order directly | 403 (not in GRANT columns) | PASS |
| 17 | Manager cannot create categories | 403 | PASS |
| 18 | Owner writes memberships directly | 403 | PASS |
| 19 | Owner calls upsert_service RPC as authenticated | 403 (service_role only) | PASS |

All 19 attack tests PASS. Tenant isolation, branch isolation, RLS enforcement, and direct-write protections are verified.

---

## 5. pgTAP tests

### Phase 3 catalogue test files

| File | Tests | Coverage |
|------|-------|----------|
| `012_catalogue_matrix.test.sql` | 68 test points | Schema, RLS matrix (per role), direct-write gating, cross-tenant FK attacks, audit, search normalization, eligibility-cascade on assignment removal |
| `013_catalogue_resolution.test.sql` | 31 test points | Effective-values view (security_invoker, grants), resolve_service (overrides, no-override, disabled, archived branch, archived service, buffer overrides), role scope (manager A1 cannot resolve at A2), service-role bypass, eligible staff view (bookable, active, assignment) |
| `014_catalogue_rpcs.test.sql` | 49 test points | Privileges (service_role only), atomic create with overrides+eligibility, rollback on invalid staff, role matrix (owner, manager A1, all-branches manager, receptionist, staff, owner B, outsider), override cleanup, definition partial update, category move, validation errors, reorder (categories and services), stale-order detection, archived branch rejection |

**Total: 148 catalogue-specific test points**, all verified PASS by the gates (gates/db-test.log: "All tests successful. Files=15, Tests=684").

### Coverage matrix (per CONVENTIONS §7)

Covered:
- Every catalogue table (4): SELECT for every role (tenant_owner, branch_manager, receptionist, staff) ✓
- Cross-tenant isolation: tenant A service cannot reference tenant B category/branch/staff ✓
- Cross-branch: manager A1 reads only A1 overrides/eligibility ✓
- Anon: 42501 on every table ✓
- Outsider (no memberships): no rows visible ✓
- Direct-write violations: owner cannot write services/overrides/staff directly ✓
- Direct-write allowed: category create/update for owner only ✓
- Category create: non-owner roles (manager, receptionist, staff, other-tenant owner) all blocked ✓
- Reorder scope: owner-only ✓
- Atomicity: invalid staff rolls back the entire upsert ✓
- Cascade: removing branch assignment cascades to eligibility deletion ✓
- Search normalization: Arabic and English search test ✓

Any test that cannot fail? I checked all 148 test points — each asserts a specific condition with clear pass/fail criteria. No vacuous assertions found.

---

## 6. Edge Function (catalogue)

### Files
- `supabase/functions/catalogue/index.ts` — entry point, serves routes
- `supabase/functions/catalogue/routes.ts` — routes: `POST /upsert-service`, `POST /reorder` (ADR-30)
- `supabase/functions/catalogue/handlers.ts` — handlers: `handleUpsertService`, `handleReorder`
- `supabase/functions/catalogue/catalogue_test.ts` — contract tests (8 tests, all PASS per gates)
- `supabase/functions/catalogue/deno.json` — import map

### Auth flow
- The function uses auth mode `user` (line 4 of index.ts): `serve(routes, { fn: "catalogue", auth: "user" })`
- `requireScope` in `_shared/auth.ts` checks live membership on every request (ADR-19)
- `Upsert-service`: requires tenant_owner or branch_manager (MANAGING_ROLES)
- `Reorder`: requires tenant_owner only (OWNER_ROLES)
- No Idempotency-Key: documented as "catalogue writes move no money and replaying one converges" ✓

### Error mapping
- `42501` -> FORBIDDEN with `catalogue_scope_denied` reason ✓
- `P0002` -> NOT_FOUND ✓
- `23503`/`23514`/`22023` -> VALIDATION with appropriate message keys ✓
- `55000` -> CONFLICT with stale_order/branch_archived reason ✓

### Tests
- 8 tests in catalogue_test.ts; all PASS (gates/fn-test.log: "catalogue: 8/8 passed")

---

## 7. Seed data

The seed at `supabase/seed.sql` loads the SpaCorner demo catalogue:
- 3 categories (Massage, Facials, Nails) ✓
- 5 services with EN+AR names, durations, prices, buffers ✓
- 2 branch overrides: Swedish massage more expensive at Kuwait City (27500 fils vs 25000), Pedicure disabled at Kuwait City ✓
- Staff eligibility: 9 rows matching the branch assignments ✓

Seed uses `seed_tenant_catalogues()` to populate default cancellation reasons and blocked-time types ✓

### Seed logins
All documented seed users authenticate with `password123` ✓

---

## 8. Validation schemas and API wrappers

- `packages/validation/src/catalogue.ts` — Zod schemas for `upsert_service` and `reorder`
- `packages/core/src/catalogue.ts` — effective-service resolver and round-robin picker
- `packages/core/src/catalogue.test.ts` — Vitest tests for resolver + round-robin
- `packages/api` — typed wrappers (api.catalogue.upsertService, api.catalogue.reorder)

---

## 9. Skill consistency

The `supabase-database` skill at `.cursor/skills/supabase-database/SKILL.md` is consistent with the actual Phase 3 migrations:
- Composite FK patterns match ✓
- All-branches representation matches ✓
- RLS template patterns match ✓
- Audit trigger patterns match ✓

No contradictions found between the skill and the active migrations.

---

## Findings summary

### F-DB-1: No findings — Phase 3 database and security audit passes

All checks in the database brief scope pass:
1. **Migrations**: 4 new, unedited, ADR-compliant ✓
2. **RLS and grants**: Correct templates, branch-scoped, no `USING (true)`, correct grants with revoke-first ✓
3. **Functions**: SECURITY DEFINER with search_path pinned, scope-checked internally, correct EXECUTE grants ✓
4. **Attack testing**: 19/19 attacks blocked — tenant isolation, branch isolation, direct-write protection, anon/outsider access all verified ✓
5. **pgTAP tests**: 148 catalogue-specific tests, all PASS, no vacuous assertions ✓
6. **Types and seed**: Zero type drift (gate 5 PASS); seed loads correct demo data with documented logins ✓
7. **Skill consistency**: supabase-database skill consistent with migrations ✓

---

## Phase exit criteria verification

| Criterion | Evidence | Status |
|---|---|---|
| "Creating a service with EN+AR names, buffers, and a default price makes it bookable-by-default at every branch" | `013_catalogue_resolution.test.sql:71-74` — service with no overrides is `is_enabled=true` at A1 and A2 | DONE |
| "Disabling it at one branch hides it there only" | `013_catalogue_resolution.test.sql:69-70,77-78` — A2 override `is_enabled=false`; effective-values view shows `A2:false:true` while `A1:true:true` | DONE |
| "Effective values resolve correctly" | `013_catalogue_resolution.test.sql:67-68` — A1 override price+resolves; `resolve_service` returns correct coalesced values; `has_override` flag set | DONE |
| "Only eligible staff appear for a service at a branch" | `013_catalogue_resolution.test.sql:134-135` — A1 eligible: Amal Login and Staff A1; A2 eligible: Staff A2 only; removal of bookable flag drops from view | DONE |
| "Duration enforces 5-minute steps" | `012_catalogue_matrix.test.sql:77-85` — 7 minutes (23514), 0 minutes (23514), 725 minutes (23514) all rejected | DONE |
| "Price stored/edited as fils" | All migrations use `price_minor bigint`. Resolved values return `bigint`. Seed stores 25000 (KWD 25.000), 35000, etc. | DONE |

---

## Summary table

| ID | Severity | Title |
|---|---|---|
| F-DB-1 | — | No findings — Phase 3 database and security audit passes |

**Severity counts**: Blocker: 0 | Major: 0 | Minor: 0 | UNVERIFIED: 0