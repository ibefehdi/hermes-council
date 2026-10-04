## Appendix

### Conventions summary

The full binding text is `CONVENTIONS.md`; the skills carry the operational detail. What a builder must not get wrong:

- Repository: pnpm monorepo (ADR-36) — `apps/back-office` (MVP) and `apps/booking` (Phase 9 scaffold) over `packages/{ui,db,api,validation,i18n,core}` plus `supabase/`. Frontend and backend deploy from the same commit. Import boundaries are lint-enforced; `packages/validation` stays pure JS so Deno imports it unchanged.
- Naming: the domain glossary below is the naming authority (ADR-15); banned synonyms are a lint/review matter. Tables plural `snake_case`; columns `snake_case` without table prefix (snapshot columns on item tables are the one exception, `{entity}_name_{locale}`); UUID primary keys everywhere (ADR-44); every tenant-owned FK is composite on `(parent_id, tenant_id)` (ADR-20 rule 5); enums are fixed CHECK constraints.
- Money: `bigint` minor units, column names end in `_minor`, never float or numeric (ADR-17); the calculation order and rounding are bound by ADR-51 (line base, line discounts, invoice discount pro-rata allocation, tax in basis points, tips outside the taxable base, totals derived and recomputed server-side). Formatting happens only at render.
- API: one envelope `{ok, data}` / `{ok, error:{code, message, fieldErrors?, details?}}` with the nine-code catalogue defined once in `packages/validation` (ADR-29); public invocation shape `/<function>/<action>` (ADR-30); invariant-bearing writes call typed wrappers in `packages/api`; money mutations send a client-generated `Idempotency-Key` header, and since the final round the replay boundary is per function (`UNIQUE (tenant_id, key, function_name)`, ADR-31 revised).
- Tenancy: `memberships` is the authorization source, looked up live per request; the JWT is identity only (ADR-19). The four-role enum is closed. Refunds/voids are owner/manager only; client CSV import and client-contact exports are owner-only. Feature gating uses `plan_features` entitlements; no runtime flags in MVP.
- Data access: reads go direct via supabase-js under RLS; the direct-write allowlist is exactly `profiles` (self), `client_notes` (receptionist+), `clients` contact fields (receptionist+, with `is_blocked`/`is_deleted`/`merged_into` carved out through the `clients` function), `settings` (role-gated), `shifts` (manager-gated). Everything money-, conflict-, or provisioning-shaped goes through an Edge Function or RPC (ADR-28). Adding to the allowlist requires a PR showing the policies that make it safe.
- Time: store `timestamptz` UTC; render and group in the branch's IANA zone; every daily metric is the branch-local calendar date converted to UTC predicates (ADR-45). Opening hours support overnight (`closes_at < opens_at`) and split intervals via `seq`; zero-length intervals are rejected unless `is_closed` (ADR-26 revised).
- i18n: Lingui ICU catalogs, logical CSS properties only (stylelint-enforced), `flipOnRtl` as the single icon-mirroring primitive, KWD with 3 decimals via centralized Intl helpers, and normalized Arabic-capable `search_text` with a trigram index (ADR-40). Missing Arabic translations fail CI.
- Testing: pgTAP per table x operation x role plus cross-tenant/cross-branch/anon cases on every migration; concurrency tests are booking acceptance criteria (ADR-24); Deno tests per Edge Function action; `packages/core` money/time math at >=95% coverage against the ADR-51 golden fixtures; Playwright journeys in both locales; the clean-migration CI gate (reset, gen types, build, `supabase test db`, adversarial fixtures, drafts-v1 reference check) is the schema proof (F-verifier-2).
- Git: `main` (production, deploy only from here), `staging` (Supabase preview branch), short-lived `feat/`, `fix/`, `db/` branches; Conventional Commits with the types `feat, fix, db, fn, refactor, test, docs, chore, i18n`; one PR per backlog task; the CONVENTIONS PR checklist is the review script.
- Definition of done: merged behind policies with `pnpm verify` green; RLS + pgTAP for every touched table; integer money end to end with reconciliation to the fil; both locales with RTL working; audit records written; function isolation preserved; docs/skills updated if a convention changed; acceptance criteria demonstrably met in both locales.

### Skills index

Seven skills ship with the plan under `skills/` (identical copies for `.cursor` and `.claude`). They are the operational how-to layer; PLAN.md and the ADRs are the what and why.

| Skill | What it covers | When it triggers |
|---|---|---|
| `spa-domain-glossary` | Canonical terms, table/type names, status enums, EN/AR labels, invariants, banned words | Writing or reviewing any code, migration, API, or UI text touching domain concepts |
| `spa-platform-architecture` | Architecture map: where new code lives, tenancy/branch scoping, data-path choice (supabase-js vs Edge Function vs RPC), monorepo and environments | "New feature — where does this go?", tenant/branch/RLS/data-access questions |
| `supabase-database` | Migration workflow, naming, money as bigint minor units, RLS policy templates with branch scope, authorization helpers, exclusion constraints, audit triggers, secure report views, pgTAP; extension list includes `pg_cron`, `pgmq`, and `pg_net` (final round) | Writing migrations, schemas, RLS, functions/triggers, or database tests |
| `supabase-edge-functions` | Bounded-context function layout, `_shared` server wrapper and auth modes, live-membership tenant context, envelope and error codes, shared Zod validation, idempotency for money mutations, pg_cron/pgmq async work, deno test, deploy commands | Creating, editing, or deploying Edge Functions |
| `react-frontend` | Back-office SPA structure, TanStack Query with scope-aware key factories, data-access rules, React Hook Form + Zod, ApiError handling, realtime cache patching, Vitest/Playwright | Adding or modifying a screen, route, query, mutation, or form |
| `i18n-rtl` | Lingui catalogs and ICU plurals (all six Arabic categories), RTL with logical CSS, mirrored icons, Intl formatting of minor-unit money and branch-zone dates, Arabic search normalization | Adding user-facing text, plurals, formatters, layout rules, or searchable text |
| `feature-delivery` | The end-to-end path for one backlog task: migration → RLS + pgTAP → generated types → Zod schema → function/RPC → UI → tests → merged PR; definition of done, commit format, PR checklist | Picking up any DB / Edge Function / Frontend / Ops backlog task or reviewing such a PR |

### Glossary

The glossary below is copied from the `spa-domain-glossary` skill (the naming authority, ADR-15), with the final-round corrections applied. If a term is missing, add it to the skill first, then use it.


Single source of truth for domain terms (ADR-15). Never invent synonyms; if a term is missing, add it here first. Where an older draft of this glossary disagreed with `decisions.md`, the rulings below already incorporate the fix.

### Domain terms

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
| Busy range | `[effective_start - buffer_before, effective_end + buffer_after)` per appointment item; protected by an exclusion constraint (ADR-24). | `appointment_items.busy_range tstzrange` (trigger-maintained in the v2 validation set; on real Postgres `during` may return to generated — F-final-sql-1) | — | — |
| Blocked time | Non-appointment busy time on a staff calendar (lunch, training, personal), with a type. Branch-scoped, or all-branches via `all_branches = true` (sentinel UUID withdrawn — ADR-20 rule 6 round 2). Every write goes through the locked staff RPC (ADR-26/28 round 2). | `blocked_times` / `BlockedTime`; types: `blocked_time_types` | Blocked time | وقت محجوب |
| Shift | A staff member's dated working window at one branch (`timestamptz` range; overnight allowed). Constrains bookable slots (soft rule, overridable with audit). Weekly grids materialize dated rows. | `shifts` / `Shift` | Shift | الشيفت |
| Opening hours | Per-weekday branch hours; `closes_at < opens_at` means overnight; `opens_at = closes_at` is rejected unless `is_closed` (zero-length intervals are meaningless, a 24-hour day is 00:00-23:59 — final round, F-final-db-5); split intervals via `seq`. | `branch_opening_hours` / `OpeningHours` | Opening hours | ساعات العمل |
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

### Invariants

- An appointment belongs to exactly one branch; a sale belongs to exactly one branch.
- A client belongs to a tenant, never to a branch; per-client financial aggregates respect the viewer's branch scope.
- A staff member has ≥ 1 branch assignment; busy time is checked across ALL branches when booking.
- Every sale's totals derive from its line items and payments; the checkout RPC reconciles them at write time.
- Money is integer minor units everywhere; one rounding rule and calculation order (half-up, ADR-17/ADR-51).
- All timestamps stored UTC; the branch's IANA time zone drives rendering and report day boundaries.
- Refunds/voids never delete or mutate original financial records.
- Every mutation on clients, appointments, sales, payments, settings, or roles writes an audit record.
- Denormalized `tenant_id` columns and every FK to a tenant-owned table are constrained by composite foreign keys to match their parents (ADR-20 rule 5, round-2 enumeration).

### Banned words in code

`location` (use `branch`), `employee` / `team_member` (use `staff_member`), `customer` (use `client`), `booking` as a noun for the record (use `appointment`; `booking` names the act/flow), `started` as an appointment status (use `in_progress`), `branch_services` / `branch_hours` / `staff` as table names (use `service_branch_overrides` / `branch_opening_hours` / `staff_members`), `paid_plan` / `membership` as a product feature before Phase 14 (`memberships` the authorization table is fine - different concept, never abbreviated the same way in UI copy).


### Source documents

This PLAN.md was assembled from the council corpus in `/Users/fahad/council/output/`. Nothing outside it was used except the cited public documentation URLs.

Plan corpus (binding alongside PLAN.md):

- `plan/decisions.md` — the 53 ADRs, full binding text, with the final-round revisions marked
- `plan/CONVENTIONS.md` — the conventions map (summarized above)
- `plan/IMPLEMENTATION_PLAN.md` — the revised round-2 implementation plan (superseded in detail by the Delivery plan section where they differ)
- `plan/REVISION_LOG.md` — what changed in each round, including the final round
- `plan/sql/v2/` — the validated migration set (12 migrations) and tests (3 files), plus `plan/sql/README.md`; `plan/sql/drafts-v1/` is the quarantined round-1 SQL and must never be applied
- `plan/skills/` — the seven skills indexed above (identical `.cursor` and `.claude` copies)

Earlier rounds (historical inputs, superseded per the precedence rule): `plan/requirements.md` (product intent), `plan/data-model.md`, `plan/backend.md`, `plan/frontend.md`, `plan/review.md`, `plan/review2/` (the four adversarial audits and `adjudication.md`), `plan/round1/`.

Final round: `plan/final/briefs/` (common + member + verifier + chair briefs), `plan/final/drafts/` (the five member drafts), `plan/final/verification.md` (the gate report whose corrections this document applies).

Fresha evidence corpus (read-only, never modified): `FINAL_REPORT.md` (page map and journeys), `TECHNICAL_REPORT.md` (deep pass), `pages.md` / `pages.json` / `links.md` (page inventory), `technical/*.md` (flows, settings, reports, architecture, gaps).
