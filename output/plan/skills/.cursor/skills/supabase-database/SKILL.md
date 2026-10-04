---
name: supabase-database
description: Use when writing Supabase migrations (SQL), designing schemas, enabling Row Level Security, creating PostgreSQL functions/triggers, adding tenant- or branch-scoped tables, or testing RLS for the spa/salon SaaS. Covers migration workflow, naming, money as bigint minor units, RLS policy templates with branch scope, authorization helpers, exclusion constraints for double-booking, audit triggers, secure report views, and pgTAP testing.
---

# Supabase database conventions

All rules follow `decisions.md` (ADR-15/17/19/20/21/22/24/44/45/46). The domain glossary fixes table names.

## Migration workflow

- Files live in `supabase/migrations/`, created with `supabase migration new <description>` (`<YYYYMMDDHHMMSS>_<description>.sql`).
- One logical change group per file (a table + its indexes + triggers + policies).
- Never modify a migration applied to any shared environment. Seed data only in `supabase/seed.sql`.
- Validate locally with `supabase db reset`; run pgTAP with `supabase test db`.
- Extensions are enabled once in `000001`: `btree_gist`, `pgcrypto`, `pg_trgm` plain; `pg_cron` in the hosted form `CREATE EXTENSION pg_cron WITH SCHEMA pg_catalog;` plus `GRANT USAGE ON SCHEMA cron TO postgres;` and `GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA cron TO postgres;` (official install doc: https://supabase.com/docs/guides/cron/install); `pgmq` per the Supabase Queues doc (own schema); `pg_net` because pg_cron invokes Edge Functions through it (https://supabase.com/docs/guides/functions/schedule-functions — final round, F-final-db-1).

## Naming and column conventions

- Tables plural `snake_case`, glossary names only: `staff_members` (never `staff`), `service_branch_overrides` (never `branch_services`), `branch_opening_hours` (never `branch_hours`).
- PK: `id uuid PRIMARY KEY DEFAULT gen_random_uuid()` (ADR-44). FK: `{entity}_id uuid`.
- Every tenant-scoped table: `tenant_id uuid NOT NULL REFERENCES tenants(id)`, `created_at`/`updated_at timestamptz NOT NULL DEFAULT now()`, and (business tables) `created_by`/`updated_by uuid REFERENCES auth.users(id)`.
- Branch-scoped tables add `branch_id uuid NOT NULL REFERENCES branches(id)`. The all-branches/tenant-wide representation (ADR-20 rule 6, round 2) is `branch_id uuid NULL` plus `all_branches boolean NOT NULL DEFAULT false` with `CHECK (all_branches = (branch_id IS NULL))` — the sentinel UUID is **withdrawn** and must never appear in a migration, policy, or helper. Tenant-wide uniqueness uses partial unique indexes (`WHERE branch_id IS NULL`); e.g. memberships: `UNIQUE (user_id, tenant_id, role, branch_id)` for branch rows plus `UNIQUE (user_id, tenant_id, role) WHERE branch_id IS NULL` for all-branches rows.
- **Money: `bigint` minor units, column suffix `_minor`** (`price_minor`, `total_minor`). Never `numeric`, never float (ADR-17). Currency exponent lives in `currencies`. `CHECK (amount_minor >= 0)` except explicitly signed ledger columns.
- Timestamps: `timestamptz` only (ADR-45). IANA zone names in `branches.timezone` / `tenants.timezone`, never offsets.
- Bilingual operator-facing names: `name_en` + `name_ar` (ADR-16). Searchable entities add a generated normalized `search_text` column (Arabic diacritics stripped, alef/ya/ta-marbuta unified, digits unified) with a `pg_trgm` GIN index (ADR-40).
- Enums: fixed `CHECK` constraints; appointment status uses `in_progress` (ADR-7).
- `updated_at` trigger on every table that has the column:

```sql
CREATE TRIGGER set_updated_at_{table}
  BEFORE UPDATE ON public.{table}
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
```

## Composite tenant consistency (ADR-20 rule 5)

Denormalized `tenant_id` must be provably consistent with parents. Parents expose `UNIQUE (id, tenant_id)`; children reference the pair. Round 2 (F-DB-3): this applies to **every** FK to another tenant-owned table, not only branch/service/staff columns — `appointments(client_id)`, `appointment_items(service_id|staff_id)`, `sales(client_id)`, `sale_items(sale_id|appointment_id|staff_id)`, `payments(sale_id|register_session_id|client_id|refunds_payment_id)`, `tips(staff_id|sale_id)`, `register_sessions(branch_id)`, `blocked_times(staff_id)`, `shifts(staff_id)`, `staff_branch_assignments(staff_id|branch_id)`, `service_staff(service_id|staff_id)`. The pgTAP harness carries the attack test: referencing another tenant's row must fail with an FK violation:

```sql
CREATE TABLE service_branch_overrides (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  branch_id uuid NOT NULL,
  service_id uuid NOT NULL,
  -- ... overrides ...
  FOREIGN KEY (branch_id, tenant_id) REFERENCES branches(id, tenant_id),
  FOREIGN KEY (service_id, tenant_id) REFERENCES services(id, tenant_id),
  UNIQUE (service_id, branch_id)
);
```

## Authorization helpers (ADR-19)

Live membership lookup; `STABLE SECURITY DEFINER`, `SET search_path = public`, granted to `authenticated` only, always filtering `is_active = true`:

```sql
CREATE OR REPLACE FUNCTION public.current_tenant_ids()
RETURNS SETOF uuid LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT tenant_id FROM public.memberships
  WHERE user_id = (SELECT auth.uid()) AND is_active = true;
$$;

CREATE OR REPLACE FUNCTION public.current_branch_scope(p_tenant_id uuid)
RETURNS SETOF uuid LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT branch_id FROM public.memberships
  WHERE user_id = (SELECT auth.uid()) AND tenant_id = p_tenant_id
    AND is_active = true AND NOT all_branches;
  -- all-branches memberships are checked via the all_branches flag, never a sentinel
$$;

CREATE OR REPLACE FUNCTION public.has_tenant_role_any_branch(
  p_tenant_id uuid, p_roles text[])
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships m
    WHERE m.user_id = (SELECT auth.uid())
      AND m.tenant_id = p_tenant_id
      AND m.role = ANY(p_roles)
      AND m.is_active = true
      AND m.all_branches
  );
$$;

-- Branch-scoped check: NO default on p_branch_id (round 2, F-DB-2) - a forgotten
-- argument must be an error, not a silent tenant-wide pass. Tenant-wide checks
-- use has_tenant_role_any_branch() above, explicitly.
CREATE OR REPLACE FUNCTION public.has_tenant_role(
  p_tenant_id uuid, p_roles text[], p_branch_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships m
    WHERE m.user_id = (SELECT auth.uid())
      AND m.tenant_id = p_tenant_id
      AND m.role = ANY(p_roles)
      AND m.is_active = true
      AND (m.all_branches OR m.branch_id = p_branch_id)
  );
$$;
```

Use `(SELECT auth.uid())` (scalar subquery, evaluated once), never bare `auth.uid()` per row. Every `SECURITY DEFINER` function - helpers, booking/checkout RPCs, audit triggers, `resolve_service`, the refund-cap trigger - declares `SET search_path = public` (or fully schema-qualifies every name); `supabase db lint` enforces this in CI (ADR-20 rule 10). Required pgTAP: a branch-A manager fails `has_tenant_role(t, '{branch_manager}', branch_b)`.

## RLS templates (ADR-20)

Tenant-level table:

```sql
ALTER TABLE public.{table} ENABLE ROW LEVEL SECURITY;
CREATE POLICY "{table}_select" ON public.{table}
  FOR SELECT TO authenticated
  USING (tenant_id IN (SELECT public.current_tenant_ids()));
-- INSERT/UPDATE/DELETE policies only where the ADR-28 allowlist permits direct writes,
-- each gated by has_tenant_role(...) with the row's branch where applicable.
```

Branch-scoped table (appointments, sales, payments, shifts, register_sessions, ...):

```sql
CREATE POLICY "{table}_select" ON public.{table}
  FOR SELECT TO authenticated
  USING (
    tenant_id IN (SELECT public.current_tenant_ids())
    AND (
      public.has_tenant_role_any_branch(tenant_id,
        '{tenant_owner,branch_manager,receptionist,staff}')
      OR branch_id IN (SELECT public.current_branch_scope(tenant_id))
    )
  );
```

Money/conflict tables get **select-only** RLS; all mutations go through SECURITY DEFINER RPCs called from Edge Functions (ADR-28). This includes `blocked_times` (round 2, F-DB-6): every blocked-time write runs through the locked `staff`/blocked-time RPC (advisory lock + cross-entity appointment check, ADR-24/26) - it is not a direct-write table. RPCs verify scope internally with the same helpers - the service role is not a boundary.

Never: `USING (true)`; insert policies on `tenants` (provisioning is the `onboarding` function only); policies without `TO authenticated`; missing `WITH CHECK` on insert/update; relying on the client for tenancy.

`profiles`: self read/write (`id = (SELECT auth.uid())`) plus a narrow same-tenant colleagues read (name/avatar) - never world-readable.

## Double-booking prevention (ADR-24) - the canonical pattern

`appointment_items` carries its own staff and span, a generated busy range including buffers, and an active flag maintained by the status machine:

```sql
ALTER TABLE appointment_items
  ADD COLUMN busy_range tstzrange GENERATED ALWAYS AS (
    tstzrange(effective_start - (buffer_before_minutes || ' minutes')::interval,
              effective_end   + (buffer_after_minutes  || ' minutes')::interval, '[)')
  ) STORED;

ALTER TABLE appointment_items
  ADD CONSTRAINT appointment_items_staff_no_overlap
  EXCLUDE USING gist (staff_id WITH =, busy_range WITH &&)
  WHERE (staff_id IS NOT NULL AND status_active);
```

`blocked_times` gets the equivalent exclusion on `(staff_id, blocked_range)`. Cross-entity conflicts (appointment vs blocked time) are checked inside the booking transaction **after** taking a per-staff lock:

```sql
SELECT pg_advisory_xact_lock(hashtextextended(p_staff_id::text, 0));
-- then check the other entity's rows, then insert
```

All of this runs only inside `book_appointment` / `reschedule_appointment` RPCs; direct writes are prohibited, which is what closes the reschedule hole. Triggers alone are NOT acceptable (race-prone). Required tests: concurrent same-slot bookings (one wins), booking into a block, reschedule into an occupied slot.

## Audit (ADR-22)

`audit_log(tenant_id, branch_id, actor_id, action, entity_type, entity_id, changes jsonb, performed_at)`. Written only by SECURITY DEFINER trigger functions on audited tables and by Edge Function code paths; `INSERT/UPDATE/DELETE` revoked from `anon` and `authenticated`. Reads: owner tenant-wide, manager branch-scoped (select-only RLS).

## Reports and views (ADR-21)

Every view: `CREATE VIEW ... WITH (security_invoker = true)` so invoker RLS applies (views bypass RLS by default - this is a Supabase-documented trap). Security-invoker views still need **grants**: the invoking role (`authenticated`) must hold SELECT on the view and its base tables, so every view migration ships explicit `GRANT SELECT` (plus the RLS policies on top) and a pgTAP test proving the intended role reads rows rather than a permission-denied error (round 2, F-6; https://supabase.com/docs/guides/database/postgres/row-level-security). Aggregates needing SECURITY DEFINER are `report_*` RPCs that filter with `current_branch_scope()` internally. Report SQL correctness (round 2, F-DB-8): top-services joins `sale_items.item_id = services.id AND sale_items.item_type = 'service'` (there is no `sale_items.service_id`); client-summary counts pre-aggregate sales per client (or `count(DISTINCT ...)`) so multi-sale clients are not inflated. The staff role sees sales only through a `report_own_sales` secured RPC/view over their own `sale_items`/`tips` - never a branch-wide `sales` SELECT (round 2, F-DB-5). Day grouping converts to branch-local first:

```sql
SELECT (s.sale_date AT TIME ZONE b.timezone)::date AS local_day, ...
FROM sales s JOIN branches b ON b.id = s.branch_id ...
```

Client financial aggregates are secured RPCs, never columns or unscoped views (ADR-11). CI greps new view definitions for `security_invoker`.

## Other required patterns

- Invoice numbers: `invoice_counters(branch_id, kind, next_number)` with `kind ∈ {invoice, appointment_ref}` (round 2, F-DB-7); assign inside the sale/booking transaction with `UPDATE ... SET next_number = next_number + 1 ... RETURNING next_number - 1` (row lock; gaps allowed, never reuse). Appointment `ref_number` = `<branch invoice_prefix>-A<seq>` with `UNIQUE (branch_id, ref_number)`.
- Refund cap trigger on `payments`: sum of `refund` rows referencing a payment ≤ its `amount_minor`. Refund rows carry a **positive** `amount_minor` and `payment_type = 'refund'` - no negative amounts, no separate refunds table (ADR-34 round 2).
- `staff_members`: partial unique index `(tenant_id, user_id) WHERE user_id IS NOT NULL` (one identity per tenant, round 2 F-DB-9).
- Sale totals reconciliation: `create_sale` RPC recomputes totals from lines and rejects mismatches; `due_minor` is derived (`total - sum(payments)`) and never hand-edited — stored generated vs computed-at-read is settled by the active migration set (the v2 validation set does not carry the column; final round, F-final-arch-1).
- `idempotency_keys(tenant_id, key, function_name, status, response_status, response_body)` unique `(tenant_id, key, function_name)` — the replay boundary is per function (final round, F-final-db-3); 30-day expiry via pg_cron. RLS deny-all with a select-only grant: the table is client-inaccessible and the replay protocol runs inside Edge Functions.
- Soft delete: `clients.is_deleted` + `merged_into`; `is_active` on services/staff/branches; status-based retention for appointments/sales; partial unique indexes exclude deleted rows; no hard deletes of referenced history.
- Settings uniqueness uses the all-branches representation: `UNIQUE (tenant_id, branch_id, key)` governs branch rows, and a partial unique index `ON settings(tenant_id, key) WHERE branch_id IS NULL` guarantees one tenant-wide row per key (round 2, F-DB-1).
- Overnight opening hours: `closes_at < opens_at` means next-day close; `opens_at = closes_at` is rejected by the `boh_nonzero_length` check unless the row is `is_closed` (closed day = `is_closed`, 24-hour day = 00:00–23:59 — ADR-26, final round F-final-db-5); split intervals via `seq` (ADR-26). Cover overnight, zero-length rejection, and a synthetic DST-zone branch in availability tests.

## How to add a tenant-scoped table

1. `supabase migration new create_{table}`; write CREATE TABLE with glossary naming, required columns, `_minor` money, bilingual names where operator-facing.
2. Composite FKs for every denormalized `tenant_id` (rule above); indexes on `(tenant_id, ...)`, FK columns, and time ranges where queried.
3. `updated_at` trigger; audit trigger if the table is in the audited set.
4. Enable RLS; tenant or branch template per ADR-20; role-gate writes per the requirements matrix; decide allowlist vs RPC-only per ADR-28 and update CONVENTIONS.md if requesting allowlist addition.
5. pgTAP tests: per operation × per role × cross-tenant × cross-branch × anon. No table ships without them.
6. `supabase db reset`, then regenerate types: `supabase gen types typescript --local > packages/db/src/database.types.ts` (committed; CI fails on drift).

## Testing RLS

pgTAP files in `supabase/tests/`, run by `supabase test db` in CI on every migration. Pattern:

```sql
BEGIN;
SELECT plan(3);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'USER-A-UUID', true);
SELECT is_empty('SELECT * FROM clients WHERE tenant_id = ''TENANT-B-UUID''',
  'Tenant A user sees no Tenant B clients');
-- branch-manager-of-A must not see branch B rows; receptionist must not write settings; etc.
ROLLBACK;
```

Coverage gate: the full matrix (every table × operation × role, cross-tenant, cross-branch, anon) must have no uncovered cells before a phase exits. Revocation-immediacy (deactivate a membership mid-session) is a standing test.

## Additional resources

- Supabase RLS (incl. views/`security_invoker`): https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase migrations: https://supabase.com/docs/guides/local-development/database-migrations
- PostgreSQL exclusion constraints: https://www.postgresql.org/docs/current/sql-createtable.html#SQL-CREATETABLE-EXCLUDE
- Supabase Queues (pgmq semantics): https://supabase.com/docs/guides/queues/pgmq
- pgTAP: https://pgtap.org/
