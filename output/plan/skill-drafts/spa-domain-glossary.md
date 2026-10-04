---
name: spa-domain-glossary
description: Shared domain vocabulary for the spa/salon SaaS (tenants, branches, staff, services, appointments, sales, payments). Use when writing or reviewing any code, migration, API, or UI text that touches these concepts, to keep table names, TypeScript types, status values, and EN/AR labels consistent.
---

# Spa domain glossary

Single source of truth for domain terms. Never invent synonyms; if a term is missing, add it here first.

## Terms

| Term | Exact meaning | Code naming (table / TS type) | EN label | AR label |
|---|---|---|---|---|
| Tenant | The buying company (e.g. SpaCorner). Owns branches, staff, clients, catalogue. Never shares data with another tenant. | `tenants` / `Tenant` | Company | الشركة |
| Branch | One physical location of a tenant, with its own hours, staff assignments, overrides, money records, and invoice sequence. Former/current competitor wording "location" is banned in code. | `branches` / `Branch` | Branch | الفرع |
| Staff member | A person who performs services; one tenant record with per-branch assignments. May be a login user. Not called "employee" or "team member" in code. | `staff_members` / `StaffMember`; assignment row: `staff_branch_assignments` / `StaffBranchAssignment` | Staff member | موظف |
| Service | A bookable treatment defined at tenant level (name EN/AR, default duration, default price, buffers). | `services` / `Service` | Service | خدمة |
| Service category | Grouping of services for menus and reports. | `service_categories` / `ServiceCategory` | Category | التصنيف |
| Service branch override | Per-branch deviation (price, duration, enabled) for a service; falls back to tenant defaults when absent. | `service_branch_overrides` / `ServiceBranchOverride` | Branch override | تعديل الفرع |
| Effective price/duration | Resolved value = override if present else default; snapshotted onto the appointment line at booking time. | TS: `resolveService(service, branchId)`; snapshot columns on `appointment_items` | — | — |
| Client | A customer of the tenant, shared across branches (PD-tenant-1). Never "customer" in code. | `clients` / `Client` | Client | العميل / العميلة |
| Walk-in | An appointment or sale with no client attached. Represented by `client_id = null`, never a fake client record. | — (flag) | Walk-in | بدون موعد مسبق |
| Appointment | A booked visit at one branch: one client (or walk-in), one or more appointment items, one start time. Invariant: belongs to exactly one branch. | `appointments` / `Appointment` | Appointment | الموعد |
| Appointment item | One service line within an appointment, with its own staff member, price, and time span. | `appointment_items` / `AppointmentItem` | — (shown as service lines) | — |
| Buffer | Prep/cleanup time before/after a service on a staff member's timeline; blocks booking but is not billable. | `buffer_before_minutes`, `buffer_after_minutes` on `services` | Buffer time | وقت التحضير |
| Blocked time | Non-appointment busy time on a staff member's calendar (lunch, training, personal), with a type. | `blocked_times` / `BlockedTime`; types: `blocked_time_types` | Blocked time | وقت محجوب |
| Shift | A staff member's scheduled working window at one branch on one date. Constrains bookable slots (soft rule, overridable with audit). | `shifts` / `Shift` | Shift | الشيفت |
| Opening hours | Per-weekday hours of a branch; availability's outer bound. | `branch_opening_hours` / `OpeningHours` | Opening hours | ساعات العمل |
| Closed period | Branch closure (holiday); removes all availability. | `closed_periods` / `ClosedPeriod` | Closure | إغلاق |
| Slot | A candidate start time offered by the availability engine (opening hours ∩ shift ∩ duration + buffers − busy). Computed, never stored. | TS: `Slot` | Available time | وقت متاح |
| Conflict | A proposed booking overlapping a staff member's busy time (appointments + buffers + blocked time) in ANY branch. Hard constraint (PD-tenant-2). | TS: `ConflictCheck` | Conflict | تعارض |
| Override (booking) | A manager confirming a booking despite a soft-rule violation (outside shift/hours). Stored with who/when/rule. | `booking_overrides` / `BookingOverride` | Override | تجاوز |
| Cancellation reason | Configurable reason required when cancelling an appointment. | `cancellation_reasons` / `CancellationReason` | Cancellation reason | سبب الإلغاء |
| Sale | The financial record of a checkout: line items, totals, status. Also called invoice in receipts; code name is always `sale`. | `sales` / `Sale` | Sale (UI: Invoice on receipt) | الفاتورة |
| Sale line item | One billable line of a sale; type-discriminated: `service` \| `manual_item` (\| `product` in Phase 3) — PD-scope-2. | `sale_items` / `SaleItem` | Item | البند |
| Manual item | Ad-hoc name+price line for incidental retail in MVP. | `SaleItem.kind = 'manual_item'` | Custom item | بند مخصص |
| Discount | Reduction on a line or the whole sale, fixed or percent, with a reason. Signed; stored on `sale_items` or `sales`. | `discounts` (columns) / `Discount` | Discount | خصم |
| Tip | Gratuity added at checkout, attributed to staff; not part of taxable net. | `tips` / `Tip` | Tip | بقشيش |
| Payment | Money movement record against a sale: method (cash, manual_knet, bank_transfer, other …), amount, actor. Online methods land in Phase 2 behind a provider abstraction. | `payments` / `Payment` | Payment | الدفعة |
| Refund | A linked negative payment against an original payment; the original is never mutated (PD-scope-10). | `payments` with `refunds_payment_id` / `Refund` | Refund | استرداد |
| Void | Same-day cancellation of an erroneous sale; record retained with status `void` + reason. | `sales.status = 'void'` | Void | إلغاء الفاتورة |
| Register session | A day's cash drawer at a branch: opened with starting cash, closed with counted cash; difference recorded. | `register_sessions` / `RegisterSession` | Register | درج النقدية |
| Invoice number | Per-branch sequential sale number (prefix + counter), assigned at creation; gaps allowed, never reused (PD-tenant-4). | `branches.invoice_prefix`, `sales.invoice_seq` | Invoice # | رقم الفاتورة |
| Receipt | Printable record of a sale, branch-branded EN/AR. | TS: `ReceiptData` | Receipt | إيصال |
| Audit record | Append-only who/what/when for every mutation (NFR-3). | `audit_log` / `AuditEntry` | Activity | السجل |
| Role | Capability set: `owner`, `manager`, `receptionist`, `staff` (+ platform-side `support`), optionally branch-scoped via `staff_branch_assignments.role`. | `AppRole` (enum) | Role | الدور |
| Status values (appointment) | Fixed enum (PD-scope-7): `booked`, `confirmed`, `arrived`, `in_progress`, `completed`, `cancelled`, `no_show`. Store the enum, translate labels in UI. | `AppointmentStatus` | Booked/Confirmed/… | محجوز / مؤكد / حاضر / جارٍ / مكتمل / ملغى / لم يحضر |
| Status values (sale) | `draft`, `unpaid`, `part_paid`, `paid`, `completed`, `void`. `completed` = fully paid and closed. | `SaleStatus` | — | — |

## Invariants

- An appointment belongs to exactly one branch; a sale belongs to exactly one branch.
- A client belongs to a tenant, never to a branch; financial aggregates per client respect the viewer's branch scope.
- A staff member has ≥ 1 branch assignment; their busy time is checked across all branches when booking.
- Every sale's totals derive from its line items and payments — never stored without them.
- Money is an integer count of minor units (fils, 3 dp for KWD); floats are forbidden everywhere (PD-money-1).
- All timestamps stored in UTC; a branch's IANA time zone drives rendering.
- Refunds/voids never delete or mutate original financial records.
- Every mutation on clients, appointments, sales, payments, settings, or roles writes an audit record.

## Banned words in code

`location` (use `branch`), `employee` / `team_member` (use `staff_member`), `customer` (use `client`), `booking` as a noun for the record (use `appointment`; `booking` is reserved for the act/flow), `paid_plan` / `membership` before Phase 3 lands.
