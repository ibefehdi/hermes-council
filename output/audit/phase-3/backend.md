# Edge Functions and backend audit — Phase 3: Service catalogue

Auditor: auditor | Reviewed by: kanban task t_d8c03ea9
Repository: /Users/fahadasad/glowdesk (read-only)
Head: bfb3a3957893f55a87bb60d660a1ac5f9b65c6b0 ("chore(back-office): add Vercel config with SPA fallback rewrite")
Gate logs: /Users/fahadasad/hermes-council/output/audit/phase-3/gates/
Supabase config.toml verified against API on 127.0.0.1:54321

---

## Checklist

### Subphase 3.1: Catalogue data (2 ew)

| Item | Status | Evidence |
|------|--------|----------|
| DB: service_categories table | DONE | supabase/migrations/20261007100000_create_service_catalogue.sql:10-25 |
| DB: services table (buffers, _minor price, bilingual + search normalization) | DONE | supabase/migrations/20261007100000_create_service_catalogue.sql:62-91 |
| DB: service_branch_overrides (composite FKs; unique (service_id, branch_id)) | DONE | supabase/migrations/20261007100100_create_service_branch_overrides_and_staff.sql:9-37 |
| DB: service_staff | DONE | supabase/migrations/20261007100100_create_service_branch_overrides_and_staff.sql:56-73 |
| RLS: definitions owner-write (branch manager read) | DONE | m/20261007100000:112-132 — owner-only insert/update; authenticated select by tenant membership |
| RLS: overrides owner + branch-manager(branch)-write | DONE | m/20261007100100:96-108 — select-only RLS (branch-scoped) for authenticated; writes go through function RPCs |
| RLS: eligibility same as overrides | DONE | m/20261007100100:103-108 — same branch-scoped select policy |
| Effective-values view WITH (security_invoker = true) | DONE | m/20261007100200:10-28 — service_effective_values view, security_invoker, explicit grants per F-6 |
| Audit triggers on catalogue tables | DONE | Every catalogue table has audit_trigger (m/20261007100000:57-59, m/20261007100100:50-52, etc.) |
| pgTAP: manager A cannot write overrides for branch B | DONE | supabase/tests/014_catalogue_rpcs.test.sql — extensive per-branch role matrix tests (49 plans) |
| pgTAP: receptionist read-only | DONE | supabase/tests/012_catalogue_matrix.test.sql — 68 plans covering read matrix per role |
| resolve_service RPC returns TABLE (F-final-sql-4) | DONE | m/20261007100200:58-85 — RETURNS TABLE with typed columns, no call-site column def needed |
| seed catalogue data sets up categories/services/overrides/eligibility | DONE | supabase/seed.sql:117-153 — SpaCorner catalogue with 3 categories, 5 services, branch overrides, staff eligibility |

### Subphase 3.2: Catalogue function (1 ew)

| Item | Status | Evidence |
|------|--------|----------|
| catalogue/upsert-service Edge Function | DONE | supabase/functions/catalogue/handlers.ts:59-79 — validates body, calls upsert_service RPC, returns serviceId |
| catalogue/reorder Edge Function | DONE | supabase/functions/catalogue/handlers.ts:83-103 — validates body, calls reorder_catalogue RPC, returns ids |
| Contract tests (envelope, validation, scope denial) | DONE | supabase/functions/catalogue/catalogue_test.ts — 8 tests covering health, 401, validation, AC, scope denial, reorder |
| Creating a service with 3 branch overrides and 5 eligible staff in one call succeeds atomically | DONE | catalogue_test.ts:163-198 — AC test creates 3 overrides + 5 staff, verifies effective values and audit |
| Manager of branch A cannot write overrides for branch B | DONE | catalogue_test.ts:217-250 — Hawally manager refused Jahra override, allowed Hawally; definition change also refused for non-owner |
| Deno tests for catalogue transactions pass | DONE | gates/fn-test.log:146-155 — "8 passed, 0 failed" including AC and scope denial |

### Phase-level exit criteria (Edge Functions and backend scope)

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Creating a service with EN+AR names, buffers, and default price | DONE | catalogue_test.ts:106-120 — definition() creates with bilingual names, duration, price, buffers |
| Disabling a service at one branch hides it there only | DONE | catalogue_test.ts:182 — Jahra override is_enabled=false confirmed via effective values view |
| Effective values resolve correctly | DONE | catalogue_test.ts:178-185 — verifies per-branch effective values with and without overrides; Vitest supabase/tests/013_catalogue_resolution.test.sql mirrors same cases |
| Only eligible staff appear for a service at a branch | DONE | packages/core/src/catalogue.ts:87-99 — eligibleStaffAt() pure function; catalogue_test.ts:187-190 verifies 5 distinct eligible staff across 3 branches |
| Duration enforces 5-minute steps | DONE | packages/validation/src/catalogue.ts:21-23 — MINUTE_STEP refinement; m/20261007100000:71 — CHECK (duration_minutes % 5 = 0) |
| Price stored as fils, displayed with 3 decimals | DONE | ADR-17: _minor bigint columns throughout; form schemas use major-unit strings parsed at the boundary (catalogue.ts:133) |

---

## Findings

### F-BE-1: Reorder endpoint lacks idempotency-key protection (minor)

- Severity: minor
- Location: supabase/functions/catalogue/handlers.ts:83-103
- Problem: The reorder-catalogue and upsert-service functions do not accept or validate an Idempotency-Key header. While catalogue writes do not move money (the phase spec and ADR-31 agree that money mutations require idempotency), reorder is a state-changing operation where a network retry could reorder twice, producing a different final order.
- Evidence: handlers.ts:14-15 comment says "No Idempotency-Key: catalogue writes move no money and replaying one converges." However, the same upsert-service call replayed could create duplicate overrides (they converge due to upsert semantics) but reorder applied twice with an intervening change could silently reorder to a different state rather than being idempotent.
- Fix: Wrap the reorder handler in ctx.idempotent() similarly to how money mutations are wrapped. The idempotency scope key would be `catalogue-reorder` with the payload hash. Because catalogue operations are infrequent and never serve cached responses across users, this is a quality improvement rather than a correctness bug. The upsert-service is safe because it naturally converges (upsert), but adding idempotency there would protect against 409-stale-order races after a retry.
- Plan item: Subphase 3.2 (catalogue function) — no explicit idempotency requirement in the AC, but it aligns with the general retry-safety principle.

### F-BE-2: Missing API wrapper test for catalogue routes (minor)

- Severity: minor
- Location: packages/api/src/client.ts:52-57
- Problem: The catalogue API wrapper (upsertService, reorder) has no dedicated Vitest unit test proving the typed invoke path works. The Deno integration tests exercise the HTTP path end-to-end, but the frontend wrapper path is not independently tested.
- Evidence: packages/api/src/client.ts defines catalogue wrappers but the packages/api/src/invoke.test.ts does not include catalogue-specific tests. Only health, onboarding, and staff paths are covered.
- Fix: Add a Vitest test in packages/api/src/invoke.test.ts that calls a mocked invoke for catalogue.upsertService and catalogue.reorder to verify the typed wrappers construct the correct function slug, action, and request options.
- Plan item: Subphase 3.2 (Tests) — contract tests should cover the typed wrapper.

### F-BE-3: service_categories allowlist has no UPDATE policy for is_active on archived rows (minor)

- Severity: minor
- Location: supabase/migrations/20261007100000_create_service_catalogue.sql:123-132
- Problem: The service_categories UPDATE policy grants tenant_owners the right to update (name_en, name_ar, is_active) on any row they can see. While the column-level grant restricts which columns change, there is no row-level constraint preventing an owner from toggling `is_active` on a category that has active services with future appointments. The planned Phase 5 will need to prevent this (deactivating a category should cascade-disable its services).
- Evidence: The policy on line 124-132 uses `has_tenant_role_any_branch(tenant_id, array['tenant_owner'])` — any owner can toggle any category. There is no `WHERE NOT EXISTS (SELECT 1 FROM services WHERE category_id = id AND is_active)` guard.
- Fix: Not a blocker because Phase 3 has no appointment engine yet. Add a note in the plan that Phase 3's category archive policy is acceptable because services are the operational unit and no appointments exist yet. When Phase 5 ships category deactivation must check for active services with future appointments.
- Plan item: Subphase 3.1 (Database work) — implicit in the design, documented here as a Phase 5 integration point.

---

## Audit of Edge Function architecture (ADR-27 to ADR-33, CONVENTIONS §3.3, §4, §6)

### 1. Layout and isolation (checklist item 1)

- Function slug = bounded-context name `catalogue`. ✓
- `_shared/` modules imported by relative path (`../_shared/server.ts`, `../_shared/auth.ts`). ✓
- Functions import `_shared` by relative path, never from `apps/` or other packages. ✓
- `packages/validation` imported through Deno-compatible export (`@repo/validation` → `../../../packages/validation/src/index.ts`). ✓
- Dependencies pinned in `deno.json`: `@supabase/supabase-js@2.117.2`, `zod@4.6.5`, `@sentry/deno@11.4.0`, `@std/assert@1.0.19`. ✓
- Each function is independently deployable (NFR-2). ✓
- `_shared` holds no mutable module-level state. ✓

**Verdict: DONE**

### 2. Auth modes (checklist item 2)

- `config.toml: [functions.catalogue] verify_jwt = false` — gateway disabled; the wrapper enforces per-route auth. ✓
- `index.ts: serve(routes, { fn: "catalogue", auth: "user" })` — user JWT mode. ✓
- `server.ts` validates JWT: extracts Bearer token, calls `auth.getUser()`, then `resolveCaller()` for live membership lookup. ✓
- Route-level override: health is automatically `auth: 'none'`. ✓
- `requireScope()` re-checks membership, role and branch server-side on every handler call. ✓
- Secret comparison in `auth.ts` uses `constantTimeEqual()` (SHA-256 hashing both sides before comparison). ✓
- Service role is never used for per-user requests; all privileged writes use `ctx.admin` (service-role client) only for the RPC call after scope verification. ✓
- Platform-admin path (`onboarding`) uses separate secret mode (PLATFORM_ADMIN_SECRET). ✓
- `_shared/errors.ts` mirrors `packages/validation/src/errors.ts` — error catalogue cannot drift. ✓

**Verdict: DONE**

### 3. Contract (checklist item 3)

- ADR-29 envelope: success `{ ok: true, data }` / failure `{ ok: false, error: { code, message, fieldErrors?, details? } }`. ✓
- Error codes match the catalogue: `VALIDATION` (400), `UNAUTHENTICATED` (401), `FORBIDDEN` (403), `NOT_FOUND` (404), `CONFLICT` (409), `INTERNAL` (500). ✓
- Body validation uses `ctx.body(schema)` which catches invalid JSON and Zod failures → `VALIDATION` with `fieldErrors`. ✓
- Request ID propagated: `x-request-id` echoed on every response (observed via curl: `x-request-id: fc140fc5...`). ✓
- CORS: preflight returns 204, allowed origins configured via `ALLOWED_ORIGINS` env or default localhost origins. ✓
- Unhandled errors become `INTERNAL` without leaking stack traces or SQL (proved by server_test.ts:84-88). ✓

**Verdict: DONE**

### 4. Invariants (checklist item 4)

- Money-moving mutations require Idempotency-Key: catalogue writes move no money. Comment explains "replaying one converges" — the RPC uses `ON CONFLICT DO UPDATE` / `ON CONFLICT DO NOTHING` which is naturally idempotent. ✓
- Multi-row writes in one database transaction: the `upsert_service` RPC writes service definition, branch overrides, AND staff eligibility in one call. ✓
- Orphan state: an ineligible staff member causes the entire call to roll back (catalogue_test.ts:200-215 proves "nothing from the rejected call is kept"). ✓
- The `catalogueRejection()` function maps PostgreSQL error codes to AppError properly (42501→FORBIDDEN, P0002→NOT_FOUND, 55000→CONFLICT, etc.). ✓

**Verdict: DONE**

### 5. Exercise it (checklist item 5)

Tested live against `http://127.0.0.1:54321`:

| Test | Result | Evidence |
|------|--------|----------|
| GET /catalogue/health | 200, ok:true, data:{status:"ok"}, proper x-request-id | curl at time of audit |
| POST /catalogue/upsert-service (no auth) | 401, UNAUTHENTICATED "Missing bearer token" | curl at time of audit |
| POST /catalogue/upsert-service (missing definition) | 400, VALIDATION with fieldErrors: {definition: "validation.definition_required"} | curl at time of audit |

The Deno integration tests cover the remaining paths (scope denial, reorder, etc.) and all pass (gates/fn-test.log:146-155).

**Verdict: DONE**

### 6. Tests (checklist item 6)

| Test suite | Coverage for Phase 3 | Status |
|------------|---------------------|--------|
| Deno catalogue tests (8 tests) | Health, 401, validation, AC (owner creates service with 3 overrides + 5 staff), ineligible staff rollback, scope denial (manager A≠B), other-tenant/reception denial, reorder with stale detection | PASS (gates/fn-test.log:146-155) |
| pgTAP 012_catalogue_matrix (68 tests) | Schema, constraints, read matrix per role, cross-tenant/cross-branch, select-only services, owner-only categories, audit, search normalization | PASS (gates/db-test.log — 684/684 total) |
| pgTAP 013_catalogue_resolution (tests) | Effective values resolution, golden cases matching core catalogue.test.ts | PASS (gates/db-test.log) |
| pgTAP 014_catalogue_rpcs (49 tests) | Atomic create, rollback on ineligible, per-branch role matrix, owner-only definition, override cleanup, audit, reorder | PASS (gates/db-test.log) |
| Vitest catalogue.test.ts | resolveEffectiveService, overriddenFields, overrideDeviates, eligibleStaffAt, nextRoundRobin — pure functions | PASS (gates/verify.log — 224/224 Vitest) |

**Verdict: DONE**. All test categories required by the phase are present and passing. No tests mock away what they claim to test.

### 7. Secrets and config (checklist item 7)

| Item | Status | Evidence |
|------|--------|----------|
| Local secrets in gitignored files | DONE | supabase/functions/.env.example documents PLATFORM_ADMIN_SECRET, INTERNAL_FUNCTION_SECRET, SENTRY_DSN. The actual .env is gitignored. |
| Committed example exists | DONE | supabase/functions/.env.example:1-14 |
| Nothing secret committed | DONE | Gate 1 confirmed frozen lockfile, repo clean before/after. No key-like strings in committed files. |
| Required secrets documented | DONE | .env.example documents each secret's purpose, including Sentry DSN disable for local dev. |

**Verdict: DONE**

---

## Summary

### Per-subphase status

| Subphase | Status | Notes |
|----------|--------|-------|
| 3.1 Catalogue data | DONE | All tables, RLS, composite FKs, effective-values view, audit, resolve_service RPC, seed data. 3 pgTAP suites (68+49+tests) all PASS. |
| 3.2 Catalogue function | DONE | upsert-service and reorder handlers, body validation, per-branch scope verification, all 8 Deno tests PASS. |
| 3.3 Catalogue UI | NOT VERIFIABLE LOCALLY (out of scope for backend audit) | Covered by the frontend auditor's brief. |

### Findings

| ID | Severity | Title |
|----|----------|-------|
| F-BE-1 | minor | Reorder endpoint lacks idempotency-key protection |
| F-BE-2 | minor | Missing API wrapper test for catalogue routes |
| F-BE-3 | minor | service_categories archive policy needs Phase 5 integration guard |

### Count per severity

- Blocker: 0
- Major: 0
- Minor: 3

---

## Conclusion

All Edge Function and backend scope items for Phase 3 are properly implemented. The catalogue follows ADR-27 (one function per bounded context), ADR-28 (select-only tables with transactional writes through the function), ADR-29 (envelope), ADR-30 (function/action routing), ADR-31 (idempotency not required for non-money mutations), ADR-32 (_shared modules), ADR-35 (our own server wrapper), and CONVENTIONS §3.3 (kebab-case slugs, secret naming §6 (allowlist), §4 (error catalogue).

Three minor findings are documented above; none block the phase. The phase exit criteria that fall within backend/Edge Functions scope are all DONE.