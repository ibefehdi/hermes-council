---
name: spa-domain-glossary
description: Shared domain vocabulary for the spa/salon SaaS (tenants, branches, staff, services, appointments, sales, payments). Use when writing or reviewing any code, migration, API, or UI text that touches these concepts, to keep table names, TypeScript types, status values, and EN/AR labels consistent.
---

# Spa domain glossary

Single source of truth for domain terms (ADR-15). Never invent synonyms; if a term is missing, add it here first. Where an older draft of this glossary disagreed with `decisions.md`, the rulings below already incorporate the fix.

## Terms

| Term | Exact meaning | Code naming (table / TS type) | EN label | AR label |
|---|---|---|---|---|
| Tenant | The buying company (e.g. SpaCorner). Owns branches, staff, clients, catalogue. Never shares data with another tenant. | `tenants` / `Tenant` | Company | الشركة |
| Branch | One physical location of a tenant, with its own hours, staff assignments, overrides, register, invoice sequence, and money records. "Location" is banned in code. | `branches` / `Branch` | Branch | الفرع |
| Staff member | A person who performs services; one tenant record with per-branch assignments. Login optional (`user_id` nullable, ADR-12). Not "employee" or "team member". | `staff_members` / `StaffMember`; assignments: `staff_branch_assignments` / `StaffBranchAssignment` | Staff member | موظف |
| Service | A bookable treatment defined at tenant level (names EN/AR, default duration, default price in minor units, buffers). | `services` / `Service` | Service | خدمة |
| Service category | Grouping of services for menus and reports. | `service_categories` / `ServiceCategory` | Category | التصنيف |
| Service branch override | Per-branch deviation (price, duration, enabled) for a service; falls back to tenant defaults when absent. | `service_branch_overrides` / `ServiceBranchOverride` | Branch override | تعديل الفرع |
| Effective price/duration | Resolved value = override if present else default; snapshotted onto the appointment/sale line at booking/checkout time. | RPC `resolve_service(branch_id, service_id)`; snapshot columns on `appointment_items` / `sale_items` | — | — |
| Client | A customer of the tenant, shared across branches (ADR-11). Never "customer" in code. | `clients` / `Client` | Client | العميل / العميلة |
| Walk-in | An appointment or sale with no client attached. `client_id = null`, never a fake client record. | — (flag) | Walk-in | بدون موعد مسبق |
| Appointment | A booked visit at one branch: one client (or walk-in), one or more items, an envelope start/end. Belongs to exactly one branch. | `appointments` / `Appointment` | Appointment | الموعد |
| Appointment item | One service line within an appointment with its own staff member, effective time span (inside the envelope), and snapshotted price/duration/buffers. Sequential or parallel with siblings (ADR-23). | `appointment_items` / `AppointmentItem` | — (shown as service lines) | — |
| Buffer | Prep/cleanup time before/after a service on a staff member's timeline; part of the busy range, not billable (ADR-25). | `buffer_before_minutes`, `buffer_after_minutes` on `services` (+ overrides, + item snapshots) | Buffer time | وقت التحضير |
| Busy range | `[effective_start - buffer_before, effective_end + buffer_after)` per appointment item; protected by an exclusion constraint (ADR-24). | `appointment_items.busy_range tstzrange` (trigger-maintained in the v2 validation set, F-final-sql-1) | — | — |
| Blocked time | Non-appointment busy time on a staff calendar (lunch, training, personal), with a type. Branch-scoped, or all-branches via `all_branches = true` (sentinel UUID withdrawn — ADR-20 rule 6 round 2). Every write goes through the locked staff RPC (ADR-26/28 round 2). | `blocked_times` / `BlockedTime`; types: `blocked_time_types` | Blocked time | وقت محجوب |
| Shift | A staff member's dated working window at one branch (`timestamptz` range; overnight allowed). Constrains bookable slots (soft rule, overridable with audit). Weekly grids materialize dated rows. | `shifts` / `Shift` | Shift | الشيفت |
| Opening hours | Per-weekday branch hours; `closes_at < opens_at` means overnight; `opens_at = closes_at` is rejected unless `is_closed` (zero-length intervals are meaningless, a 24-hour day is 00:00–23:59 — final round, F-final-db-5); split intervals via `seq`. | `branch_opening_hours` / `OpeningHours` | Opening hours | ساعات العمل |
| Closed period | Branch closure (holiday) by date range; removes all availability. | `closed_periods` / `ClosedPeriod` | Closure | إغلاق |
| Slot | A candidate start time from the availability engine (opening hours ∩ shift ∩ duration+buffers − appointments − blocked time − closures). Computed, never stored. | TS: `Slot` (`packages/core`) | Available time | وقت متاح |
| Conflict | A proposed booking overlapping a staff member's busy time (appointments + buffers + blocked time) in ANY branch. Hard constraint (ADR-12, ADR-24). | TS: `ConflictCheck` | Conflict | تعارض |
| Override (booking) | A manager confirming a booking despite a soft-rule violation (outside shift/hours). Stored with who/when/rule. | `booking_overrides` / `BookingOverride` | Override | تجاوز |
| Cancellation reason | Configurable bilingual reason required when cancelling an appointment. | `cancellation_reasons` / `CancellationReason` | Cancellation reason | سبب الإلغاء |
| Sale | The financial record of a checkout: line items, totals (derived, never free-standing), status. Called invoice on receipts; code name is always `sale`. | `sales` / `Sale` | Sale (UI: Invoice on receipt) | الفاتورة |
| Sale line item | One billable line; type-discriminated `service` \| `manual_item` in MVP (`product`, `package`, `gift_card` arrive with their phases, ADR-2). | `sale_items` / `SaleItem` | Item | البند |
| Manual item | Ad-hoc name+price line for incidental retail in MVP. | `sale_items.item_type = 'manual_item'` | Custom item | بند مخصص |
| Discount | Reduction on a line or the whole sale, fixed or percent, with a reason. Stored in `_minor` columns on `sale_items` / `sales`. | `Discount` | Discount | خصم |
| Tip | Gratuity at checkout, attributed per staff member; outside taxable net. | `tips` / `Tip` | Tip | بقشيش |
| Payment | Money-movement ledger row against a sale: method, positive `amount_minor`, actor. Types: `payment` \| `refund` (ADR-34). Online methods land in plan Phase 10 behind the provider abstraction. | `payments` / `Payment` | Payment | الدفعة |
| Refund | A `payments` row of type `refund` referencing `refunds_payment_id`, carrying a **positive** `amount_minor` (ADR-34 round 2 — no negative ledger rows); original never mutated; total refunds ≤ original amount (DB-enforced). Owner/manager only — receptionist forbidden (ADR-10 round 2). No separate refunds table. | `payments` (type `refund`) / `Refund` | Refund | استرداد |
| Void | Same-day cancellation of an erroneous sale; record retained with status `voided` + reason. | `sales.status = 'voided'` | Void | إلغاء الفاتورة |
| Register session | A branch's cash drawer for a day: opened with starting cash, closed with counted cash; difference recorded; cash payments link to it. | `register_sessions` / `RegisterSession` | Register | درج النقدية |
| Invoice number | Per-branch sequential number (`branches.invoice_prefix` + `invoice_counters`), assigned in the sale transaction; unique `(branch_id, invoice_seq)`; gaps allowed, never reused (ADR-14). | `sales.invoice_seq` | Invoice # | رقم الفاتورة |
| Appointment reference | Per-branch human-readable appointment number `<branch invoice_prefix>-A<seq>`, generated by the booking RPC from `invoice_counters (kind = 'appointment_ref')`; unique `(branch_id, ref_number)` (ADR-14 round 2, F-DB-7). | `appointments.ref_number` | Appointment # | رقم الموعد |
| Receipt | Printable record of a sale, branch-branded EN/AR. | TS: `ReceiptData` | Receipt | إيصال |
| Audit record | Append-only who/what/when/branch for every mutation (NFR-3), written by DB triggers / definer writers, never by clients (ADR-22). | `audit_log` / `AuditEntry` | Activity | السجل |
| Membership | The authorization row: user × tenant × role × branch scope (`branch_id` or `all_branches = true`; `is_active`). The only source of roles; live-looked-up per request (ADR-19). | `memberships` / `Membership` | — | — |
| Role | Capability set on a membership: `tenant_owner`, `branch_manager`, `receptionist`, `staff` (platform admin is an ops path, not a membership role). | `AppRole` (enum) | Role | الدور |
| Status values (appointment) | Fixed enum (ADR-7): `booked`, `confirmed`, `arrived`, `in_progress`, `completed`, `cancelled`, `no_show`. Store the enum, translate labels in UI. | `AppointmentStatus` | Booked/Confirmed/Arrived/In progress/Completed/Cancelled/No-show | محجوز / مؤكد / حاضر / جارٍ / مكتمل / ملغى / لم يحضر |
| Status values (sale) | Fixed enum (ADR-7): `unpaid`, `part_paid`, `completed`, `voided`. `completed` = fully paid and closed. | `SaleStatus` | — | — |
| Money | Integer count of minor units (fils; KWD exponent 3 from the `currencies` table). Columns are `bigint` named `*_minor`. Floats and `numeric` are banned (ADR-17). Calculation order and rounding are bound by ADR-51. | `amount_minor: number` (integer) | — | — |
| Currency | ISO-4217 code + minor-unit exponent (KWD = 3), one per tenant in MVP; the tenant currency locks after the first sale (US-ON-2, DB trigger in plan Phase 6). | `currencies` / `Currency` | Currency | العملة |
| Tax rate | Tenant-level rate applied at checkout, stored in basis points; per-line calculation and tax-inclusive extraction per ADR-51; retail-prices-include-tax option; Kuwait zero-rated today, model ships in MVP (plan Phase 6). | `tax_rates` / `TaxRate` | Tax rate | نسبة الضريبة |
| Client source | Optional acquisition attribution on a client (`walk-in`, `imported`, …); nullable, defaults set on create/import; source reporting deferred non-committed (ADR-52 round 2). | `clients.source` | Source | المصدر |

## Invariants

- An appointment belongs to exactly one branch; a sale belongs to exactly one branch.
- A client belongs to a tenant, never to a branch; per-client financial aggregates respect the viewer's branch scope.
- A staff member has ≥ 1 branch assignment; busy time is checked across ALL branches when booking.
- Every sale's totals derive from its line items and payments; the checkout RPC reconciles them at write time.
- Money is integer minor units everywhere; one rounding rule and calculation order (half-up, ADR-17/ADR-51).
- All timestamps stored UTC; the branch's IANA time zone drives rendering and report day boundaries.
- Refunds/voids never delete or mutate original financial records.
- Every mutation on clients, appointments, sales, payments, settings, or roles writes an audit record.
- Denormalized `tenant_id` columns and every FK to a tenant-owned table are constrained by composite foreign keys to match their parents (ADR-20 rule 5, round-2 enumeration).

## Banned words in code

`location` (use `branch`), `employee` / `team_member` (use `staff_member`), `customer` (use `client`), `booking` as a noun for the record (use `appointment`; `booking` names the act/flow), `started` as an appointment status (use `in_progress`), `branch_services` / `branch_hours` / `staff` as table names (use `service_branch_overrides` / `branch_opening_hours` / `staff_members`), `paid_plan` / `membership` as a product feature before Phase 14 (`memberships` the authorization table is fine - different concept, never abbreviated the same way in UI copy).
