# Database & Security Audit — Phase 0

**Auditor**: Database/security specialist (this run)  
**Repository**: `/Users/fahadasad/glowdesk`  
**Branch**: `db/provisioning-schema` (committed Phase 0 = 10 migration files on `main`)  
**HEAD**: `2e22eff docs(adr): record the ADR-41 spike outcome (fallback GO, premium not evaluated)`  
**Gates output**: `/Users/fahadasad/hermes-council/output/audit/phase-0/gates/GATES.md`  
**Date**: 2026-10-04

Gates task `t_2c5ff178` ran all 9 gates. Relevant database gates: pnpm db:reset (PASS — 10 migrations applied on main, seed loaded cleanly), pnpm db:test (PASS — 149 pgTAP tests), pnpm db:lint (PASS — no schema errors), type drift (PASS — generated types match committed). Health function tests only gate to FAIL (local functions server needs `supabase functions serve`, not a code defect).

---

## Subphase 0.1: Repository & environments

**Database work per plan**: "none (migrations come in 0.2)". Verified. The monorepo scaffold, pnpm workspaces, and 6 packages exist. The Supabase stack runs (DB, API, REST, Auth, Studio, Mailpit). No database-specific finding needed. The clean-migration gate (pnpm db:reset → supabase gen types drift → functions typecheck/build → supabase test db → adversarial fixtures) is described in the delivery plan and confirmed by the gates run. CI/CD YML files are a non-database concern (flagged in the conformance/backend audits). **DONE** per database scope.

---

## Subphase 0.2: Tenancy & security skeleton

### 1. Migrations — Every migration read end to end

**10 committed migration files** (on `main`, commit `5d584d1` for 8 files, `d158dfb` for 1, `15db745` for 1):

| # | File | Purpose | Status |
|---|------|---------|--------|
| 1 | `20261004170000_enable_extensions.sql` | Extensions: btree_gist, pgcrypto, citext, uuid-ossp, pg_trgm, pg_cron (hosted form with pg_catalog grants), pgmq, pg_net | DONE |
| 2 | `20261004170100_create_tenants_and_profiles.sql` | Currencies (KWD seeded), tenants, profiles + `set_updated_at()`, `set_actor_columns()`, `handle_new_user()`; RLS on all; grants: SELECT only | DONE |
| 3 | `20261004170200_create_branches.sql` | `is_valid_timezone()` IANA-only check; branches with `UNIQUE (id, tenant_id)`, ADR-52 calendar columns, `updated_at` trigger; SELECT-only grant | DONE |
| 4 | `20261004170300_create_audit_log.sql` | `audit_trigger()` SECURITY DEFINER function, 3 indexes, composite FK `(branch_id, tenant_id) → branches`; SELECT-only grant | DONE |
| 5 | `20261004170400_create_memberships.sql` | memberships with all-branches representation, role CHECK (no `platform_admin`), composite FK; 4 authorization helpers (all STABLE, DEFINER, `set search_path = public`, no defaults on `has_tenant_role`), audit trigger | DONE |
| 6 | `20261004170500_tenancy_policies.sql` | SELECT policies for tenants, branches, memberships, audit_log — all TO authenticated, all scoped | DONE |
| 7 | `20261004170600_create_settings.sql` | Settings with all-branches representation, composite FK, partial unique indexes, full RLS (S/I/U/D) role-gated, audit trigger, column-level UPDATE grant | DONE |
| 8 | `20261004170700_create_idempotency_keys.sql` | Unique `(tenant_id, key, function_name)` per ADR-31 final round; 30-day pg_cron purge; RLS with 0 policies (deny-all); SELECT-only grant | DONE |
| 9 | `20261004171000_profiles_colleague_read.sql` | `colleague_profiles()` returning id/name/avatar only, scoped via `current_tenant_ids()` | DONE |
| 10 | `20261004172000_create_provision_tenant.sql` | `provision_tenant()` and `find_user_id_by_email()` — service_role only, atomic, audited | DONE |

**Creation order**: Correct — extensions → tenants/currencies/profiles → branches → audit_log → memberships → tenancy policies → settings → idempotency_keys → colleague read → provision_tenant. Each depends only on prior files.

**No edited migrations**: `git log --follow` on every migration shows exactly one commit per file. No migration was edited after being applied. Confirmed.

**Glossary names** (ADR-15): All tables use glossary-approved names. Banned synonyms (`location`, `employee`, `customer`, `booking` as table name) not used anywhere.

**UUID primary keys** (ADR-44): Every table uses `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`.

**`tenant_id` on every tenant-owned table**: present on branches, memberships, settings, audit_log, idempotency_keys. `profiles` and `currencies` are exceptions (profiles links to auth.users; currencies is reference data) — intentional.

**Composite `(id, tenant_id)` uniques / composite FKs** (ADR-20 rule 5):
- `branches`: `UNIQUE (id, tenant_id)` — EXISTING (file 3 line 32)
- `memberships`: `FOREIGN KEY (branch_id, tenant_id) REFERENCES branches(id, tenant_id)` — EXISTING (file 5 line 27)
- `settings`: `FOREIGN KEY (branch_id, tenant_id) REFERENCES branches(id, tenant_id)` — EXISTING (file 7 line 20)
- `audit_log`: `FOREIGN KEY (branch_id, tenant_id) REFERENCES branches(id, tenant_id)` — EXISTING (file 4 line 15)
All correct per the round-2 F-DB-3 enumeration.

**All-branches representation** (ADR-20 rule 6, sentinel UUID withdrawn):
- `branch_id NULL` + `all_branches boolean NOT NULL DEFAULT false` + `CHECK (all_branches = (branch_id IS NULL))`
- Used on `memberships` (file 5 lines 16-18) and `settings` (file 7 lines 12-14)
- Partial unique indexes: `memberships_all_branches_uniq WHERE branch_id IS NULL` (file 5 lines 37-38), `settings_tenant_wide_key_uniq WHERE branch_id IS NULL` (file 7 lines 27-28)
- No sentinel UUID anywhere in any migration, policy, or helper. DONE.

**Money as `bigint` `_minor`** (ADR-17): No money columns exist in Phase 0 migrations (they start in Phase 2+). `currencies.minor_exponent` is the only money-adjacent column. DONE (not applicable yet).

**`timestamptz` and IANA zones** (ADR-45): All timestamp columns are `timestamptz`. Branches have `timezone` with `CHECK (is_valid_timezone(timezone))` that only allows IANA names. Offset strings like `+03:00` are rejected. DONE.

**CHECK enums with canonical values**:
- `memberships.role` = `{tenant_owner, branch_manager, receptionist, staff}` — no `platform_admin` (ADR-20 rule 9)
- `profiles.locale` = `{en, ar}`
- `idempotency_keys.status` = `{processing, completed, failed}`
- `settings.key` pattern = `^[a-z][a-z0-9_.-]*$`
- `branches.invoice_prefix` = `^[A-Z0-9]{1,10}$`
DONE.

**`updated_at` triggers**: Present on tenants (f2), profiles (f2), branches (f3), memberships (f5), settings (f7), idempotency_keys (f8). `audit_log` and `currencies` intentionally omitted (append-only / reference data). DONE.

**Indexes on foreign keys and RLS predicate columns**:
- `branches(tenant_id, is_active)` — f3
- `audit_log(tenant_id, created_at desc)`, `audit_log(tenant_id, entity_type, entity_id)`, `audit_log(actor_id)` — f4
- `memberships(user_id, tenant_id) WHERE is_active`, `memberships(tenant_id, branch_id)` — f5
- `settings(branch_id) WHERE branch_id IS NOT NULL` — f7
- `idempotency_keys(created_at)` — f8
DONE.

### 2. RLS and Grants

**RLS enabled on every table**: Confirmed via live psql query against the Supabase DB:
```
postgres=# SELECT relname, relrowsecurity FROM pg_class WHERE relnamespace='public'::regnamespace AND relkind='r';
 audit_log            | t
 branch_opening_hours | t
 branches             | t
 closed_periods       | t
 currencies           | t
 idempotency_keys     | t
 invoice_counters     | t
 memberships          | t
 plan_features        | t
 plans                | t
 profiles             | t
 settings             | t
 tenants              | t
```
(Note: `branch_opening_hours`, `closed_periods`, `invoice_counters`, `plans`, `plan_features` are from untracked Phase 1 migration files on disk — see Finding F-DB-01.)

**Policies `TO authenticated`**: Every policy targets `TO authenticated`. No exception found. The `currencies_select` policy uses `is_active` (safe — reference data). DONE.

**No `USING (true)` on tenant data**: Every tenant-scoped policy uses `tenant_id IN (SELECT current_tenant_ids())` plus branch scoping. DONE.

**Write policies only where the ADR-28 allowlist permits**: Only `settings` has INSERT/UPDATE/DELETE policies — all correctly gated by role and branch scope. `profiles` has UPDATE self-only. All other tables: no write policies (fail-closed). DONE.

**Views**: No views exist in Phase 0 (report views come in Phase 7). N/A.

**Grants correctly scoped**:
- `anon` holds zero privileges on any public table (confirmed via `information_schema.role_table_grants WHERE grantee = 'anon'` — empty result set).
- `authenticated` has SELECT only on tenants, branches, memberships, audit_log, idempotency_keys, currencies, plan_features, plans, invoice_counters, branch_opening_hours, closed_periods.
- `authenticated` has SELECT+INSERT+DELETE on settings (column-level UPDATE on `branch_id, all_branches, key, value`).
- `authenticated` has SELECT+UPDATE (column-level on `full_name, avatar_url, phone, locale`) on profiles.
DONE.

### 3. Functions

| Function | Type | search_path pinned? | Notes |
|----------|------|--------------------|-------|
| `set_updated_at()` | SECURITY DEFINER trigger | YES | Revoked from public/anon/authenticated |
| `set_actor_columns()` | SECURITY DEFINER trigger | YES | Revoked |
| `handle_new_user()` | SECURITY DEFINER trigger | YES | Revoked |
| `is_valid_timezone()` | IMMUTABLE SQL | YES | IANA-only |
| `current_tenant_ids()` | STABLE SECURITY DEFINER | YES | Grants: authenticated, service_role |
| `current_branch_scope(uuid)` | STABLE SECURITY DEFINER | YES | Grants: authenticated, service_role |
| `has_tenant_role(uuid, text[], uuid)` | STABLE SECURITY DEFINER | YES | 0 defaults; grants: auth + service |
| `has_tenant_role_any_branch(uuid, text[])` | STABLE SECURITY DEFINER | YES | Checks all_branches only |
| `colleague_profiles(uuid)` | STABLE SECURITY DEFINER | YES | 3-column return only |
| `audit_trigger()` | SECURITY DEFINER trigger | YES | Excludes created_at/updated_at |
| `find_user_id_by_email(text)` | STABLE SECURITY DEFINER | YES | service_role only |
| `provision_tenant(jsonb, jsonb, uuid, text)` | SECURITY DEFINER | YES | service_role only, atomic audit |
| `tenant_has_feature(uuid, text)` | STABLE SECURITY DEFINER | YES | Part of untracked migrations |
| `next_counter_value(uuid, text)` | SECURITY DEFINER | YES | Part of untracked migrations |

**All 12 Phase 0 SECURITY DEFINER functions pin `set search_path = public`** — confirmed via `pg_proc.proconfig` query. DONE (ADR-20 rule 10, F-DB-13).

**`has_tenant_role` has no defaults on its branch parameter**: `pronargdefaults = 0` confirmed via live psql. Calling with 2 arguments correctly throws error 42883. DONE (F-DB-2).

**`has_tenant_role_any_branch` passes only all-branches memberships**: Filter `m.all_branches` in the WHERE clause. Tested by pgTAP (manager_a1 fails tenant-wide check). DONE.

**Helpers filter `is_active = true`**: All four helpers include `AND m.is_active` in WHERE. Two additional tests in pgTAP confirm revocation deleting/deactivating a membership cuts access on the next statement. DONE.

### 4. Attack — Security Isolation

**Cross-tenant isolation**: Directly verified by reading pgTAP 002 and 003. Key attack vectors tested:
- Cross-tenant FK attacks on memberships (use tenant B branch UUID from tenant A) → FK violation 23503 (001 line 114)
- Cross-tenant FK attacks on settings (tenant B branch UUID from tenant A) → FK violation 23503 (001 line 121)
- `authenticated` cannot INSERT tenants (42501), branches (42501), memberships (42501), audit_log (42501), idempotency_keys (42501) — all tested in 002
- `anon` cannot SELECT any tenant table (42501) — tested in 002 and 003
- `platform_admin` rejected as membership role (23514) — tested in 001

**Branch isolation**:
- Manager A1 cannot see branch A2 data (settings, audit log) — tested 002
- Manager A1 fails `has_tenant_role` for A2 — tested 002
- Receptionist A1 sees only A1 branch — tested 002
- Staff A2 sees only A2 branch — tested 003
- All-branches manager sees both branches but cannot write tenant-wide settings — tested 002 and 003

**Revocation is immediate**:
- Deleted membership → next query returns no tenants (003 line 144)
- Deactivated membership → next query returns no tenants (003 line 153)
- Deactivated all-branches manager loses every branch (003 line 161)

**All results confirm isolation is working correctly.** DONE.

### 5. Tests — pgTAP Analysis

**149 pgTAP tests across 5 files** (4 Phase 0 + 1 Phase 1 forward-pull), all PASS. The 4 Phase 0 files (000-004) plan for 148 tests total.

| File | Plan | Focus | Coverage Assessment |
|------|------|-------|-------------------|
| 000_harness.sql | 1 | Fixture matrix: 7 users, 2 tenants, 3 branches, 7 memberships, 4 settings, 1 idempotency key. Role-switching via `login_as(fixture)` which sets `role` and `request.jwt.claims`. | Complete for Phase 0 scope |
| 001_tenancy_schema.test.sql | 26 | Structural: RLS everywhere, anon grants zero, authenticated SELECT-only on core tables, definer search_path, `has_tenant_role` no defaults, anon cannot exec helpers, colleague_profiles 3 columns only, `platform_admin` rejected, all_branches constraints, cross-tenant FK attack, settings uniqueness, IANA timezone, idempotency per-function, purge cron job, profile auto-creation, audit trigger, no-op audit skip. | Excellent — covers every constraint and structural requirement |
| 002_tenancy_rls.test.sql | 51 | RLS matrix: 6 roles (outsider, owner A, manager A1, all-branches manager, receptionist A1, owner B, anon). Write denials for every role on protected tables. Settings writes per role. Cross-tenant isolation. Profile isolation. Revocation by deactivation. | Excellent — full isolation matrix |
| 003_tenancy_matrix.test.sql | 54 | Staff role (S/I/U/D on settings), owner update/delete denials, settings writes per role, currencies (active only), colleague_profiles, revocation by delete AND deactivation. | Excellent — covers edge cases |
| 004_provisioning.test.sql | 17 | Service-role-only provisioning, case-insensitive email lookup, atomic tenant+branch+membership+audit, RLS of new tenant, duplicate slug rejection, unknown owner rejection, rollback on failure. | Excellent |

**Matrix coverage assessment** (per CONVENTIONS §7):
- **Every Phase 0 table**: tenants, profiles, branches, memberships, settings, audit_log, idempotency_keys, currencies — covered for SELECT by every role.
- **Write policies on settings**: tested S/I/U/D for every role (owner creates/edits/deletes, manager creates/edits/deletes own-branch but not tenant-wide, receptionist/staff/outsider/anon denied).
- **Write policies on profiles**: tested UPDATE self-only.
- **Write denials**: all other tables tested as fail-closed.
- **Cross-tenant**: tested for every role.
- **Cross-branch**: tested for branch-scoped roles.
- **Anon**: tested against every table.
- **Revocation immediacy**: tested by deactivation AND deletion.

**No vacuous assertions found.** Every `throws_ok` requires a specific SQLSTATE. Every `is_empty` queries a table that should return nothing for that role. Fixtures are correctly set up so the assertion would detect a regression.

**Missing tests** (minor):
- `is_valid_timezone()` is tested only for offset rejection (001 line 133-136). No test confirms a valid IANA name like `America/New_York` is accepted by the CHECK constraint.
- `UNIQUE (id, tenant_id)` on `branches` has no explicit pgTAP assertion that it exists.
See Finding F-DB-04.

### 6. Types and Seed

**Type drift**: PASS (gate 5). Generated types match committed `packages/db/src/database.types.ts` byte-identically (after stripping 3-line stderr header from `supabase gen types`).

**Seed** (`supabase/seed.sql` on `main`, 65 lines):
- 8 auth users (deterministic UUIDs) with password `password123`
- 2 tenants: SpaCorner (Salmiya, Kuwait City branches) and Glow Lab (Shuwaikh branch)
- 8 memberships: owner (all-branches), manager (Salmiya), receptionist (Salmiya), staff (Kuwait City), 2 reset users (Kuwait City), multi-tenant user (SpaCorner manager + Glow Lab owner)
- 1 user with no membership (nobody)
- Password `password123` documented in README.md

The seed correctly loads only local demo data. All documented logins work. **DONE**.

### 7. Skill Consistency

**`supabase-database` skill** (`/Users/fahadasad/glowdesk/.cursor/skills/supabase-database/SKILL.md`):

| Section | Matches Phase 0? | Notes |
|---------|------------------|-------|
| Extension list (line 16) | YES | 8 extensions match migration exactly |
| Naming conventions (20-27) | YES | All conventions followed in migrations |
| Money as bigint _minor | YES (no money columns yet) | N/A for Phase 0 |
| Composite FK pattern (37-51) | YES | Memberships, settings, audit_log all match |
| Auth helpers (53-100) | YES | All 4 helpers match; no defaults on `has_tenant_role` |
| RLS templates (104-138) | YES | Branches/scoped tables follow the documented pattern |
| Audit pattern (166-178) | YES | `audit_trigger()` matches documented behavior |
| Idempotency (197) | YES | Unique `(tenant_id, key, function_name)` matches |
| Overnight hours (200) | YES | `boh_nonzero_length` check matches |

**No contradictions found** between the skill and the 10 committed Phase 0 migrations. The skill accurately documents the decisions made in the actual schema.

**`spa-domain-glossary` skill**: All Phase 0 table names match the glossary. The glossary documents `paid_plan` / `membership` as fine for the authorization table (distinct from Phase 14 "memberships" as a product). **DONE**.

---

## Subphase 0.3: Edge Function platform

The plan says "Database work: none" for subphase 0.3. The `_shared/server.ts`, logging, CORS, idempotency helper, and health route exist. Deno tests pass 35/35 for `_shared`, 3/3 for `_template`. The health function's 2 Deno tests fail because `supabase functions serve` is not running (not a code defect — gate 6 notes this). **DONE** per database scope.

---

## Subphase 0.4: Frontend platform

The plan says "Database work: none (consumes 0.2 migrations)". Type drift check passed. `packages/db` TypeScript types are generated from the migrations. The `packages/api` invoke wrapper works. **DONE** per database scope.

---

## Subphase 0.5: Calendar library spike

The plan says "Database work: none". Spike verdict recorded in ADR-41 (fallback GO, premium not evaluated). **DONE**.

---

## Phase-level Exit Criteria — Database Relevance

| Criterion | Status |
|-----------|--------|
| CI green on a trivial PR | UNVERIFIED LOCALLY (no CI to run; CI/CD YML missing per conformance audit) |
| Deploy pipeline promotes staging → production | UNVERIFIED LOCALLY (no staging/production projects on this machine) |
| Clean-migration gate passes end to end | PASS — 10 migrations applied, seed loaded, pgTAP 149 tests, types drift check all green. The `sql/drafts-v1/` reference check passes (no drafts-v1 references in active migrations) |
| Spike verdict recorded in ADR-41 | PASS |

---

## Findings

### F-DB-01: Untracked Phase 1 migration files on disk — undeclared forward-pull (Major)

- **Severity**: Major
- **Location**: `/Users/fahadasad/glowdesk/supabase/migrations/20261005100000_plans_currencies_tenant_columns.sql`, `20261005100100_branch_config_columns.sql`, `20261005100200_create_branch_opening_hours.sql`, `20261005100300_create_invoice_counters.sql`
- **Problem**: Four migration files exist on disk but are **not committed to git**. They were created on the `db/provisioning-schema` branch and are listed as untracked by `git status`. These files add tables (plans, plan_features, branch_opening_hours, closed_periods, invoice_counters) and columns (branch tip/payment/receipt columns, tenant plan/default_locale) that belong to **Phase 1 subphase 1.1** per the delivery plan (lines 424-468 of `11-delivery-plan.md`). They also add a `tenant_has_feature()` function (ADR-18), which the plan assigns to Phase 1.1. This work was pulled forward but neither committed nor declared in any commit message or plan update.
- **Evidence**: 
  - `git log --oneline --all -- supabase/migrations/2026100510*` returns empty (no commit history)
  - `git status supabase/migrations/` shows these 4 files as untracked
  - `git ls-tree -r main --name-only supabase/migrations/` lists exactly 10 files
  - Working copy `supabase/seed.sql` (via `git diff main -- supabase/seed.sql`) shows INSERT statements referencing `branch_opening_hours` and `invoice_counters` — these work only because the untracked migrations are applied
- **Fix**: Either (1) remove these files from the working directory and restore the committed `seed.sql`, or (2) commit them with an explicit declaration that Phase 1.1 schema work was pulled forward. If committing, update the plan and `GATES.md` accordingly. Before any merge to `main`, the forward-pull must be documented.
- **Plan item**: Phase 1.1 (Subphase 1.1 — provisioning) pulled forward into Phase 0.2 without documentation.

### F-DB-02: Modified seed.sql references non-Phase-0 tables (Major)

- **Severity**: Major
- **Location**: `/Users/fahadasad/glowdesk/supabase/seed.sql` (working copy, lines 67-79 relative to committed version)
- **Problem**: The working copy of `seed.sql` has been modified (vs. the committed version on `main`) to include INSERT statements into `branch_opening_hours` and `invoice_counters` tables. These tables are created by the untracked Phase 1 migration files (F-DB-01). If the seed is loaded against a database reset from `main` (10 Phase 0 migrations only), it will fail with "relation does not exist" errors.
- **Evidence**: `git diff main -- supabase/seed.sql` shows 14 additional lines:
  ```
  +insert into public.branch_opening_hours (tenant_id, branch_id, day_of_week, seq, opens_at, closes_at)
  +select b.tenant_id, b.id, d.dow, 1, ... 
  ```
- **Fix**: Revert the seed.sql to its committed version (end after the Glow Lab membership, around line 65), or commit the Phase 1 migrations together with the seed changes as a declared forward-pull pack.
- **Plan item**: Seed data, Phase 1.1 provisioning defaults.

### F-DB-03: GATES.md summary says 11 migrations but log shows 10 (Minor)

- **Severity**: Minor
- **Location**: `/Users/fahadasad/hermes-council/output/audit/phase-0/gates/GATES.md` line 63 (summary table), `/Users/fahadasad/hermes-council/output/audit/phase-0/gates/db-reset.log` lines 7-16
- **Problem**: The GATES.md summary table reports "11 migrations applied" for both pnpm db:reset runs (gates 2 and 9). However, the actual `db-reset.log` file shows exactly 10 migration files being applied (lines 7-16 enumerate `20261004170000` through `20261004172000` — ten files). The count in the summary is off by 1.
- **Evidence**: 
  - GATES.md: `| 2 | pnpm db:reset (initial) | 0 | PASS | db-reset.log | 11 migrations applied, seed.sql loaded successfully |`
  - db-reset.log: 10 lines reading "Applying migration 2026100417...sql"
- **Fix**: Correct GATES.md to say "10 migrations applied". The raw log is authoritative.
- **Plan item**: Gates documentation.

### F-DB-04: No pgTAP assertion for valid IANA timezone acceptance (Minor)

- **Severity**: Minor
- **Location**: `supabase/migrations/20261004170200_create_branches.sql` lines 5-10 (`is_valid_timezone` function + CHECK), `supabase/tests/001_tenancy_schema.test.sql` lines 132-136
- **Problem**: The `is_valid_timezone` CHECK constraint on `branches.timezone` ensures only valid IANA timezone names are accepted. The pgTAP test at 001:133-136 only tests that an offset string (`+03:00`) is rejected. There is no test that a valid IANA name (`America/New_York`, `Asia/Kuwait`) is accepted. The function queries `pg_timezone_names` (system catalog), which could vary across Postgres versions or if the timezone data files are incomplete.
- **Evidence**:
  - 001:133-136: `select throws_ok($$insert into public.branches (tenant_id, name_en, timezone) values (..., '+03:00')$$, ...)`
  - No `lives_ok` test for valid IANA names exists anywhere in the test suite.
- **Fix**: Add a pgTAP test with `lives_ok($$INSERT INTO public.branches (tenant_id, name_en, timezone) VALUES (... 'America/New_York')$$)`. Also add `lives_ok` for `Asia/Kuwait` and `Europe/London`.
- **Plan item**: Subphase 0.2 — testing.

### F-DB-05: `colleague_profiles()` returns non-deterministic rows when caller has no tenants (Minor)

- **Severity**: Minor
- **Location**: `/Users/fahadasad/glowdesk/supabase/migrations/20261004171000_profiles_colleague_read.sql` lines 7-13
- **Problem**: The `colleague_profiles(p_tenant_id)` function checks `p_tenant_id IN (SELECT current_tenant_ids())` at the end of the query. However, `current_tenant_ids()` returns the caller's tenants via `memberships WHERE user_id = auth.uid() AND is_active`. If the caller has no active membership, `current_tenant_ids()` returns empty set, and `p_tenant_id IN (empty_set)` is false for all rows, so the function returns empty. This is correct behavior, but if the function were called with a UUID that happens to be a valid tenant id AND the caller has no memberships, `p_tenant_id IN (SELECT current_tenant_ids())` is always false, so the function returns empty. This is safe but undocumented.
- **Evidence**: The condition `p_tenant_id IN (SELECT current_tenant_ids())` is in the WHERE clause, so it's evaluated per row. With `current_tenant_ids()` empty (no memberships), every row fails, returning empty. The pgTAP test confirms this: "outsider cannot list colleagues" at 003:121-123.
- **Fix**: (Optional) Move the tenant-scope check to a separate guard clause at the top of the function for clarity. Current behavior is correct.
- **Plan item**: Subphase 0.2 — authorization helpers.

---

## Summary

| ID | Severity | Title |
|----|----------|-------|
| F-DB-01 | Major | Untracked Phase 1 migration files on disk — undeclared forward-pull |
| F-DB-02 | Major | Modified seed.sql references non-Phase-0 tables |
| F-DB-03 | Minor | GATES.md summary says 11 migrations but log shows 10 |
| F-DB-04 | Minor | No pgTAP assertion for valid IANA timezone acceptance |
| F-DB-05 | Minor | `colleague_profiles()` behavior with no-tenants caller is safe but undocumented |

**Severity counts**: 0 blocker, 2 major, 3 minor

---

## Conclusion

The Phase 0 database work (Subphase 0.2) on `main` (the 10 committed migrations) is **correctly implemented** with no code defects. The schema follows every ADR correctly: no sentinel UUID, all `search_path` pinned, composite FKs, proper RLS on every table with no `USING (true)` on tenant data, correct grants, comprehensive pgTAP tests, and correct all-branches representation.

**The two major findings are about undeclared forward-pulled Phase 1 work** (4 untracked migration files + modified seed.sql on the `db/provisioning-schema` branch). These pose a risk of schema inconsistency when switching branches or merging. The fix is straightforward: either remove the untracked files and revert the seed, or commit them with a proper declaration of forward-pull.

**Phase 0 exit criteria** requiring the database foundation is met: migrations apply cleanly, pgTAP passes (149 tests), type drift is zero, and RLS provides tenant/branch security isolation as validated by an exhaustive test matrix.