## Domain model

#### Tenancy and branches

```mermaid
classDiagram
  class Tenant {
    +UUID id
    +String name_en
    +String name_ar
    +String slug
    +String plan
    +UUID currency_id
    +Boolean is_active
    +Timestamp created_at
    +Timestamp updated_at
  }

  class Branch {
    +UUID id
    +UUID tenant_id
    +String name_en
    +String name_ar
    +String address
    +String phone
    +String timezone
    +String invoice_prefix
    +Smallint first_day_of_week
    +Smallint time_format
    +Smallint slot_step_minutes
    +Boolean is_active
    +Timestamp created_at
    +Timestamp updated_at
  }

  class BranchOpeningHours {
    +UUID id
    +UUID branch_id
    +UUID tenant_id
    +Smallint day_of_week
    +Smallint seq
    +Time opens_at
    +Time closes_at
    +Boolean is_closed
  }

  class ClosedPeriod {
    +UUID id
    +UUID branch_id
    +UUID tenant_id
    +Date starts_on
    +Date ends_on
    +String name_en
    +String name_ar
  }

  class Membership {
    +UUID id
    +UUID user_id
    +UUID tenant_id
    +Role role
    +UUID branch_id
    +Boolean all_branches
    +Boolean is_active
  }

  class Currency {
    +UUID id
    +String code
    +Smallint exponent
  }

  class PlanFeature {
    +UUID id
    +String plan
    +String feature
  }

  Tenant "1" --> "*" Branch : has
  Tenant "1" --> "*" Membership : authorizes
  Tenant "1" --> "1" Currency : uses
  Tenant "1" --> "*" PlanFeature : entitled
  Branch "1" --> "*" BranchOpeningHours : defines
  Branch "1" --> "*" ClosedPeriod : observes
  Membership "*" --> "0..1" Branch : scoped to
```

Tenancy ER diagram:

```mermaid
erDiagram
  tenants {
    uuid id PK
    text name_en
    text name_ar
    text slug UK
    text plan
    uuid currency_id FK
    boolean is_active
  }
  branches {
    uuid id PK
    uuid tenant_id FK
    text name_en
    text name_ar
    text timezone
    text invoice_prefix
    smallint first_day_of_week
    smallint time_format
    smallint slot_step_minutes
    boolean is_active
  }
  branch_opening_hours {
    uuid id PK
    uuid branch_id FK
    uuid tenant_id FK
    smallint day_of_week
    smallint seq
    time opens_at
    time closes_at
    boolean is_closed
  }
  closed_periods {
    uuid id PK
    uuid branch_id FK
    uuid tenant_id FK
    date starts_on
    date ends_on
  }
  memberships {
    uuid id PK
    uuid user_id FK
    uuid tenant_id FK
    text role
    uuid branch_id FK
    boolean all_branches
    boolean is_active
  }
  currencies {
    uuid id PK
    text code UK
    smallint exponent
  }
  plan_features {
    uuid id PK
    text plan
    text feature
  }
  tenants ||--o{ branches : "tenant_id FK + composite (id,tenant_id)"
  tenants ||--o{ memberships : "tenant_id FK"
  tenants ||--|| currencies : "currency_id FK"
  branches ||--o{ branch_opening_hours : "composite (branch_id,tenant_id) FK"
  branches ||--o{ closed_periods : "composite (branch_id,tenant_id) FK"
  branches ||--o{ memberships : "branch_id FK (nullable; all_branches flag)"
```

Tenancy explanation: The tenant is the root entity; every other table belongs to a tenant via `tenant_id` and composite foreign keys (ADR-20 rule 5). Branch-scoped roles use `memberships.branch_id` or the `all_branches` flag (nullable `branch_id` + boolean, ADR-20 rule 6 — the sentinel UUID is withdrawn). `platform_admin` is not a membership role; platform ops use audited impersonation (ADR-20 rule 9). Branch calendar preferences (`first_day_of_week`, `time_format`, `slot_step_minutes`) live on `branches` as typed columns, not `settings` keys (ADR-52). Opening hours support overnight (`closes_at < opens_at`) and split intervals via `seq`; `opens_at = closes_at` is rejected by the `boh_nonzero_length` check unless the row is `is_closed` — a zero-length interval is meaningless, a closed day is `is_closed = true`, and a 24-hour day is expressed as 00:00-23:59 (ADR-26, revised in the final round per F-final-db-5).

#### Staff and shifts

```mermaid
classDiagram
  class StaffMember {
    +UUID id
    +UUID tenant_id
    +UUID user_id
    +String full_name_en
    +String full_name_ar
    +String phone
    +String email
    +Boolean is_active
    +Timestamp created_at
    +Timestamp updated_at
  }

  class StaffBranchAssignment {
    +UUID id
    +UUID staff_id
    +UUID tenant_id
    +UUID branch_id
    +Boolean is_default
    +Boolean is_bookable
  }

  class Shift {
    +UUID id
    +UUID staff_id
    +UUID branch_id
    +UUID tenant_id
    +Timestamp starts_at
    +Timestamp ends_at
  }

  class BlockedTimeType {
    +UUID id
    +UUID tenant_id
    +String name_en
    +String name_ar
    +String color
  }

  class BlockedTime {
    +UUID id
    +UUID staff_id
    +UUID tenant_id
    +UUID branch_id
    +UUID blocked_time_type_id
    +Timestamp starts_at
    +Timestamp ends_at
    +String notes
    +Boolean all_branches
  }

  StaffMember "1" --> "*" StaffBranchAssignment : assigned to
  StaffMember "1" --> "*" Shift : works
  StaffMember "1" --> "*" BlockedTime : has
  Branch "1" --> "*" StaffBranchAssignment : at
  Branch "1" --> "*" Shift : at
  BlockedTimeType "1" --> "*" BlockedTime : typed
```

Staff ER diagram:

```mermaid
erDiagram
  staff_members {
    uuid id PK
    uuid tenant_id FK
    uuid user_id FK
    text full_name_en
    text full_name_ar
    text phone
    text email
    boolean is_active
  }
  staff_branch_assignments {
    uuid id PK
    uuid staff_id FK
    uuid tenant_id FK
    uuid branch_id FK
    boolean is_default
    boolean is_bookable
  }
  shifts {
    uuid id PK
    uuid staff_id FK
    uuid branch_id FK
    uuid tenant_id FK
    timestamptz starts_at
    timestamptz ends_at
  }
  blocked_time_types {
    uuid id PK
    uuid tenant_id FK
    text name_en
    text name_ar
    text color
  }
  blocked_times {
    uuid id PK
    uuid staff_id FK
    uuid tenant_id FK
    uuid branch_id FK
    uuid blocked_time_type_id FK
    timestamptz starts_at
    timestamptz ends_at
    text notes
    boolean all_branches
  }
  staff_members ||--o{ staff_branch_assignments : "composite FK"
  staff_members ||--o{ shifts : "composite FK"
  staff_members ||--o{ blocked_times : "composite FK"
  blocked_time_types ||--o{ blocked_times : "type FK"
```

Staff explanation: One `staff_members` row per person per tenant; login is optional (`user_id` nullable, ADR-12). A partial unique index `(tenant_id, user_id) WHERE user_id IS NOT NULL` enforces one identity per tenant (ADR-12, F-DB-9). Staff are assigned to branches via `staff_branch_assignments` with a default-branch and bookable flag. The conflict engine checks busy time across all branches a staff member is assigned to (ADR-12, ADR-24). `blocked_times` is not a direct-write table — every write goes through the locked `staff`/blocked-time RPC (advisory lock + cross-entity appointment check, ADR-26, F-DB-6). Time off spanning branches uses `all_branches = true` with `branch_id IS NULL` (ADR-20 rule 6, ADR-26). `shifts` are dated rows (`timestamptz` ranges), not weekly templates; the shift grid materializes a week of rows and supports copy-previous-week.

#### Service catalogue

```mermaid
classDiagram
  class ServiceCategory {
    +UUID id
    +UUID tenant_id
    +String name_en
    +String name_ar
    +Smallint sort_order
    +Boolean is_active
  }

  class Service {
    +UUID id
    +UUID tenant_id
    +UUID category_id
    +String name_en
    +String name_ar
    +String description_en
    +String description_ar
    +Bigint default_price_minor
    +Int default_duration_minutes
    +Int buffer_before_minutes
    +Int buffer_after_minutes
    +Boolean is_active
  }

  class ServiceBranchOverride {
    +UUID id
    +UUID service_id
    +UUID tenant_id
    +UUID branch_id
    +Bigint price_minor
    +Int duration_minutes
    +Int buffer_before_minutes
    +Int buffer_after_minutes
    +Boolean is_enabled
  }

  class ServiceStaff {
    +UUID id
    +UUID service_id
    +UUID tenant_id
    +UUID staff_id
  }

  ServiceCategory "1" --> "*" Service : groups
  Service "1" --> "*" ServiceBranchOverride : overridden at
  Service "1" --> "*" ServiceStaff : performed by
  Branch "1" --> "*" ServiceBranchOverride : has overrides
  StaffMember "1" --> "*" ServiceStaff : eligible for
```

Catalogue explanation: Services are defined at tenant level with default price (in minor units, ADR-17), duration, and buffers. `service_branch_overrides` provides per-branch deviations (price, duration, enabled) that fall back to tenant defaults when absent (ADR-13). The effective price/duration is resolved by `resolve_service(branch_id, service_id)` and snapshotted onto `appointment_items` and `sale_items` at booking/checkout time for historical accuracy. Buffers are first-class and included in the busy range but not billable (ADR-25). Staff eligibility per service per branch lives in `service_staff`. A cross-branch reschedule must re-resolve price/duration/buffers via the target branch and re-snapshot (ADR-13 round 2, F-walk-1).

#### Clients

```mermaid
classDiagram
  class Client {
    +UUID id
    +UUID tenant_id
    +String first_name
    +String last_name
    +String first_name_alt
    +String last_name_alt
    +String phone
    +String email
    +Date date_of_birth
    +String gender
    +String allergies
    +Text notes
    +String source
    +Boolean is_blocked
    +Boolean is_deleted
    +UUID merged_into
    +Timestamp created_at
    +Timestamp updated_at
  }

  class ClientNote {
    +UUID id
    +UUID client_id
    +UUID tenant_id
    +UUID author_id
    +Text content
    +Timestamp created_at
  }

  Client "1" --> "*" ClientNote : has
```

Clients explanation: Clients are tenant-scoped (shared across all branches for safety — a therapist at any branch must see allergies, ADR-11). Client financial aggregates are branch-scoped via secured RPCs, never raw client columns (ADR-11). The staff role reads only basic client fields (name, phone, allergy flags) through a column-restricted secured view limited to clients with appointments at their assigned branches, and has no writes to client master data (ADR-11, F-DB-5/F-perm-2). `is_blocked`, `is_deleted`, and `merged_into` are carved out of direct writes — they route through the `clients` Edge Function with role checks and audit (ADR-28, F-4). Duplicate warning on create (name/phone/email match, tenant-wide) with explicit proceed-and-record choice (ADR-9). `clients.source` defaults to `walk-in` or `imported`; source reporting is deferred non-committed (ADR-52).

#### Appointments and booking

```mermaid
classDiagram
  class Appointment {
    +UUID id
    +UUID tenant_id
    +UUID branch_id
    +UUID client_id
    +String ref_number
    +Timestamp scheduled_start
    +Timestamp scheduled_end
    +AppointmentStatus status
    +String notes
    +Timestamp created_at
    +Timestamp updated_at
  }

  class AppointmentItem {
    +UUID id
    +UUID appointment_id
    +UUID tenant_id
    +UUID staff_id
    +UUID service_id
    +Timestamp effective_start
    +Timestamp effective_end
    +Bigint price_minor
    +Int duration_minutes
    +Int buffer_before_minutes
    +Int buffer_after_minutes
    +String service_name_en
    +String service_name_ar
    +TsTzRange busy_range
    +Boolean status_active
  }

  class BookingOverride {
    +UUID id
    +UUID appointment_id
    +UUID tenant_id
    +UUID overridden_by
    +String rule_violated
    +Timestamp created_at
  }

  class CancellationReason {
    +UUID id
    +UUID tenant_id
    +String name_en
    +String name_ar
  }

  Appointment "1" --> "*" AppointmentItem : contains
  Appointment "1" --> "*" BookingOverride : justified by
  Appointment "*" --> "1" CancellationReason : cancelled with
  Client "1" --> "*" Appointment : booked for
  Branch "1" --> "*" Appointment : at
  StaffMember "1" --> "*" AppointmentItem : performs
  Service "1" --> "*" AppointmentItem : is
```

Appointment ER diagram:

```mermaid
erDiagram
  appointments {
    uuid id PK
    uuid tenant_id FK
    uuid branch_id FK
    uuid client_id FK
    text ref_number
    timestamptz scheduled_start
    timestamptz scheduled_end
    text status
  }
  appointment_items {
    uuid id PK
    uuid appointment_id FK
    uuid tenant_id FK
    uuid staff_id FK
    uuid service_id FK
    timestamptz effective_start
    timestamptz effective_end
    bigint price_minor
    int duration_minutes
    int buffer_before_minutes
    int buffer_after_minutes
    text service_name_en
    text service_name_ar
    tstzrange busy_range
    boolean status_active
  }
  booking_overrides {
    uuid id PK
    uuid appointment_id FK
    uuid tenant_id FK
    uuid overridden_by FK
    text rule_violated
  }
  cancellation_reasons {
    uuid id PK
    uuid tenant_id FK
    text name_en
    text name_ar
  }
  appointments ||--o{ appointment_items : "composite FK"
  appointments ||--o{ booking_overrides : "composite FK"
```

Appointments explanation: An appointment belongs to exactly one branch. `appointment_items` carry their own staff member and time span, enabling multi-service visits (sequential or parallel) inside the appointment envelope (ADR-23). Each item snapshots the resolved price, duration, buffers, and service names at booking time. `busy_range` is a trigger-maintained `tstzrange` column including buffers (BEFORE INSERT/UPDATE triggers in the validated v2 set — PGlite rejects the buffer arithmetic in a generated-column expression; on real Postgres `appointments.during` could return to `GENERATED ALWAYS`, `busy_range` stays trigger-maintained. Final round, F-final-sql-1) (`[effective_start - buffer_before, effective_end + buffer_after)`), protected by an exclusion constraint `EXCLUDE USING gist (staff_id WITH =, busy_range WITH &&) WHERE status_active` (ADR-24). The `status_active` flag is maintained by the appointment state machine — cancelled/no_show items drop out of the constraint. `ref_number` is generated by the booking RPC as `<branch invoice_prefix>-A<seq>` with `UNIQUE (branch_id, ref_number)` (ADR-14, F-DB-7). All appointment/booking_item writes go through the `bookings` Edge Function — never direct supabase-js (ADR-28).

#### Sales, payments and register

```mermaid
classDiagram
  class Sale {
    +UUID id
    +UUID tenant_id
    +UUID branch_id
    +UUID client_id
    +UUID appointment_id
    +Int invoice_seq
    +SaleStatus status
    +Bigint subtotal_minor
    +Bigint discount_total_minor
    +Bigint tax_total_minor
    +Bigint total_minor
    +Bigint due_minor
    +Timestamp created_at
  }

  class SaleItem {
    +UUID id
    +UUID sale_id
    +UUID tenant_id
    +UUID staff_id
    +UUID appointment_id
    +ItemType item_type
    +UUID service_id
    +Bigint price_minor
    +Bigint discount_minor
    +Bigint tax_minor
    +Bigint line_total_minor
    +String service_name_en
    +String service_name_ar
  }

  class Payment {
    +UUID id
    +UUID sale_id
    +UUID tenant_id
    +UUID branch_id
    +UUID client_id
    +PaymentType payment_type
    +String method
    +Bigint amount_minor
    +UUID refunds_payment_id
    +String reason
    +UUID register_session_id
    +Timestamp created_at
  }

  class Tip {
    +UUID id
    +UUID sale_id
    +UUID tenant_id
    +UUID staff_id
    +Bigint amount_minor
  }

  class RegisterSession {
    +UUID id
    +UUID branch_id
    +UUID tenant_id
    +UUID opened_by
    +UUID closed_by
    +Bigint starting_cash_minor
    +Bigint counted_cash_minor
    +Bigint difference_minor
    +Timestamp opened_at
    +Timestamp closed_at
  }

  class TaxRate {
    +UUID id
    +UUID tenant_id
    +String name
    +Int rate_bp
    +Boolean is_inclusive
  }

  Sale "1" --> "*" SaleItem : lines
  Sale "1" --> "*" Payment : paid by
  Sale "1" --> "*" Tip : tipped
  Payment "*" --> "0..1" Payment : refunds
  Payment "*" --> "0..1" RegisterSession : during
  Appointment "0..1" --> "1" Sale : from
```

Sales ER diagram:

```mermaid
erDiagram
  sales {
    uuid id PK
    uuid tenant_id FK
    uuid branch_id FK
    uuid client_id FK
    uuid appointment_id FK
    int invoice_seq
    text status
    bigint subtotal_minor
    bigint discount_total_minor
    bigint tax_total_minor
    bigint total_minor
    bigint due_minor
  }
  sale_items {
    uuid id PK
    uuid sale_id FK
    uuid tenant_id FK
    uuid staff_id FK
    uuid appointment_id FK
    text item_type
    uuid service_id FK
    bigint price_minor
    bigint discount_minor
    bigint tax_minor
    bigint line_total_minor
  }
  payments {
    uuid id PK
    uuid sale_id FK
    uuid tenant_id FK
    uuid branch_id FK
    uuid client_id FK
    text payment_type
    text method
    bigint amount_minor
    uuid refunds_payment_id FK
    text reason
    uuid register_session_id FK
  }
  tips {
    uuid id PK
    uuid sale_id FK
    uuid tenant_id FK
    uuid staff_id FK
    bigint amount_minor
  }
  register_sessions {
    uuid id PK
    uuid branch_id FK
    uuid tenant_id FK
    uuid opened_by FK
    uuid closed_by FK
    bigint starting_cash_minor
    bigint counted_cash_minor
    bigint difference_minor
    timestamptz opened_at
    timestamptz closed_at
  }
  tax_rates {
    uuid id PK
    uuid tenant_id FK
    text name
    int rate_bp
    boolean is_inclusive
  }
  sales ||--o{ sale_items : "composite FK"
  sales ||--o{ payments : "composite FK"
  sales ||--o{ tips : "composite FK"
  payments ||--o{ payments : "refunds_payment_id FK"
  register_sessions ||--o{ payments : "register_session_id FK"
```

Sales explanation: Every sale belongs to exactly one branch and records its per-branch `invoice_seq` (ADR-14). Totals are derived from line items by the checkout RPC per the deterministic calculation order bound in ADR-51 (line base → line discounts → invoice-level pro-rata allocation → tax → tips → sale total). `due_minor` is derived from lines and payments (`total - sum(payments)`) and never hand-edited; whether it is stored generated or computed at read time is decided by the active migration set (final round, F-final-arch-1). All sale-related writes go through the `checkout` Edge Function — never direct supabase-js (ADR-28). Payments use a single `payments` table with `payment_type ∈ {payment, refund}`; refunds are positive `amount_minor` rows referencing `refunds_payment_id` (ADR-34 — no separate refunds table, no negative amounts). A trigger enforces `sum(refund amounts) ≤ original payment amount`. Refunds and voids are owner/manager-only (ADR-10 round 2, F-perm-1). Register sessions link cash payments and support daily reconciliation (ADR-6). Money is `bigint` minor units (fils for KWD, ADR-17) everywhere.

#### Settings and audit

```mermaid
classDiagram
  class Setting {
    +UUID id
    +UUID tenant_id
    +UUID branch_id
    +Boolean all_branches
    +String key
    +Jsonb value
  }

  class AuditLog {
    +UUID id
    +UUID tenant_id
    +UUID branch_id
    +UUID actor_id
    +String action
    +String entity_type
    +UUID entity_id
    +Jsonb changes
    +Timestamp performed_at
  }

  class IdempotencyKey {
    +UUID id
    +UUID tenant_id
    +String key
    +String function
    +String status
    +Int response_status
    +Jsonb response_body
    +Timestamp created_at
  }

  Branch "1" --> "*" Setting : configured
  Tenant "1" --> "*" Setting : configured
  Tenant "1" --> "*" AuditLog : audited
```

Settings explanation: Settings use the same `all_branches` representation: `branch_id NULL` + `all_branches boolean` for tenant-wide rows, with a partial unique index `WHERE branch_id IS NULL` (ADR-20 rule 6). Audit rows are written only by `SECURITY DEFINER` triggers on audited tables and by Edge Function code paths; direct DML is revoked from `anon` and `authenticated` (ADR-22). `idempotency_keys` are unique on `(tenant_id, key)`; money mutations require an `Idempotency-Key` header; replay returns the cached response; 30-day expiry via `pg_cron` (ADR-31).

#### Full entity-relationship overview

```mermaid
erDiagram
  tenants ||--o{ branches : "has"
  tenants ||--o{ memberships : "authorizes"
  tenants ||--|| currencies : "uses"
  branches ||--o{ branch_opening_hours : "defines"
  branches ||--o{ closed_periods : "observes"
  branches ||--o{ staff_branch_assignments : "staff at"
  branches ||--o{ service_branch_overrides : "overrides"
  branches ||--o{ appointments : "at"
  branches ||--o{ sales : "at"
  branches ||--o{ register_sessions : "at"
  branches ||--o{ settings : "configured"
  
  staff_members ||--o{ staff_branch_assignments : "assigned"
  staff_members ||--o{ shifts : "works"
  staff_members ||--o{ blocked_times : "blocked"
  staff_members ||--o{ appointment_items : "performs"
  staff_members ||--o{ service_staff : "eligible"
  
  service_categories ||--o{ services : "groups"
  services ||--o{ service_branch_overrides : "overridden"
  services ||--o{ service_staff : "staff for"
  services ||--o{ appointment_items : "snapshotted in"
  
  clients ||--o{ appointments : "books"
  clients ||--o{ sales : "buys"
  clients ||--o{ client_notes : "noted"
  
  appointments ||--o{ appointment_items : "contains"
  appointments ||--o{ booking_overrides : "justified"
  appointments ||--o{ sales : "results in"
  
  sales ||--o{ sale_items : "lines"
  sales ||--o{ payments : "paid"
  sales ||--o{ tips : "tipped"
  
  payments ||--o{ payments : "refunds"
  register_sessions ||--o{ payments : "cash during"
  
  blocked_time_types ||--o{ blocked_times : "types"
  cancellation_reasons ||--o{ appointments : "cancelled with"
```

Full ER explanation: Every tenant-owned table carries `tenant_id`, and every foreign key to another tenant-owned table is composite on `(parent_id, tenant_id)` to enforce tenant consistency at the database level (ADR-20 rule 5). Branch-scoped tables add `branch_id`. The `all_branches` representation (`branch_id NULL` + `all_branches boolean` + `CHECK (all_branches = (branch_id IS NULL))`) applies to `memberships`, `settings`, and `blocked_times` (ADR-20 rule 6). Soft deletes: `clients.is_deleted` + `merged_into`; `is_active` on services/staff/branches; status-based retention on appointments/sales; immutable financial rows (ADR-46). All timestamps are `timestamptz` (UTC storage); each branch has an IANA timezone for rendering and day-boundary grouping (ADR-45).

---

### The validated SQL v2 migration set

The schema in the diagrams above is proven by a validation migration set under `sql/v2/` (12 migrations plus 3 test files). It is not yet the active `supabase/migrations/` set — writing that from the ADRs is Phase 0/1 work behind the clean-migration CI gate, and the diagrams must be re-checked against it afterwards (F-final-arch-1). What the validation set contains:

| Migration | Contents |
|---|---|
| `000001_enable_extensions.sql` | `btree_gist`, `pgcrypto`, `citext`, `uuid-ossp`; hosted-form `pg_cron`, `pgmq`, and `pg_net` (added in the final round, F-final-db-1) inside the checker skip block; base grants and schemas |
| `000002_create_tenants.sql` | `tenants`, `currencies`, `plan_features`, `profiles`, and the `handle_new_user` auth trigger (skip-blocked for PGlite, F-final-sql-5) |
| `000003_create_branches.sql` | `branches` (bilingual names, `invoice_prefix`, IANA timezone, calendar preferences per ADR-52), `branch_opening_hours` (seq, overnight, `is_closed`, plus the final-round `boh_nonzero_length` check), `closed_periods` |
| `000004_create_memberships.sql` | `memberships` with the four-role enum, nullable `branch_id` + `all_branches` flag (ADR-20 rules 4/6) |
| `000005_create_staff.sql` | `staff_members` (nullable `user_id`, partial unique per ADR-12), `staff_branch_assignments`, `shifts`, `blocked_time_types`, `blocked_times` (exclusion-constrained range) |
| `000006_create_services.sql` | `service_categories`, `services`, `service_branch_overrides`, `service_staff`, and the `resolve_service` RPC (returns `record` in v2; convert to `RETURNS TABLE` before production, F-final-sql-4) |
| `000007_create_clients.sql` | `clients` (tenant-scoped, soft delete, `merged_into`, `source`, normalized `search_text`), `client_notes` |
| `000008_create_appointments.sql` | `cancellation_reasons`, `appointments`, `appointment_items` (snapshots, trigger-maintained `busy_range`, `status_active`), `booking_overrides`, the partial exclusion constraint (F-final-sql-2/3) |
| `000009_create_sales.sql` | `invoice_counters` (`kind`-discriminated, `UNIQUE (branch_id, kind)`), `tax_rates`, `register_sessions` (one-open-per-branch partial unique index `idx_rs_one_open`), `sales`, `sale_items`, `tips`, `payments` (refund-cap trigger), `idempotency_keys` (`UNIQUE (tenant_id, key, function_name)` since the final round, F-final-db-3) |
| `000010_create_settings.sql` | `settings` (role-gated), `audit_log` (append-only, ADR-22) |
| `000011_create_views.sql` | `security_invoker` report views with explicit grants (ADR-21) |
| `000012_enable_rls.sql` | RLS on every table plus policies, helper functions, and role grants |

Tests: `001_tenant_isolation.sql` (cross-tenant reads/FK attacks/role checks), `002_branch_isolation.sql` (branch scope, payment restrictions, money and sequence races), `003_final_round_fixes.sql` (zero-length opening-hours rejection, overnight acceptance, per-function idempotency scope).

Checker result (`check-sql.mjs`, PGlite): 12 migrations apply cleanly; 33 public tables, 33 with RLS enabled; all three test files pass. One warning is intentional: `public.idempotency_keys` has RLS with no policies (deny-all) because it is a client-inaccessible mutation table with a select-only grant — the replay protocol runs inside Edge Functions under the service role.

Remaining production-validation gates carried from the final round: the partial exclusion constraint syntax and the `handle_new_user` trigger must be re-validated on real Supabase Postgres with the pinned CLI (F-final-sql-2/5); `resolve_service` converts to `RETURNS TABLE` (F-final-sql-4); trigger-maintained ranges need bypass/update coverage tests (F-final-sql-1); cancellation and no-show must flip `status_active` inside the booking RPC contract, with concurrent cancellation/reschedule tests in Phase 5 (F-final-sql-3).

