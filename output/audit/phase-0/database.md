# Database and Security Audit — Phase 0

Auditor role. Brief: `/Users/fahadasad/hermes-council/output/audit/phase-0/briefs/database.md`.

Checked against: plan phase 0 (delivery-plan.md lines 190–393), the ADRs (decisions.md), and CONVENTIONS.md.

Repository: `/Users/fahadasad/glowdesk` (read-only).
Branch: `feat/frontend-platform` (head `2e22eff`).
Gates: parent task `t_5ee7c800` reported 9/9 gates pass, but GATES.md was not found under the gates output directory (only `git-status-before.txt` and `supabase-status.txt` present). pgTAP re-ran locally: 149 tests pass.

---

## Migration analysis

### Migration 001: 20261004170000_enable_extensions.sql

Creates extensions: `btree_gist`, `pgcrypto`, `citext`, `uuid-ossp`, `pg_trgm`, `pg_cron` (hosted form with pg_catalog schema + cron grants), `pgmq`, `pg_net`.
- `pg_net` uses `with schema extensions` (correct per ADR-33 revised)
- `pg_cron` grants: `grant usage on schema cron to postgres; grant all privileges on all tables in schema cron to postgres` (correct per official install doc)
- All extensions mentioned in CONVENTIONS §7 (line 190-191) are present.

### Migration 002: 20261004170100_create_tenants_and_profiles.sql

Tables: `currencies`, `tenants`, `profiles`.
- `tenants`: uuid PK, bilingual names, `slug` unique with pattern check, `currency_code` FK to currencies, `is_active`, timestamps with trigger.
- `profiles`: uuid PK FK to auth.users, `name` bilingual, `locale` with `en`/`ar` check, timestamps.
- `currencies`: text PK with ISO code check, bilingual names, `minor_exponent` 0-4, `is_active`.
- RLS enabled on both tables.
- Grants: `revoke all on table public.currencies from anon, authenticated; grant select to authenticated` — correct.
- `handle_new_user()` trigger for auto-creating profiles — `SECURITY DEFINER` with `set search_path = public` ✓.
- `set_updated_at()` and `set_actor_columns()` triggers — both pin `search_path = public` ✓.

**Finding**: `handle_new_user()` has `SECURITY DEFINER` but NOT revoked from `public`/`anon`/`authenticated` in this file (lines 116-117 do revoke it explicitly). Grant status: `revoke execute on function public.handle_new_user() from public, anon, authenticated` — correct.

**Finding**: `currencies` migration seeds KWD with `minor_exponent = 3` but ADR-17 requires column names ending in `_minor` (e.g. `total_minor`, `amount_minor`). No money columns exist in Phase 0 yet, so this is a future concern, not a Phase 0 defect.

### Migration 003: 20261004170200_create_branches.sql

- `is_valid_timezone()` function: uses `pg_timezone_names`, immutable, `set search_path = public` ✓.
- `branches`: uuid PK, `tenant_id` FK, `UNIQUE (id, tenant_id)` for composite FK support, bilingual names, `timezone` (IANA check), `invoice_prefix`, `is_active`, `first_day_of_week` (0-6, default 6 = Saturday), `time_format` (12/24), `slot_step_minutes` (5/10/15/30, default 15).
- All ADR-52 fields (`first_day_of_week`, `time_format`, `slot_step_minutes`) present.
- Index on `(tenant_id, is_active)`.
- RLS enabled. Grants: `revoke all from anon, authenticated; grant select to authenticated` — correct (writes through onboarding only per ADR-28).

### Migration 004: 20261004170300_create_audit_log.sql

- `audit_log`: bigint PK (identity), `tenant_id`, nullable `branch_id`, nullable `actor_id`, `entity_type`, nullable `entity_id`, `action`, `changed_fields` jsonb, `created_at`.
- Composite FK: `foreign key (branch_id, tenant_id) references public.branches(id, tenant_id)`.
- Indexes on `(tenant_id, created_at desc)`, `(tenant_id, entity_type, entity_id)`, `(actor_id)`.
- `audit_trigger()`: SECURITY DEFINER, `set search_path = public` ✓. Revoked from `public, anon, authenticated`.
- Grants: `revoke all from anon, authenticated; revoke all on sequence from anon, authenticated; grant select to authenticated` — correct (append-only, ADR-22).
- The trigger captures before/after for updates, records tenant_id, branch_id, and `auth.uid()` for actor. No-op updates are skipped.

**Minor finding**: The audit_log's `action` column allows `INSERT`/`UPDATE`/`DELETE` (from `TG_OP`) but also has a check constraint `action ~ '^[A-Z_]+$'`. PROVISION (used in the provisioning migration) has this as uppercase with underscore, so it passes. No explicit handling of `DELETE` in the trigger (it treats DELETE identically to INSERT for the old row) — this is fine for append-only.

### Migration 005: 20261004170400_create_memberships.sql

- `memberships`: uuid PK, `tenant_id` FK, `user_id` FK (on delete cascade), `role` CHECK without `platform_admin`, nullable `branch_id`, `all_branches` with constraint `all_branches = (branch_id is null)`, `is_active`, `created_by`, `updated_by`.
- Constraint: `memberships_owner_all_branches_chk` — tenant_owner must have all_branches.
- Composite FK: `foreign key (branch_id, tenant_id) references public.branches(id, tenant_id)`.
- Unique: `(user_id, tenant_id, role, branch_id)`. Partial unique: `(user_id, tenant_id, role) WHERE branch_id is null`.
- Indexes: `memberships_user_active_idx (user_id, tenant_id) WHERE is_active`, `memberships_tenant_branch_idx (tenant_id, branch_id)`.
- Triggers: `set_updated_at`, `set_actor_columns`, `audit_memberships`.
- RLS enabled. Grants: `revoke all; grant select` — correct.
- All four helpers: `current_tenant_ids()`, `current_branch_scope(uuid)`, `has_tenant_role(uuid, text[], uuid)`, `has_tenant_role_any_branch(uuid, text[])` — all are `STABLE SECURITY DEFINER SET search_path = public` ✓.

**Key design points checked**:
- `has_tenant_role` has 3 parameters with no defaults — a forgotten branch argument is a compile error ✓ (ADR-20 rule 4, F-DB-2).
- `has_tenant_role_any_branch` checks only `m.all_branches` — branch-scoped roles never pass a tenant-wide check ✓.
- `current_branch_scope` returns only non-all-branches (the all_branches flag is filtered explicitly) ✓.
- Helpers are revoked from `public, anon` and granted to `authenticated, service_role` ✓.

### Migration 006: 20261004170500_tenancy_policies.sql

RLS policies for `tenants`, `branches`, `memberships`, `audit_log`:
- `tenants_select`: `id IN (select current_tenant_ids())` — correct.
- `branches_select`: tenant_id IN current_tenant_ids() AND either has_tenant_role_any_branch() or branch IN current_branch_scope() — correct branch-scoped pattern.
- `memberships_select`: own memberships OR (tenant-wide AND owner) OR (branch-specific AND branch_manager of that branch) — correct.
- `audit_log_select`: owner tenant-wide OR branch_manager branch-scoped — correct per ADR-22.

All policies: `FOR SELECT TO authenticated` — no `USING (true)` found on any ✓.

### Migration 007: 20261004170600_create_settings.sql

- `settings`: uuid PK, `tenant_id`, `branch_id` (nullable), `all_branches`, `key`, `value` jsonb, timestamps, created_by, updated_by.
- Constraint: `all_branches = (branch_id is null)` ✓ (ADR-20 rule 6).
- Composite FK: `(branch_id, tenant_id) → branches(id, tenant_id)` ✓ (ADR-20 rule 5).
- Partial unique: `(tenant_id, key) WHERE branch_id is null` for tenant-wide rows ✓.
- Unique: `(tenant_id, branch_id, key)` for branch-specific rows ✓.
- Triggers: `set_updated_at`, `set_actor_columns`, `audit_settings`.
- RLS policies: settings select (multi-role branch-scoped), insert (owner tenant-wide, owner/branch_manager for branch), update (same gates), delete (same gates).
- Grants: `revoke all; grant select, insert, delete; grant update (branch_id, all_branches, key, value)` — correct for the direct-write allowlist (ADR-28).

### Migration 008: 20261004170700_create_idempotency_keys.sql

- `idempotency_keys`: uuid PK, `tenant_id`, `key` (1-255 chars), `function_name` (pattern check), `request_hash`, `status`, `response_status`, `response_body`, timestamps.
- Unique: `(tenant_id, key, function_name)` — per-function scope (ADR-31, final round F-final-db-3).
- Index on `(created_at)` for cleanup.
- Cron job: `purge-expired-idempotency-keys` runs at `17 3 * * *`, deletes keys older than 30 days ✓.
- RLS enabled. Grants: `revoke all; grant select` — correct (client-inaccessible, ADR-31).

### Migration 009: 20261004171000_profiles_colleague_read.sql

- `colleague_profiles()`: SECURITY DEFINER, `set search_path = public` ✓. Returns `id, full_name, avatar_url` for active memberships in the caller's tenant.
- Uses `current_tenant_ids()` to check scope internally ✓.
- Revoked from `public, anon`, granted to `authenticated` ✓.
- Returns only 3 columns id/full_name/avatar_url — no phone or email exposed ✓.

### Migration 010: 20261004172000_create_provision_tenant.sql

- `find_user_id_by_email()`: SECURITY DEFINER, `set search_path = public` ✓. Lowercase comparison for case-insensitive lookup.
- `provision_tenant()`: SECURITY DEFINER, `set search_path = public` ✓. Creates tenant + branch + membership + audit row atomically.
- Both are service_role only ✓ (not callable by anon/authenticated).
- Validates owner exists, requested_by not empty.
- Idempotency not built into the RPC itself (handled by the Edge Function layer via `_shared/idempotency.ts`).

---

## Security (RLS & Grants) Analysis

### RLS Status by Table
All tables have `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`:
- `currencies` ✓ — `FOR SELECT TO authenticated USING (is_active)`
- `tenants` ✓ — `FOR SELECT TO authenticated USING (id IN current_tenant_ids())`
- `profiles` ✓ — `FOR SELECT` self-only, `FOR UPDATE` self-only with `WITH CHECK`
- `branches` ✓ — `FOR SELECT TO authenticated` with tenant+branch scope
- `memberships` ✓ — `FOR SELECT TO authenticated` with owner/manager scope
- `settings` ✓ — `FOR SELECT/INSERT/UPDATE/DELETE` with role+branch scope
- `audit_log` ✓ — `FOR SELECT TO authenticated` with owner/manager scope
- `idempotency_keys` ✓ — no policy (select-only grant)

### Grant Pattern
All tables follow the pattern:
- `revoke all on table from anon, authenticated`
- `grant select on table to authenticated`
- Settings additionally: `grant insert, delete` and `grant update (columns)`
- Profiles additionally: `grant update (columns)`

No `USING (true)` found on tenant data ✓.

### No-Insert Policies on Critical Tables
- `tenants`: no insert/update/delete policy — only using the `onboarding` function (ADR-20 rule 3) ✓.
- `branches`: no insert/update/delete policy — only onboarding function ✓.
- `memberships`: no insert/update/delete policy — only onboarding/staff functions ✓.
- `audit_log`: no insert/update/delete — trigger-only writes ✓.
- `idempotency_keys`: no insert/update/delete policy — Edge Function writes ✓.

---

## Function Analysis

### SECURITY DEFINER Functions — search_path check

| Function | search_path pinned? |
|---|---|
| `set_updated_at()` | ✓ `set search_path = public` |
| `set_actor_columns()` | ✓ `set search_path = public` |
| `handle_new_user()` | ✓ `set search_path = public` |
| `is_valid_timezone()` | ✓ `set search_path = public` (immutable) |
| `current_tenant_ids()` | ✓ `set search_path = public` |
| `current_branch_scope(uuid)` | ✓ `set search_path = public` |
| `has_tenant_role(uuid, text[], uuid)` | ✓ `set search_path = public` — no defaults ✓ |
| `has_tenant_role_any_branch(uuid, text[])` | ✓ `set search_path = public` |
| `colleague_profiles(uuid)` | ✓ `set search_path = public` |
| `audit_trigger()` | ✓ `set search_path = public` |
| `find_user_id_by_email(text)` | ✓ `set search_path = public` |
| `provision_tenant(jsonb, jsonb, uuid, text)` | ✓ `set search_path = public` |

All 12 functions pin `search_path = public` ✓ (tested in pgTAP 001 line 36-39).

### has_tenant_role parameter defaults

- `has_tenant_role(uuid, text[], uuid)` has no defaults ✓ (tested in pgTAP 001 lines 42-51).
- Calling it without branch argument correctly errors ✓.

### has_tenant_role_any_branch scope

- Filters on `m.all_branches = true` — only true all-branches memberships pass ✓.
- A branch-scoped manager does NOT pass `has_tenant_role_any_branch` ✓ (tested in pgTAP 002 lines 69-70).

---

## pgTAP Test Coverage

5 test files, 149 tests, all passing.

### 000_harness.sql — Fixture setup
- Creates `tests` schema with role-switching helpers and fixture matrix.
- `login_as(fixture_name)` activates a test user with JWT claims.
- `seed_tenancy_matrix()` creates 7 users, 2 tenants, 3 branches, 7 memberships, 4 settings.
- Covers: tenant_owner, branch_manager (scoped), branch_manager (all-branches), receptionist, staff, outsider (no membership), anon.

### 001_tenancy_schema.test.sql — 26 tests
- RLS on every public table ✓
- No anon grants ✓
- authenticated can only SELECT audit_log ✓
- authenticated can only SELECT core tenancy tables ✓
- has_tenant_role has no defaults ✓
- anon cannot execute auth helpers ✓
- colleague_profiles exposes only 3 columns ✓
- platform_admin rejected as role ✓
- all_branches constraints ✓
- Composite FK attacks: cross-tenant membership rejected ✓, cross-tenant settings rejected ✓
- settings unique partial index ✓
- IANA timezone validation ✓
- Idempotency: per-function uniqueness ✓, same key same function rejected ✓
- Purge cron job exists ✓
- Profile auto-creation ✓
- Audit logging on membership inserts/updates ✓
- No-op update skips audit ✓

### 002_tenancy_rls.test.sql — 51 tests
- Outsider sees nothing ✓
- Owner sees only their tenant ✓
- Owner cannot create tenants/branches/memberships/audit rows ✓
- Owner can write settings (tenant-wide and branch) ✓
- Owner cannot write other tenant's settings ✓
- Branch manager sees only their branch ✓
- Branch manager sees only branch memberships/audit rows ✓
- Manager A1 fails branch_manager check for A2 ✓
- Manager A1 fails tenant-wide branch_manager check ✓
- Manager A1 cannot write tenant-wide settings ✓
- Manager A1 can write A1 settings but not A2 ✓
- All-branches manager sees both branches ✓
- All-branches manager cannot write tenant-wide settings ✓
- Receptionist sees only own branch ✓
- Receptionist cannot write settings ✓
- Receptionist can update own profile ✓
- Users cannot update other profiles ✓
- Owner B cannot see tenant A data ✓
- Anon cannot read any table ✓
- Deactivated manager loses access immediately ✓

### 003_tenancy_matrix.test.sql — 54 tests
- Staff A2 sees only branch A2 ✓
- Staff sees tenant-wide and own-branch settings ✓
- Staff cannot insert settings or profiles ✓
- Staff update/delete has no effect ✓
- Owner tenant update/delete denied ✓
- Owner branch update/delete denied ✓
- Owner membership update/delete denied ✓
- Owner audit/attempt update denied ✓
- Owner idempotency key update/delete denied ✓
- Owner cannot insert/delete profiles ✓
- Owner can update/insert/delete settings within scope ✓
- Owner cannot affect tenant B data ✓
- Currencies: only active visible ✓
- Colleague profiles visible only within tenant ✓
- Manager cannot update/delete tenant-wide settings ✓
- Manager cannot delete A2 settings ✓
- All-branches manager can update any branch setting ✓
- All-branches manager cannot update tenant-wide settings ✓
- Outsider has no tenants ✓
- Outsider cannot list colleagues ✓
- Revocation by delete cuts access immediately ✓
- Revocation by deactivation cuts access immediately ✓

### 004_provisioning.test.sql — 17 tests
- anon cannot call provisioning ✓
- authenticated cannot call provisioning ✓
- service_role can call provisioning ✓
- tenant owner cannot call provision_tenant ✓
- Email lookup is case-insensitive ✓
- Unknown email returns null ✓
- Tenant created with default currency ✓
- Branch created with default timezone ✓
- Owner gets all-branches tenant_owner membership ✓
- Provisioning writes PROVISION audit row ✓
- New owner reads only their tenant under RLS ✓
- Duplicate slug rejected ✓
- Unknown owner rejected ✓
- Failed provision leaves no rows behind ✓

---

## Seed Analysis

File: `/Users/fahadasad/glowdesk/supabase/seed.sql` (67 lines)

- Creates 8 users with fixed UUIDs under the `00000000-0000-4000-8000-...` prefix.
- Creates SpaCorner tenant (`0000...9000...0001`) with 2 branches: Salmiya and Kuwait City.
- Creates memberhips for owner (all-branches), manager (Salmiya), receptionist (Salmiya), staff (Kuwait City).
- Creates second tenant Glow Lab for tenant-switching test user Maha Multi.
- All passwords are `password123` (documented in README).

**Findings**:
- UUIDs follow the pattern `00000000-0000-4000-...` which are valid UUIDv4-like formats. The `4` in the variant nibble position makes them look like UUIDv4, but they're deterministic — fine for seed data.
- Manager `mona@spacorner.test` is only manager of Salmiya branch, consistent with tests.
- User `nobody@spacorner.test` has no memberships — tests empty-scope correctly.
- User `multi@spacorner.test` is manager in SpaCorner and owner of Glow Lab — tests multi-tenant.
- Password-reset users `reset-en` and `reset-ar` are staff in Kuwait City branch, separated by locale so e2e projects run in parallel ✓.

---

## Findings

### F-DB-1: CI/CD workflows (ci.yml, deploy.yml) do not exist — no `.github/workflows/` directory
- Severity: **blocker**
- Location: `/Users/fahadasad/glowdesk/` — no `.github/` directory found at all
- Problem: Subphase 0.1 explicitly requires CI/CD as a feature delivered and has acceptance criteria "CI is green on a trivial PR" and "Deploy pipeline promotes staging → production". The `.github/workflows/ci.yml` and `.github/workflows/deploy.yml` do not exist. This is a critical deliverable of the entire phase.
- Evidence: `search_files` from repo root returned zero results for `.github` path. Already flagged by parent gates task.
- Fix: Create `.github/workflows/ci.yml` with: typecheck Deno + TS, lint, `supabase db lint`, pgTAP via `supabase test db`, Deno tests, Vitest, build, size-limit, generated-types drift check, and the clean-migration acceptance gate (including `sql/drafts-v1/` reference check). Create `.github/workflows/deploy.yml` with migrations, functions `--use-api`, and frontend build/deploy from the same commit.
- Plan item: Subphase 0.1 — "CI/CD: ci.yml..." and all 7 backlog items under 0.1

### F-DB-2: `branches` table ships in Phase 0 but belongs to Phase 1.1 per the plan
- Severity: **major**
- Location: `/Users/fahadasad/glowdesk/supabase/migrations/20261004170200_create_branches.sql`
- Problem: Subphase 0.2 specifies "migrations for `tenants, profiles, memberships, settings, currencies, audit_log, idempotency_keys`" — `branches` is NOT listed. It appears first in the Phase 1.1 database work: "Migration: `branches`...". The branches table was pulled forward into Phase 0. This IS a legitimate pull-forward (needed for composite FKs on memberships, settings, and audit_log), and it is documented in the migration comment header ("Branches: the FK target for every branch-scoped table, so it lands with the tenancy skeleton"). However, this is an undeclared deviation — it should be documented as such in the plan or commit message.
- Evidence: Migration file header says "so it lands with the tenancy skeleton" but the Phase 0 specification does not list it.
- Fix: Either (a) document the pull-forward in the plan or (b) add a note in the migration file saying "Pulled forward from Phase 1.1 — needed for composite FKs in Phase 0."
- Plan item: Subphase 0.2 — this is a declared-deviation gap.

### F-DB-3: `provision_tenant` RPC ships in Phase 0 but belongs to Phase 1.1 per the plan
- Severity: **minor**
- Location: `/Users/fahadasad/glowdesk/supabase/migrations/20261004172000_create_provision_tenant.sql`
- Problem: The `provision_tenant` RPC (and `find_user_id_by_email`) are listed in Phase 1.1 backlog: "[Edge Function] `onboarding/provision-tenant`". The Edge Function wrapper is in Phase 0.3, but the SQL RPC is a Phase 0.2 database migration. This is a legitimate pull-forward since `onboarding` Edge Function needs the RPC, but should be documented.
- Evidence: Migration file header: "Platform-admin tenant provisioning (ADR-20 rule 3). Only the onboarding Edge Function calls these... Full provisioning (plan row, seeded defaults, idempotent re-runs, provision-branch) lands in Phase 1.1." — this acknowledges the split.
- Fix: Add a note to the plan that the `provision_tenant` SQL RPC is pulled forward into Phase 0.2 so the onboarding function works.
- Plan item: Subphase 0.2, Phase 1.1

### F-DB-4: Sentry, uptime monitor, and log drain not wired (NOT VERIFIABLE LOCALLY type)
- Severity: **major**
- Location: Subphase 0.1 — "Sentry (frontend + Deno), external uptime monitor pinging `/health`, log-drain wiring"
- Problem: Sentry integration, external uptime monitor, and log drain are Phase 0.1 deliverables. While `/health` exists and responds, Sentry SDK is not found in the repository, no monitors.json or uptime-check configuration detected. The phase exit criteria include "Sentry captures an error from a deliberately-broken function; uptime monitor fires on simulated downtime."
- Evidence: Search in repo root: no `sentry` references found in core setup files. No `.github/workflows/` exists for deploy pipeline. The health endpoint exists but responds with BOOT_ERROR ("Worker failed to boot").
- Fix: Add Sentry SDK to Deno functions (Sentry Deno package) and frontend (`@sentry/react`), add monitors.json for uptime monitoring, and wire log drain.
- Plan item: Subphase 0.1

### F-DB-5: Health endpoint fails to boot
- Severity: **major**
- Location: `curl http://127.0.0.1:54321/functions/v1/health`
- Problem: The health endpoint returns `{"code":"BOOT_ERROR","message":"Worker failed to boot (please check logs)"}`. This means the Deno runtime cannot start the health function, breaking the acceptance criteria "A ping-style health route deployed to staging returns 200 with a request ID header."
- Evidence: Actual HTTP response from live local stack.
- Fix: Check `supabase/functions/health/` for import resolution errors (likely `_shared/server.ts` imports that fail at runtime). Fix any broken imports or missing `.env` variables.
- Plan item: Subphase 0.3

### F-DB-6: Seed users use deterministic UUIDs that look like valid UUIDs but are not GenRandom
- Severity: **minor**
- Location: `/Users/fahadasad/glowdesk/supabase/seed.sql:7-14`
- Problem: The seed uses hardcoded UUIDs like `00000000-0000-4000-8000-000000000001`. While functionally valid, the seed should not use the `4` version nibble (which suggests RFC 4122 UUIDv4 randomness) for deterministic IDs. This is style/readability, not correctness.
- Evidence: `seed.sql` lines 7-14 show all user UUIDs follow the pattern `00000000-0000-4000-8000-00000000000N`.
- Fix: Use a different scheme: either `00000000-0000-0000-0000-00000000000N` (all zeros in version nibble) or document that these are fixed deterministic UUIDs for reproducible seed data.
- Plan item: Naming/seed convention

### F-DB-7: No Realtime channel authorization tested
- Severity: **major**
- Location: pgTAP test files — none test Realtime channel authorization
- Problem: ADR-20 (consequences) and ADR-38 (round-2 binding correction) require "the test plan includes Realtime channel authorization — subscribing as tenant A/branch A must never receive tenant B or branch B payloads". CONVENTIONS §7 requires "Realtime channel authorization tested for tenant/branch leakage". No pgTAP or E2E test for Realtime authorization exists in Phase 0.
- Evidence: No test files reference Realtime, postgres_changes, or channel authorization.
- Fix: Add pgTAP tests that verify `REALTIME` subscribers receive only the rows their RLS allows. This can use `supabase_realtime` extension or test the underlying RLS boundary. Alternatively, add E2E tests via Playwright with authenticated WebSocket subscriptions.
- Plan item: Subphase 0.2 — testing; ADR-20, ADR-38

---

## Summary

### Verification results

| Subphase | Status |
|---|---|
| 0.1 Repository & environments | PARTIAL — monorepo exists, but CI/CD missing, Sentry/monitor unwired |
| 0.2 Tenancy & security skeleton | DONE — 10 migrations, 8 RLS tables, 12 helpers, 149 pgTAP tests, seed data |
| 0.3 Edge Function platform | PARTIAL — _shared/ exists but health endpoint fails to boot |
| 0.4 Frontend platform | NOT VERIFIED — out of database scope |
| 0.5 Calendar library spike | NOT VERIFIED — out of database scope |

### Database deliverables assessment

| Item | Status |
|---|---|
| 10 migration files in correct chronological order | DONE |
| Extensions set (btree_gist, pgcrypto, citext, uuid-ossp, pg_trgm, pg_cron, pgmq, pg_net) | DONE |
| uuid primary keys (ADR-44) | DONE |
| tenant_id on every tenant-owned table | DONE |
| Composite (id, tenant_id) UNIQUE on parent tables | DONE (branches, not needed on tenants) |
| Composite foreign keys for tenant consistency (ADR-20 rule 5) | DONE (branch_id + tenant_id pairs) |
| All-branches representation (branch_id NULL + all_branches + partial unique) | DONE (ADR-20 rule 6) |
| timestamptz + IANA timezone (ADR-45) | DONE (branches.timezone with is_valid_timezone) |
| CHECK enums with canonical values | DONE (role, status, locale checks) |
| updated_at triggers | DONE |
| Indexes on FKs and RLS predicate columns | DONE |
| SECURITY DEFINER functions pin search_path | DONE (all 12, tested) |
| RLS on every table | DONE (8/8 tables) |
| has_tenant_role no parameter defaults | DONE |
| has_tenant_role_any_branch checks all_branches only | DONE |
| 149 pgTAP tests covering all CRUD x role x scope | DONE |
| CI/CD workflows | MISSING |
| Realtime channel authorization test | MISSING |

### Findings count
- Blocker: 1 (CI/CD missing)
- Major: 4 (branches pulled forward, Sentry/monitor not wired, health endpoint boot failure, Realtime channel auth not tested)
- Minor: 2 (provision_tenant planned vs actual, seed UUID style)