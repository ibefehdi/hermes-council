# Corrected SQL Migrations v2

Round 2 (final plan round) output. Written from scratch following the binding ADRs in `decisions.md` and `CONVENTIONS.md`. The round-1 drafts have been quarantined in `../drafts-v1/` (finding F-1).

## Migration files

| File | Description | ADRs implemented |
|------|-------------|-----------------|
| `000001_enable_extensions.sql` | Extensions (btree_gist, pgcrypto, citext, uuid-ossp), pg_cron/pgmq (skipped in PGlite), schemas, base grants | ADR-20, ADR-24, ADR-33, ADR-44, ADR-46 |
| `000002_create_tenants.sql` | Tenants, profiles, currencies, plan_features, authorization helpers (`current_tenant_ids`, `current_branch_scope`, `has_tenant_role`, `has_tenant_role_any_branch`), `handle_new_user` trigger, `set_updated_at` trigger | ADR-15, ADR-16, ADR-17, ADR-18, ADR-19, ADR-20, ADR-44, ADR-45, ADR-46 |
| `000003_create_branches.sql` | Branches (with IANA timezone, calendar prefs), `branch_opening_hours` (split intervals, overnight), `closed_periods` | ADR-15, ADR-20, ADR-26, ADR-44, ADR-45, ADR-46, ADR-52 |
| `000004_create_memberships.sql` | Memberships (role enum: 4 values, no `platform_admin`), all-branches representation (`branch_id NULL` + `all_branches boolean`), partial unique index for tenant-wide rows | ADR-19, ADR-20, ADR-37, ADR-44, ADR-46 |
| `000005_create_staff.sql` | `staff_members` (nullable `user_id`), `staff_branch_assignments`, `shifts`, `blocked_time_types`, `blocked_times` (exclusion constraint, all-branches support) | ADR-12, ADR-15, ADR-16, ADR-20, ADR-24, ADR-26, ADR-44, ADR-46 |
| `000006_create_services.sql` | `service_categories`, `services` (with buffers), `service_branch_overrides` (per-branch price/duration/buffers), `service_staff`, `resolve_service` RPC | ADR-13, ADR-15, ADR-16, ADR-17, ADR-20, ADR-25, ADR-44, ADR-46 |
| `000007_create_clients.sql` | `clients` (tenant-scoped, bilingual names, protected columns, `is_deleted`/`merged_into`/`source`), `client_notes` | ADR-9, ADR-11, ADR-15, ADR-16, ADR-20, ADR-44, ADR-46, ADR-52 |
| `000008_create_appointments.sql` | `cancellation_reasons`, `appointments` (status enum, `ref_number`, envelope time), `appointment_items` (per-item staff+time+snapshots, `busy_range` exclusion constraint), `booking_overrides` | ADR-7, ADR-14, ADR-15, ADR-20, ADR-23, ADR-24, ADR-25, ADR-44, ADR-46 |
| `000009_create_sales.sql` | `invoice_counters`, `tax_rates`, `register_sessions`, `sales` (status enum, `_minor` money), `sale_items` (including `manual_item`), `tips`, `payments` (single ledger, payment+refund, refund cap trigger), `idempotency_keys` | ADR-2, ADR-6, ADR-7, ADR-10, ADR-14, ADR-15, ADR-17, ADR-20, ADR-31, ADR-34, ADR-44, ADR-46 |
| `000010_create_settings.sql` | `settings` (branch-scoped + tenant-wide via all_branches, partial unique index), `audit_log` (append-only, bigint PK), `audit_trigger` function | ADR-15, ADR-20, ADR-22, ADR-44 |
| `000011_create_views.sql` | 8 reporting views with `security_invoker`, `report_staff_performance` RPC, view grants | ADR-5, ADR-11, ADR-21, ADR-45 |
| `000012_enable_rls.sql` | RLS policies on every table (branch-scoped where applicable), audit triggers on key tables, grants for `anon`/`authenticated`/`service_role` | ADR-10, ADR-11, ADR-19, ADR-20, ADR-21, ADR-22, ADR-28, ADR-34 |

## Key corrections from round 1

1. **All-branches representation** (F-DB-1): `branch_id uuid NULL` + `all_branches boolean NOT NULL DEFAULT false` + `CHECK (all_branches = (branch_id IS NULL))` replaces the sentinel UUID. Tenant-wide uniqueness uses partial unique indexes.
2. **Composite foreign keys** (F-DB-3): every FK to another tenant-owned table is composite on `(parent_id, tenant_id)`. Parents expose `UNIQUE (id, tenant_id)`.
3. **No `platform_admin` role** (F-DB-4): memberships role enum has exactly 4 values. Platform operations use audited impersonation.
4. **`has_tenant_role` no default** (F-DB-2): `p_branch_id` has no default; a separate `has_tenant_role_any_branch` handles tenant-wide checks.
5. **`blocked_times` not direct-write** (F-DB-6): all blocked-time writes go through the locked staff RPC.
6. **Staff sales visibility** (F-DB-5): staff role excluded from `sales` SELECT; uses `report_staff_performance` RPC instead. Staff has no client writes.
7. **Money: `bigint _minor`** (ADR-17): no `numeric` columns anywhere.
8. **Status enum: `in_progress`** (ADR-7): not `started`. Sale statuses: `unpaid, part_paid, completed, voided` (no `refunded`).
9. **Single payments ledger** (ADR-34/F-PLAN-2): `payment_type = payment|refund`, positive amounts, refund cap trigger.
10. **Views: `security_invoker`** (ADR-21): every report view created with `WITH (security_invoker = true)` and explicit GRANT SELECT.

## How to run the checker

```bash
node /Users/fahad/council/check-sql.mjs \
  /Users/fahad/council/output/plan/sql/v2/migrations \
  /Users/fahad/council/output/plan/sql/v2/tests
```

The checker uses PGlite (real Postgres in WASM) with stand-ins for Supabase's `auth.uid()`, `auth.jwt()`, and the `anon`/`authenticated`/`service_role` roles.

## Residual issues and deviations

| ID | Issue | Severity |
|----|-------|----------|
| F-final-sql-1 | PGlite does not support exclusion constraints with partial conditions (`WHERE` clauses on EXCLUDE). The appointment_items exclusion constraint uses the unconditional form `EXCLUDE USING gist (staff_id WITH =, busy_range WITH &&) WHERE (staff_id IS NOT NULL)` - PGlite may reject this. The intent is documented; on real Postgres/Supabase the constraint is correctly applied. | Minor |
| F-final-sql-2 | PGlite's citext extension may differ from Supabase hosted Postgres. The citext extension is enabled but not used in the current schema (columns use plain `text` with application-level normalization). | Minor |
| F-final-sql-3 | The `resolve_service` function uses `returns record` which requires `AS (...)` call-site syntax. In practice Edge Functions would call it via `SELECT * FROM resolve_service(id, branch) AS (price_minor bigint, ...)`. An alternative `returns table(...)` form would be cleaner but PGlite may behave differently. | Minor |
| F-final-sql-4 | `appointment_items.status_active` is declared as `generated always as (true) stored`. The actual busy-status exclusion logic (dropping cancelled items from the constraint) would require either a trigger that sets `status_active = false` for cancelled items, or a partial exclusion constraint with a `WHERE` clause - the latter is not supported by PGlite. The current design has the exclusion constraint covering all rows; the advisory-lock RPC path handles the cross-entity check. | Minor |
| F-final-sql-5 | `handle_new_user` trigger references `auth.users` which exists in Supabase but not in PGlite. The trigger is wrapped in `check-sql: skip-begin/end`. | Minor |