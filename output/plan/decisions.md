# Decisions: architecture decision records (chair rulings)

This file is the authoritative record of every significant decision for the GlowDesk multi-tenant spa/salon SaaS. It rules on all proposed decisions (PD-*) from the council members, resolves the eight cross-area conflicts and answers the ten open questions in `review.md`. Every later document (IMPLEMENTATION_PLAN.md, CONVENTIONS.md, the skills) follows these rulings; where a member document disagrees with this file, this file wins.

Conventions used below:

- Status: **Accepted** (build it as ruled), **Accepted with changes** (accepted plus the stated corrections, which are binding), **Rejected** (do not build), **Deferred** (revisit at the named phase).
- Source: which member proposed it and the verifier's verdict from `review.md`.
- Money amounts are integer minor units (fils for KWD) per ADR-17. Table and term names follow the domain glossary per ADR-15.
- **Phase numbers** in this file and every plan artifact refer to IMPLEMENTATION_PLAN.md Phases 0–17. The former release-bucket numbering ("Phase 2" = online presence, "Phase 3" = growth) maps as: release Phase 2 = plan Phases 9–11; release Phase 3 = plan Phases 12–17. Round 2 swept every bare "Phase 2/3" reference to plan numbering (F-PLAN-3/F-3).
- **Document precedence (round 2, F-verifier-1)**: the binding ADRs in this file and the current IMPLEMENTATION_PLAN.md govern. requirements.md is product intent. CONVENTIONS.md, active SQL, and the skills must conform to the ADRs. Round-1 member drafts (backend.md, frontend.md, data-model.md, requirements.md, review.md) and the quarantined SQL under `sql/drafts-v1/` are superseded wherever they disagree; superseded artifacts carry a banner or live outside the active migration path.
- **Post-MVP phases (9–17) are specified to decision level only**; their per-task backlogs are produced at scheduling time, per the IMPLEMENTATION_PLAN note. This is an explicit, recorded exception to the round-1 chair brief's per-phase backlog requirement (round 2, F-PLAN-17). The expanded post-MVP detail in PLAN.md is illustrative scheduling input under this convention, not a binding backlog.
- **Final round**: ADRs revised during the final verification round carry a `Revised in final round: <ids>` line in their entry; ADR-53 was added in the final round. The final-round fixes also updated `CONVENTIONS.md`, the skills, the validated SQL v2 set (`pg_net`, idempotency unique scope, `boh_nonzero_length` check, test `003_final_round_fixes.sql`), and PLAN.md.

## Summary table

| ADR | Title | Status |
|---|---|---|
| 1 | Online booking is plan Phase 9, not MVP | Accepted |
| 2 | Inventory is plan Phase 13; manual sale items in MVP | Accepted with changes |
| 3 | Packages, gift cards, memberships are plan Phase 14 | Accepted |
| 4 | MVP conflict dimensions are staff + time only | Accepted with changes |
| 5 | MVP report set is six reports | Accepted with changes |
| 6 | Register sessions are in MVP | Accepted with changes |
| 7 | Fixed appointment status enum, `in_progress` | Accepted with changes |
| 8 | Repeating series plan Phase 11, no series columns in MVP | Accepted |
| 9 | Duplicate warning in MVP, merge tool plan Phase 11 | Accepted with changes |
| 10 | Full refunds and void in MVP | Accepted with changes |
| 11 | Clients are tenant-scoped; financial aggregates branch-scoped | Accepted with changes |
| 12 | Staff: one tenant record, branch assignments, nullable login | Accepted with changes |
| 13 | Service branch overrides as override rows | Accepted with changes |
| 14 | Invoice numbering is per branch | Accepted with changes |
| 15 | Domain glossary is the naming authority | Accepted |
| 16 | Bilingual name columns where operators see names | Accepted |
| 17 | Money is integer minor units (`bigint`) | Accepted (PD-DB-3 Rejected) |
| 18 | Subscription billing, minimal entitlement row | Accepted |
| 19 | Authorization from live membership lookup; JWT is identity only | Accepted (PD-BACKEND-3 Rejected) |
| 20 | Branch-scoped RLS architecture | Accepted with changes |
| 21 | Reports via `security_invoker` views and secured RPCs | Accepted |
| 22 | Audit log is append-only, written by triggers | Accepted |
| 23 | Appointment items carry their own staff and time span | Accepted |
| 24 | Double-booking: exclusion constraints plus per-staff advisory lock | Accepted with changes |
| 25 | Buffers are snapshotted and included in busy ranges | Accepted |
| 26 | Opening hours, closed periods, blocked time representation | Accepted |
| 27 | One Edge Function per bounded context | Accepted with changes |
| 28 | Hybrid data access with an explicit direct-write allowlist | Accepted with changes |
| 29 | One API envelope and one error code catalogue | Accepted |
| 30 | Public invocation shape: `/<function>/<action>` | Accepted |
| 31 | Idempotency keys for money mutations | Accepted |
| 32 | Shared Edge Function code via `_shared/` | Accepted with changes |
| 33 | Async work via pg_cron + pgmq, idempotent consumers | Accepted with changes |
| 34 | Payments: manual methods in MVP, MyFatoorah plan Phase 10 behind abstraction | Accepted with changes |
| 35 | Pin and CI-verify the Supabase server wrapper | Accepted |
| 36 | pnpm monorepo, two apps, six packages | Accepted |
| 37 | Branch context in URL, tenant context in session | Accepted with changes |
| 38 | TanStack Query keys carry tenant and branch scope | Accepted with changes |
| 39 | React Hook Form + Zod schemas shared with Deno | Accepted with changes |
| 40 | Lingui ICU + logical CSS + Intl formatting | Accepted with changes |
| 41 | schedule-x with premium resource views, conditional on a spike | Accepted with changes |
| 42 | TanStack Router with typed search params | Accepted |
| 43 | Exports stream from Edge Functions; Storage comes in plan Phase 9 | Accepted |
| 44 | UUID primary keys | Accepted |
| 45 | `timestamptz` + IANA zone per branch | Accepted with changes |
| 46 | Mixed soft delete and status-based retention | Accepted with changes |
| 47 | Rate limiting: platform limits in MVP, per-tenant limiter designed in plan Phase 9 | Accepted (round 2) |
| 48 | Data residency: production region decided with a legal verification gate | Accepted (round 2) |
| 49 | Backups, PITR, RPO/RTO, and restore drills | Accepted (round 2) |
| 50 | Tenant offboarding and data deletion contract | Accepted (round 2) |
| 51 | Deterministic checkout calculation order and rounding | Accepted (round 2) |
| 52 | Round-2 model additions: branch calendar preferences, client source | Accepted (round 2) |
| 53 | MVP staff time-off is manager-created blocked time | Accepted (final round) |

## Rulings on the verifier's open questions

1. **Money representation**: integer minor units (ADR-17). `numeric(12,3)` is rejected.
2. **Multiple tenant memberships**: allowed. The active tenant is application context, verified server-side on every privileged operation (ADR-19, ADR-37).
3. **Non-login staff**: supported. `staff_members.user_id` is nullable (ADR-12).
4. **Receptionist client visibility**: tenant-wide client contact and history are visible (safety requirement: allergies); financial aggregates are branch-scoped (ADR-11).
5. **Multi-service visits in MVP**: yes. Appointment items carry their own staff member and time span, sequential or parallel inside the appointment window (ADR-23).
6. **Manual payment methods / refund model**: fixed enum `cash | card_terminal | knet_terminal | bank_transfer | other`, enabled per branch; refunds are `payments` rows with `payment_type = 'refund'` and a **positive** `amount_minor` referencing the original payment (`refunds_payment_id`); no separate refunds table (ADR-34, clarified in round 2, F-PLAN-2).
7. **Tenant creation**: platform-admin only, through the `onboarding` Edge Function with the service role; no direct insert policy on `tenants` (ADR-20).
8. **Auth Hook mechanism**: none in MVP. JWT carries identity only; authorization is a live database lookup (ADR-19). A Custom Access Token hook may be revisited as a cache optimization after MVP, never as the authorization source.
9. **schedule-x premium**: budget approved conditionally; go/no-go after a one-week Phase 0 spike, with the documented fallback (ADR-41).
10. **Exports and avatars in MVP**: CSV exports stream from an Edge Function (no Storage bucket in MVP); avatars and any file uploads come in plan Phase 9 with tenant/branch-prefixed paths and Storage RLS defined first (ADR-43).

---

## Section 1: Product scope

### ADR-1: Online booking is plan Phase 9, not MVP
- Status: Accepted.
- Context: Online booking is the highest-demand feature, but MVP must deliver staff-facing core operations for SpaCorner with zero external dependencies.
- Decision: MVP is back-office only. Plan Phase 9 adds the public booking page (`apps/booking`), shareable links/QR, and reminders. The slot engine and conflict rules built in MVP must be reusable as a service for public traffic.
- Alternatives: include online booking in MVP (rejected: public traffic, abuse protection, and payment questions widen the surface); never build it (rejected: it is the main post-MVP value).
- Consequences: the plan Phase 9 plan must carry a public-booking threat model (rate limits, abuse prevention) per the verifier; ADR-47 names the owner and scope of that threat model. No staff-only assumptions may leak into the conflict model.
- Revised in round 2: F-PLAN-3/F-3 (phase numbering).
- Source: requirements PD-scope-1; verifier AGREE.

### ADR-2: Inventory is plan Phase 13; MVP checkout supports a manual item line
- Status: Accepted with changes.
- Context: SpaCorner is services-first, but incidental retail happens at the desk.
- Decision: no product/SKU/stock model in MVP. `sale_items.item_type` supports `service` and `manual_item` in MVP; `product`, `package`, `gift_card` are added by later migrations when their phases land.
- Alternatives: full inventory in MVP (rejected: months of scope); no retail at all (rejected: operators will improvise outside the system).
- Consequences: **Binding correction**: the draft SQL check constraint omitted `manual_item`; the MVP migration must include it. The quick-sale story US-CO-5 depends on it. Round 2 (F-cov-4): the draft's `service_charge_total numeric(12,3)` column is rejected with the rest of the drafts-v1 SQL; a "service charges" feature has no requirements home and is deferred non-committed — if it is ever scheduled it must use `_minor bigint` money columns and be assigned to a named phase.
- Revised in round 2: F-PLAN-3/F-3, F-cov-4.
- Source: requirements PD-scope-2; verifier AGREE WITH CHANGES.

### ADR-3: Packages, gift cards, memberships are plan Phase 14, in that order
- Status: Accepted.
- Context: all three create prepaid liabilities; memberships additionally need recurring card billing (KNET cannot do merchant-initiated recurring charges — labeled a provider-specific assumption re-verified at plan Phase 10 discovery, see ADR-34 round-2 amendment).
- Decision: defer as a group to plan Phase 14; build packages first (no gateway dependency), then gift cards, then memberships on tokenized cards.
- Alternatives: bundle earlier (rejected: liability accounting plus gateway dependency).
- Consequences: no schema may hardcode "sale = appointment services"; `sale_items.item_type` stays extensible (ADR-2).
- Revised in round 2: F-PLAN-3/F-3, F-DB-12.
- Source: requirements PD-scope-3; verifier AGREE.

### ADR-4: MVP conflict dimensions are staff + time only; resources/rooms are plan Phase 15
- Status: Accepted with changes.
- Context: a resource dimension doubles the conflict engine and calendar UI.
- Decision: MVP conflict checking covers staff busy time only. The conflict engine interface takes a list of "busy sources" so a resource dimension can be added without rewriting it.
- Alternatives: build resources now (rejected: scope); hardcode staff-only internals (rejected: plan Phase 15 rewrite).
- Consequences: **Binding correction**: no `resources` table and no resource checks in any MVP migration or trigger (the draft `000007_create_resources.sql` is out of MVP scope; it returns in the plan Phase 15 migration set). Calendar stays one column per staff member.
- Revised in round 2: F-PLAN-3/F-3.
- Source: requirements PD-scope-4; verifier AGREE WITH CHANGES.

### ADR-5: MVP report set is the six reports US-RPT-1..6
- Status: Accepted with changes.
- Context: Fresha has 59 reports; most belong to features we defer.
- Decision: ship six reports (sales summary, payments summary, appointments summary, client list, staff performance, shifts) on a generic report framework (date presets, branch filter scoped by role, CSV export, EN/AR labels, RTL). Metric definitions as written in requirements §4.8, including cancellation rate = cancelled ÷ (completed + cancelled + no_show).
- Alternatives: Fresha-scale reporting engine now (rejected); fewer reports (rejected: these six are the operator-critical set).
- Consequences: **Binding correction**: every report view/RPC must be branch-scoped for branch-scoped roles and must group dates in the branch's IANA time zone (ADR-21, ADR-45). The draft views did neither. Round 2 additions: (F-cov-3) a taxes summary report (by rate, by period, collected vs refunded) is added to plan Phase 7 as an additive seventh report — tax collection without a reconciliation output cannot be called MVP-ready. (F-cov-2) rich KPI dashboards, comparison-period reports ("sales by time period", "performance over time"), and the "performance insights" drawer are deferred non-committed; if the product schedules them they form a separate "dashboards & analytics" workstream after plan Phase 12 data exists, with its own phase plan — the requirements' bare "Phase 3" placement reads as this deferral and is not an executable commitment.
- Revised in round 2: F-cov-2, F-cov-3.
- Source: requirements PD-scope-5; verifier AGREE WITH CHANGES.

### ADR-6: Register sessions (cash open/close) are in MVP
- Status: Accepted with changes.
- Context: daily cash reconciliation is standard practice in Kuwaiti salons.
- Decision: minimal register: open with starting cash, close with counted cash, difference recorded, per branch, one open session at a time. No multi-register, no float transfers in MVP.
- Alternatives: defer (rejected: cash control is a daily need); full register suite (rejected: scope).
- Consequences: **Binding correction**: add `register_sessions` to the schema and migration list (it existed only as a glossary concept); `payments.register_session_id` links cash taken during a session; the daily sales summary shows expected vs counted. Round 2 (F-walk-2): cash refunds executed when the branch has no open register session are allowed (they are manager-approved per ADR-10) and are recorded against the sale with `register_session_id IS NULL`, flagged in the daily summary and audit as out-of-session cash movements; cash payments *in* still require an open session per branch config. Ledger and register tests cover both paths.
- Revised in round 2: F-walk-2.
- Source: requirements PD-scope-6; verifier AGREE WITH CHANGES.

### ADR-7: Fixed appointment status enum; the canonical value is `in_progress`
- Status: Accepted with changes.
- Context: documents disagreed between `started` and `in_progress`.
- Decision: appointment status is a fixed enum: `booked, confirmed, arrived, in_progress, completed, cancelled, no_show`. Transitions form a code-level state machine; only legal transitions are allowed (manager override for backward moves, audit-logged). Custom statuses are deferred non-committed; if automations need them they are scheduled with plan Phase 12 (marketing & automations) — round 2, F-cov-5. Sale status enum is fixed too: `unpaid, part_paid, completed, voided` (the glossary's `draft` and `paid` are dropped as redundant; `completed` means fully paid and closed; the drafts' `refunded` sale status is rejected — refunds are ledger rows, ADR-34).
- Alternatives: configurable statuses now (rejected: they only matter with automations); `started` (rejected: glossary and user stories already say `in_progress`).
- Consequences: **Binding correction**: all SQL checks, queries, translations, diagrams, and skills use `in_progress`; any occurrence of `started` in draft SQL is wrong. Requirements §1.1's "Started" wording is superseded by this ADR per the precedence rule (round 2, F-term-1).
- Revised in round 2: F-cov-5, F-term-1, F-PLAN-2.
- Source: requirements PD-scope-7; verifier AGREE WITH CHANGES (conflict 3 ruled).

### ADR-8: Repeating appointment series are plan Phase 11; no series columns in MVP
- Status: Accepted.
- Context: series complicate reschedule/cancel semantics and conflict checking.
- Decision: single appointments only in MVP. **Chair ruling on the reserved-column question: do not add a nullable `series_id` reservation.** Adding a nullable column later is a cheap, safe migration; carrying a dead column through MVP is not.
- Alternatives: MVP series (rejected); nullable reservation (rejected as above).
- Consequences: plan Phase 11 adds `appointment_series` plus per-occurrence edit/cancel semantics.
- Revised in round 2: F-PLAN-3/F-3.
- Source: requirements PD-scope-8; verifier AGREE.

### ADR-9: Duplicate clients: warn in MVP, merge tool in plan Phase 11
- Status: Accepted with changes.
- Context: families share phone numbers; CSV imports create duplicates.
- Decision: duplicate warning on create (name/phone/email match, tenant-wide) with an explicit proceed-and-record choice; import offers skip/merge/create per duplicate. Interactive merge (reassigning appointments and sales) is plan Phase 11.
- Alternatives: build merge now (rejected: scope); ignore duplicates (rejected: data quality).
- Consequences: **Binding correction**: `clients.merged_into uuid NULL REFERENCES clients(id)` ships in the MVP migration as promised; merged clients are tombstoned (queries follow the pointer).
- Revised in round 2: F-PLAN-3/F-3.
- Source: requirements PD-scope-9; verifier AGREE WITH CHANGES.

### ADR-10: Full refunds and same-day void in MVP; partial refunds plan Phase 10
- Status: Accepted with changes.
- Context: refunds against cash are simple; partial refunds matter mostly with online payments.
- Decision: full refund of a payment and same-day void of a sale in MVP. A refund never mutates or deletes the original record. Voiding requires a reason and keeps the sale with status `voided`.
- Alternatives: complete refund matrix now (rejected: partial refunds need gateway machinery).
- Consequences: **Binding corrections**: refunds are role-restricted (manager and above) and branch-scoped; the database enforces `total refunded ≤ original payment amount` (trigger on `payments`); sales totals net refunds automatically. See ADR-34 for the ledger model. Round 2 (F-perm-1, blocker): refunds and voids are **owner + branch manager only; receptionists are forbidden** (`FORBIDDEN`). The requirements §3 matrix cell that lumped "refunds, voids" together with checkout/discounts/tips for receptionists is superseded by this ADR per the precedence rule: receptionists keep checkout, discounts, and tips. The `checkout` function enforces the split server-side (never UI-only), and the plan Phase 6 ACL tests pin both the allowed and forbidden paths.
- Revised in round 2: F-perm-1, F-PLAN-3/F-3.
- Source: requirements PD-scope-10; verifier AGREE WITH CHANGES.

## Section 2: Tenancy and domain model

### ADR-11: Clients belong to the tenant; financial aggregates respect branch scope
- Status: Accepted with changes.
- Context: clients visit whichever branch they like; branch-scoped clients would fragment history. Safety requires cross-branch visibility of allergies and notes.
- Decision: `clients` is tenant-scoped (RLS tenant-level). Every appointment and sale records its branch, so per-branch history falls out of the data. Client contact data, notes, and allergies are readable tenant-wide by client-facing roles.
- Alternatives: branch-scoped clients (rejected: data-quality disaster); tenant-wide everything including financials (rejected: violates the role matrix).
- Consequences: **Binding correction** (conflict 8 ruled): the client profile's financial aggregates (lifetime value, balances, visit spend) come from secured RPCs that filter by the caller's branch scope, never from the raw client row or an unscoped view. Client contact export stays owner-only (US-SEC-3). Round 2 amendments: (F-verifier-3) the report/export privacy boundary is binding — client lookup and safety fields (allergies) may be read tenant-wide by client-facing roles for booking/safety; financial and operational aggregates stay branch-scoped; client contact/allergy CSV exports are owner-only; allergy detail is redacted from ordinary aggregate reports; role/branch negative export tests are required in plan Phase 7. (F-DB-5/F-perm-2) the staff role reads only basic client fields (name, phone, allergy flags) through a column-restricted secured view limited to clients with appointments at the staff member's assigned branches, and has **no writes** to client master data, notes, or allergies in MVP (receptionist and above write); staff sales visibility is exposed through a `report_own_sales` secured RPC/view joining their own `sale_items`/`tips`, never through branch-wide `sales` SELECT.
- Revised in round 2: F-verifier-3, F-DB-5, F-perm-2.
- Source: requirements PD-tenant-1; verifier AGREE (financial aggregates must be branch-filtered).

### ADR-12: Staff are single tenant records with branch assignments; login optional
- Status: Accepted with changes.
- Context: a therapist may work at two branches; double-booking must be prevented across branches; some staff have no login.
- Decision: one `staff_members` row per person per tenant, plus `staff_branch_assignments` rows (with default-branch flag and bookable flag). The conflict engine checks busy time across all branches. `staff_members.user_id` is **nullable** (open question 3 ruled): non-login staff exist as records and appear in schedules and reports like everyone else; they simply never authenticate.
- Alternatives: per-branch staff duplicates (rejected: identity fragmentation); mandatory login (rejected: real salons have non-system staff).
- Consequences: **Binding corrections**: `staff_branch_assignments` (and every denormalized `tenant_id` column) is constrained with composite foreign keys so a row cannot pair tenant A's `tenant_id` with tenant B's staff or branch (verifier HIGH finding; enumerated in ADR-20 rule 5, round 2). Calendar queries join assignments; the booking path serializes per staff member (ADR-24). Round 2 (F-DB-9): the one-row-per-person-per-tenant invariant is enforced by `CREATE UNIQUE INDEX staff_members_tenant_user ON staff_members(tenant_id, user_id) WHERE user_id IS NOT NULL;` (partial because `user_id` is nullable for non-login staff), with a plan Phase 2 test.
- Revised in round 2: F-DB-3, F-DB-9.
- Source: requirements PD-tenant-2; verifier AGREE WITH CHANGES; conflict 7 ruled (nullable `user_id`).

### ADR-13: Services use branch override rows
- Status: Accepted with changes.
- Context: the same service has different price/duration/availability per branch.
- Decision: tenant-level `services` (definition, defaults) plus `service_branch_overrides` rows (price, duration, enabled) that fall back to defaults when absent. Effective values are resolved in a view/RPC and **snapshotted onto `appointment_items` and `sale_items` at booking/checkout time** for historical accuracy. Staff eligibility per service per branch lives in `service_staff`.
- Alternatives: copy the service per branch (rejected: update propagation); resolve at read time only (rejected: history would drift when prices change).
- Consequences: **Binding corrections**: the table is named `service_branch_overrides` (the draft SQL's `branch_services` is renamed to match the glossary, ADR-15); override rows enforce that branch, service, and tenant all belong together via composite foreign keys; the UI shows which branches deviate. Round 2 (F-walk-1, money-correctness): a cross-branch reschedule **must** re-resolve price, duration, and buffers via `resolve_service(target_branch_id, service_id)` and re-snapshot the new values onto the moved items; reusing the old branch's snapshot is a billing error and prohibited. The audit record carries both old and new resolved values. This is acceptance-tested in plan Phase 5.
- Revised in round 2: F-walk-1.
- Source: requirements PD-tenant-3; verifier AGREE WITH CHANGES.

### ADR-14: Invoice numbering is per branch, sequential, gap-tolerant
- Status: Accepted with changes.
- Context: documents disagreed between per-tenant and per-branch uniqueness (conflict, PD-tenant-4).
- Decision: **Per branch is authoritative.** Each branch has `invoice_prefix` and its own counter (`invoice_counters`, one row per branch, race-safe `UPDATE ... RETURNING` under row lock). A sale gets `(branch_id, invoice_seq)` unique across the branch; numbers are never reused; gaps after failed transactions are allowed and documented. Receipts show `PREFIX-SEQ`.
- Alternatives: tenant-global sequence (rejected: operators think per branch; the draft SQL's `(tenant_id, sale_number)` unique index is superseded).
- Consequences: `sales.invoice_seq int NOT NULL` + unique index `(branch_id, invoice_seq)`; the checkout RPC assigns the number inside the sale transaction. Round 2 (F-DB-7): appointment `ref_number` uses the same counter discipline — the booking RPC generates `<branch invoice_prefix>-A<seq>` from an appointments-purpose counter row (`invoice_counters` gains a `kind` discriminator: `invoice | appointment_ref`), under the same row-lock `UPDATE ... RETURNING` pattern, constrained by `UNIQUE (branch_id, ref_number)`. A naked `NOT NULL` text column with no generator is prohibited; the plan Phase 5 migration and concurrency tests carry this.
- Revised in round 2: F-DB-7.
- Source: requirements PD-tenant-4; verifier AGREE WITH CHANGES; the one authoritative rule is per-branch.

### ADR-15: The domain glossary is the naming authority
- Status: Accepted.
- Context: the drafts diverged: SQL said `staff`/`branch_services`/`branch_hours`, the glossary said `staff_members`/`service_branch_overrides`/`branch_opening_hours`; the glossary also named tables the SQL never created (`blocked_times`, `register_sessions`).
- Decision: the `spa-domain-glossary` skill is the single source of truth for entity and table names, and the final schema uses: `tenants, branches, branch_opening_hours, closed_periods, profiles, memberships, staff_members, staff_branch_assignments, shifts, blocked_time_types, blocked_times, service_categories, services, service_branch_overrides, service_staff, clients, client_notes, appointments, appointment_items, booking_overrides, cancellation_reasons, sales, sale_items, tips, payments, register_sessions, invoice_counters, tax_rates, settings, audit_log, idempotency_keys, currencies, plan_features` (round 2, F-7: `plan_features` added per ADR-18). Banned synonyms (location, employee, team_member, customer) stay banned. Where this file and the glossary draft disagree (sale statuses, ADR-7), this file wins and the finalized skill is updated.
- Alternatives: let each layer keep its own names (rejected: the drift is exactly what the verifier flagged).
- Consequences: the draft SQL migrations are a starting inventory, not the final schema; Phase 0/1 rewrites them under these names with the corrections in ADR-17, 20, 23, 24, 26, 31. Round 2 (F-1): the round-1 drafts have been **quarantined** — they now live in `sql/drafts-v1/` with a superseded banner in every file, outside any active migration path; no tooling may apply them, and CI fails if the active migration path references them (F-verifier-2 gate). The fresh migration set is written from the ADRs under `supabase/migrations/` (CONVENTIONS §2). Claiming the plan is build-ready while unbannered draft `.sql` files sit in the active path is prohibited.
- Revised in round 2: F-7, F-1.
- Source: chair ruling on the verifier's skill-review conflict list.

### ADR-16: Bilingual name columns where operators see names
- Status: Accepted.
- Context: EN/AR from day one (ADR-40); the draft SQL used single `name` columns.
- Decision: operator-facing entities carry `name_en` and `name_ar` (services, service_categories, blocked_time_types, cancellation_reasons, branches, tenants display name). People carry both scripts where available: `staff_members.full_name_en/full_name_ar`; clients store `first_name`/`last_name` in the user's script plus optional `first_name_alt`/`last_name_alt` in the other script. At least one script is required; search matches either (ADR-40 normalization).
- Alternatives: single `name` column (rejected: fails US-SEC-1/NFR-7); everything bilingual including notes (rejected: free text is written in one language by its author).
- Consequences: every migration, type, form, and receipt template handles both columns; display falls back `name_ar → name_en` for AR users and `name_en → name_ar` for EN users.
- Source: requirements PD-i18n-1; verifier AGREE WITH CHANGES.

## Section 3: Money, payments, billing

### ADR-17: Money is integer minor units (`bigint`), never numeric or float
- Status: Accepted. PD-DB-3 (`numeric(12,3)`) is **Rejected**.
- Context: the sharpest conflict in the pass (review.md conflict 2): requirements and glossary said integer fils; data model, SQL, and two skills said `numeric(12,3)`. KWD has three decimals; reports and receipts must agree to the fils.
- Decision: all monetary columns are `bigint` counting minor units (fils for KWD), `CHECK (>= 0)` except where a signed ledger row is explicitly allowed. A small `currencies` table holds the ISO-4217 exponent per currency; KWD exponent = 3. All arithmetic (DB, Deno, browser) is integer; the single rounding rule is half-up at the line level; only the presentation layer renders decimals (`useFormat().money`, ADR-40). Column names end in `_minor` (e.g. `total_minor`, `amount_minor`). Totals are derived from lines and payments and checked at write time by the checkout RPC.
- Alternatives: `numeric(12,3)` (rejected: it is exact, but it splits the codebase into two representations — SQL decimal vs JS integer — and invites float conversions at every boundary; the product decision and both TS layers already speak minor units); `float` (rejected: never).
- Consequences: every draft migration, view, type, report definition, and the `supabase-database` and `spa-domain-glossary` skills are updated to `_minor bigint`. API payloads carry integers; no decimal.js/Dinero dependency is needed in MVP (integer arithmetic plus one formatting boundary). JSON serialization of bigint stays within Number.MAX_SAFE_INTEGER (fils values are far below 2^53 for any realistic amount). Round 2 (F-verifier-5): the calculation order, discount allocation, tax extraction, and rounding mode are bound end to end by ADR-51 — two valid implementations may no longer produce different totals.
- Revised in round 2: F-verifier-5.
- Source: requirements PD-money-1 vs data-model PD-DB-3; verifier DISAGREED with numeric and recommended integer minor units; chair adopts the recommendation.

### ADR-18: Subscription billing per tenant; minimal entitlement model in MVP
- Status: Accepted.
- Context: we are a conventional B2B SaaS, not an add-on marketplace; billing must not be an undocumented hardcoded assumption.
- Decision: tenants are billed by subscription plan (tiered by branch/staff count). MVP ships the minimal representation: `tenants.plan` (text, e.g. `core`) plus a single entitlement-check helper (`tenant_has_feature(tenant_id, feature)`) backed by a small `plan_features` table, so feature gating is data, not code. Self-serve signup, payment collection for subscriptions, and plan management UI are a post-MVP phase (**plan Phase 17** — round 2 correction; the former "Phase 11" reference was wrong under both numbering schemes); until then the platform admin sets the plan during onboarding.
- Alternatives: in-product wallet/credits (rejected: marketplace mechanic, not our model); no representation until plan Phase 17 (rejected: verifier's point — undocumented hardcoding).
- Consequences: no wallet tables; premium report gating later is a `plan_features` row. Runtime feature flags are not used in MVP; entitlements are the gating mechanism (CONVENTIONS §5, round 2 G-5).
- Revised in round 2: F-PLAN-3/F-3, G-5.
- Source: requirements PD-billing-1; verifier AGREE.

### ADR-34: Payments: manual methods in MVP; MyFatoorah in plan Phase 10 behind a provider abstraction
- Status: Accepted with changes.
- Context: MVP must have zero external paid dependencies; Kuwait online payments are KNET-first; two member documents proposed the same gateway with different supporting claims.
- Decision (MVP ledger model): one canonical model — `payments` rows only, no separate refunds table. `payments.payment_type ∈ {payment, refund}`; a refund row references `refunds_payment_id` (the original), carries a positive `amount_minor`, a reason, and is manager-only. A trigger enforces `sum(refund amounts) ≤ original amount`. Manual methods are a fixed enum `cash | card_terminal | knet_terminal | bank_transfer | other`; each branch enables a subset (US-ON-6) in branch settings; split payments across methods are allowed. `payments.register_session_id` links cash movements to the open register session (ADR-6).
- Decision (plan Phase 10): MyFatoorah is the primary online gateway for Kuwait, Tap Payments is the documented alternative for GCC tenants, both behind a provider-neutral interface (intent → redirect/webhook → capture; refunds via API). **Binding correction**: the fee percentages, approval rates, settlement times, and recurring-billing capabilities cited in the drafts are treated as integration assumptions to be re-verified against official provider documentation during plan Phase 10 discovery, not as settled facts. The one constraint we keep as design-driving (because it shaped ADR-3): KNET does not support merchant-initiated recurring billing, so memberships use tokenized cards. Round 2 (F-DB-12): this KNET constraint is labeled a **provider-specific assumption** supported by PayTabs documentation (https://support.paytabs.com/en/support/solutions/articles/60000692059-knet-activation-and-workflow) and joins the plan Phase 10 discovery re-verification list; the tokenized-card design stands independently of it.
- Alternatives: Tap first (viable fallback; slightly higher assumed fees, better docs); KNET direct (rejected: bank KYC timeline, separate card acquirer); separate `refunds` table (rejected: two ledgers for one concept — the verifier's reconciliation objection).
- Consequences: webhook signature verification and idempotency (ADR-31) are mandatory in plan Phase 10; merchant onboarding (CR, IBAN, days of KYC) starts before plan Phase 10 code freeze; MVP checkout writes the same `payments` rows with manual methods, so plan Phase 10 adds rows, not a new model. **Binding clarification superseding requirements US-CO-4's "negative payment record" phrasing (round 2, F-PLAN-2, blocker)**: a refund is a `payments` row with `payment_type = 'refund'` and a **positive** `amount_minor` referencing `refunds_payment_id`; every `payments` amount column keeps `CHECK (amount_minor >= 0)`; no signed ledger columns exist. The `payment_type` enum is exactly `{payment, refund}` — the drafts' `sale` enum value, the separate `refunds` table, and the `refunded` sale status are all rejected (ADR-7). Reports and the daily summary net refunds by subtracting refund sums.
- Revised in round 2: F-PLAN-2, F-DB-12, F-PLAN-3/F-3.
- Source: requirements PD-payments-1 + backend PD-BACKEND-4; verifier AGREE WITH CHANGES on both; review.md SQL findings on `payment_method` and the dual refund representation are resolved here.

## Section 4: Authorization and security

### ADR-19: Authorization comes from live membership lookup; the JWT carries identity only
- Status: Accepted. PD-BACKEND-3 (tenant context from JWT claims) is **Rejected**.
- Context: the central contradiction of the pass (review.md conflict 1): data-model proposed live DB lookup, backend proposed JWT claims injected by an `auth-hook` Edge Function. JWT claims go stale: removing a user from a tenant would not take effect until token expiry, violating the immediate-revocation requirement.
- Decision: `auth.uid()` from the JWT is the only identity input. Authorization (tenant membership, role, branch scope) is derived on every request from the `memberships` table via `STABLE SECURITY DEFINER` helpers (`current_tenant_ids()`, `current_branch_scope(p_tenant_id)`, `has_tenant_role(p_tenant_id, p_roles, p_branch_id)` — all filtering `is_active = true`). Edge Functions performing privileged writes re-check membership, role, and branch scope server-side before writing; a `branch_id` in a request body is only ever cross-checked against the caller's derived scope, never trusted. The `auth-hook` Edge Function is removed from the MVP function list. A Supabase Custom Access Token hook may later add tenant claims as a **non-authoritative cache** for display/context only, if membership-lookup performance ever demands it; that decision is deferred until measured (with the caching/performance tests the verifier required).
- Multi-tenancy (open question 2): a user may hold memberships in several tenants. The frontend keeps an active-tenant context (ADR-37); RLS naturally returns rows across the user's tenants; every privileged Edge Function operation takes the target tenant from the request, verifies membership live, and scopes the whole transaction to it.
- Alternatives: JWT claims as the authorization source (rejected: stale tokens, and the verifier noted Supabase Auth Hooks are Postgres functions or supported HTTP endpoints, not an arbitrary internal Edge Function convention); per-request client-sent tenant ids without verification (rejected: spoofable).
- Consequences: `memberships(user_id, tenant_id)` is indexed for the hot lookup path; helpers are `STABLE` so the lookup runs once per statement; RLS test suite (pgTAP) covers revocation-takes-effect-immediately; no Auth Hook deployment dependency in Phase 0.
- Source: data-model PD-DB-1 vs backend PD-BACKEND-3; verifier AGREE WITH CHANGES on PD-DB-1, DISAGREE on PD-BACKEND-3; conflict 1 ruled as recommended.

### ADR-20: Branch-scoped RLS is the security boundary (binding policy architecture)
- Status: Accepted with changes. This ADR converts the verifier's CRITICAL/HIGH findings into binding rules for every migration.
- Context: the draft policies were tenant-only on branch-scoped tables, `profiles_select` was `USING (true)`, `tenants_insert` was `WITH CHECK (true)`, role checks ignored branch scope, and denormalized `tenant_id` columns were unconstrained.
- Decision — the following rules are mandatory:
  1. Every table with a `branch_id` gets branch-scoped policies: a row is visible/writable only if the caller has an all-branches membership in the row's tenant **or** a membership whose branch matches the row's branch. Applies at least to: `appointments, appointment_items, sales, sale_items, payments, register_sessions, shifts, blocked_times, branch_opening_hours, closed_periods, service_branch_overrides, service_staff, invoice_counters`.
  2. `profiles`: self-read/write only (`id = auth.uid()`), plus a narrow same-tenant relationship read (name/avatar needed to render colleagues); never `USING (true)`.
  3. `tenants`: no insert/update/delete policies for `authenticated`. Tenant creation happens only in the `onboarding` Edge Function under the service role, invoked by platform admins through a non-public ops path, always audit-logged (open question 7). Platform impersonation of a tenant is explicit, time-boxed, audit-logged, and visible to the tenant owner (NFR-1).
  4. Role helper checks carry branch scope: `has_tenant_role(p_tenant_id uuid, p_roles text[], p_branch_id uuid)` — **no default on the branch parameter** (round 2, F-DB-2); every call site passes the row's branch explicitly, so a forgotten argument is a compile/SQL error instead of a silent degradation to tenant-wide. Genuinely tenant-wide checks use a separate explicit helper `has_tenant_role_any_branch(p_tenant_id, p_roles)`. pgTAP proves a branch-A manager fails `has_tenant_role(t, '{branch_manager}', branch_b)`.
  5. Composite foreign keys enforce tenant consistency: parents expose `UNIQUE (id, tenant_id)` and **every foreign key to another tenant-owned table is composite on `(parent_id, tenant_id)`** (round 2, F-DB-3) — not only the denormalized branch/service/staff columns. Enumerated minimum pairs: `appointments(client_id)→clients`, `appointment_items(service_id|staff_id)`, `sales(client_id)→clients`, `sale_items(sale_id|appointment_id|staff_id)`, `payments(sale_id|register_session_id|client_id)`, `payments(refunds_payment_id)→payments`, `tips(staff_id|sale_id)`, `register_sessions(branch_id)`, `blocked_times(staff_id)`, `shifts(staff_id)`, `staff_branch_assignments(staff_id|branch_id)`, `service_branch_overrides(service_id|branch_id)`, `service_staff(service_id|staff_id)`. The Phase 0 pgTAP harness includes the attack-path test: inserting a row that references tenant B's client/appointment/sale/staff must fail with a foreign-key violation. A plain UUID FK plus a tenant-only `WITH CHECK` is insufficient.
  6. **Revised in round 2 (F-DB-1, blocker — supersedes the sentinel-UUID ruling)**: the sentinel UUID (`00000000-0000-0000-0000-000000000000`) is withdrawn — it cannot satisfy rule 5's composite FKs because no sentinel `branches` row may exist, and silently creating a fake branch row is prohibited. "All branches"/"tenant-wide" is represented as: `branch_id uuid NULL` (with the composite `(branch_id, tenant_id)` FK where rule 5 applies) **plus** `all_branches boolean NOT NULL DEFAULT false` and `CHECK (all_branches = (branch_id IS NULL))` on `memberships`, `settings`, `blocked_times`, and any future table needing the value. Tenant-wide uniqueness uses partial unique indexes — e.g. `CREATE UNIQUE INDEX settings_tenant_wide_key ON settings(tenant_id, key) WHERE branch_id IS NULL;` — next to `UNIQUE (tenant_id, branch_id, key)`, which then governs branch rows only. Policies test `all_branches OR branch_id = ANY(current_branch_scope(tenant_id))`; helpers test the `all_branches` flag, never a sentinel literal. Mixing the sentinel and nullable models anywhere is forbidden; the migration-wide rewrite applies this representation consistently.
  7. Service-role writes are not a database boundary: privileged functions derive and verify tenant/branch/role from live membership (ADR-19) and scope every statement; "include tenant_id in WHERE" is a code-review rule on top, not the defense.
  8. Write policies implement the role matrix (requirements §3) table by table; tables missing an update/delete policy are fail-closed by design and the required mutation path must exist via RPC/Edge Function. Round-2 note (F-perm-3): the client CSV import is owner-only.
  9. Role-grant rules (round 2, F-DB-4/F-perm-4): the memberships role enum is exactly `tenant_owner | branch_manager | receptionist | staff` — `platform_admin` is **not** a membership role and must not appear in any CHECK constraint, frontend route guard, or membership query. Membership/role mutations happen only through the `onboarding`/`staff` functions, which enforce: `tenant_owner` grants are owner-only; branch managers may grant only `receptionist`/`staff` scoped to their own branch; the granted role may never exceed the granter's own tenant role; every change writes an audit row. Platform operations use explicit, time-boxed, audit-logged impersonation (rule 3, NFR-1), modeled in the UI as an audited impersonation session mode with a persistent banner — never as a standing role.
  10. Every `SECURITY DEFINER` function — authorization helpers, booking/checkout RPCs, audit triggers, `resolve_service`, the refund-cap trigger — declares `SET search_path = public` (or uses fully schema-qualified names); `supabase db lint` runs on every migration in CI and enforces this (round 2, F-DB-13).
- Alternatives: application-layer tenancy checks (rejected: NFR-1 requires the database to be the boundary); schema-per-tenant (rejected: operational overhead at SaaS scale, Supabase single-project model).
- Consequences: the pgTAP suite tests per table, per operation, per role, cross-tenant, cross-branch, and anon, including Realtime channel authorization (verifier MEDIUM finding) before any phase exits; direct-write allowlist in ADR-28. Round-2 pgTAP additions: manager-of-branch-A fails the explicit-branch role check for branch B (rule 4); cross-tenant FK attack inserts fail (rule 5); nobody can set `platform_admin` and managers cannot grant owner/manager (rule 9).
- Revised in round 2: F-DB-1, F-DB-2, F-DB-3, F-DB-4, F-DB-13, F-perm-3, F-perm-4.
- Source: chair ruling on the verifier's security and tenancy findings (CRITICAL ×3, HIGH ×3, MEDIUM ×3).

### ADR-21: Reports are exposed via `security_invoker` views and secured RPCs, grouped in branch-local time
- Status: Accepted.
- Context: draft report views were granted to `authenticated` while assuming underlying RLS applied; Supabase documents that views bypass underlying-table RLS by default unless created `WITH (security_invoker = true)` (Postgres 15+). Date grouping used session time zone semantics.
- Decision: MVP report views are created `WITH (security_invoker = true)` so the invoker's RLS (tenant + branch scope, ADR-20) filters rows; heavy aggregates that need SECURITY DEFINER must internally apply `current_branch_scope()` filtering and are exposed as RPCs (`report_*` functions) with branch parameters validated against the caller's scope. All day/week/month grouping converts timestamps with the branch's IANA zone before truncation (`(x AT TIME ZONE b.timezone)::date`).
- Alternatives: revoke views and only use RPCs (viable, slightly more code; allowed as an escape hatch where a view cannot express the scope); leaving default view behavior (rejected: cross-tenant leak).
- Consequences: CI checks every view definition for `security_invoker`; report tests assert branch-manager A cannot see branch B aggregates; client financial aggregates (ADR-11) use the same secured-RPC pattern. Round 2 (F-6): security-invoker views still require **grants** — the invoking role (`authenticated`) must hold SELECT on the base tables, so every view migration ships explicit `GRANT SELECT` on the view and its base tables (RLS policies apply on top; per Supabase's grants-and-policies guidance, https://supabase.com/docs/guides/database/postgres/row-level-security), plus a pgTAP test proving the intended role reads rows rather than a permission-denied error.
- Revised in round 2: F-6.
- Source: verifier HIGH finding with official citation (https://supabase.com/docs/guides/database/postgres/row-level-security).

### ADR-22: Audit log is append-only and written by the database
- Status: Accepted.
- Context: the draft allowed authenticated clients to insert audit rows and nothing prevented edits; NFR-3 requires append-only records including `branch_id`.
- Decision: `audit_log` rows are written only by `SECURITY DEFINER` trigger functions attached to the audited tables (clients, appointments, sales, payments, settings, memberships/roles) and by Edge Function code paths for non-table events (logins of concern, exports, impersonation). Direct INSERT/UPDATE/DELETE on `audit_log` is revoked from `anon` and `authenticated`; reads are role-scoped (owner tenant-wide, manager branch-scoped). Records carry actor, tenant, branch, entity type/id, action, changed fields (before/after essentials), and UTC timestamp; retention ≥ 2 years.
- Alternatives: client-inserted audit rows (rejected: forgeable and droppable); outbox-to-queue audit (deferred: unnecessary at MVP volume).
- Consequences: direct supabase-js writes still produce audit rows (the trigger fires regardless of path); exports of client data are themselves audited (NFR-11).
- Source: verifier MEDIUM finding; requirements NFR-3.

## Section 5: Booking integrity and time

### ADR-23: Appointment items carry their own staff member and time span
- Status: Accepted.
- Context: the draft trigger checked every item against the parent appointment's whole range, so it could not represent US-CAL-8 (multi-service visits with different staff, sequential or parallel). Open question 5 asked whether to defer the story.
- Decision: multi-service visits stay in MVP. `appointment_items` gains `staff_id`, `effective_start timestamptz`, `effective_end timestamptz` (per item, inside the appointment window), snapshotted `price_minor`, `duration_minutes`, buffers (ADR-25), and `service_name_en/service_name_ar` snapshots. The appointment's own `scheduled_start/end` is the envelope; items are sequential spans (one after another) or parallel spans (different staff, overlapping time). Conflict checking runs per item staff over that item's span.
- Alternatives: defer multi-service visits to a post-MVP phase (rejected: real spa workflows need it and the item table already exists); parent-range-only checking (rejected: the verifier showed it is wrong).
- Consequences: the slot engine computes item spans when composing a visit; checkout copies item prices into `sale_items`; every item row carries `created_at/updated_at` per the table convention (draft omission corrected).
- Source: chair ruling on verifier HIGH findings (booking/time) and requirements US-CAL-8.

### ADR-24: Double-booking prevention: real exclusion constraints plus per-staff serialization
- Status: Accepted with changes (PD-BACKEND-5 accepted in principle; the draft trigger implementation is rejected).
- Context: NFR-4 requires that concurrent booking of the same slot is impossible. The draft `check_staff_double_booking()` trigger did `SELECT count(*)` before insert: two concurrent transactions can both see zero conflicts and both commit. The data-model's example exclusion constraint was invalid SQL (exclusion expressions cannot contain cross-table subqueries). PD-BACKEND-5 proposed a valid constraint but the migration never implemented it.
- Decision: three layers, in this order of authority:
  1. **Database constraint (final guard)**: `appointment_items` stores a generated `busy_range tstzrange` (`[effective_start - buffer_before, effective_end + buffer_after)`, ADR-25) and gets `EXCLUDE USING gist (staff_id WITH =, busy_range WITH &&) WHERE (staff_id IS NOT NULL AND appointment_status_busy)` — the busy-status condition is implemented by keeping the exclusion on a `status_active boolean`-style flag column maintained by the appointment state machine (cancelled/no_show items are flagged inactive and drop out of the constraint). `blocked_times` gets its own equivalent exclusion `(staff_id WITH =, blocked_range WITH &&)`.
  2. **Cross-entity conflicts (appointment vs blocked time)** cannot share one constraint, so every write path that creates/moves busy time runs inside a transaction that first takes `pg_advisory_xact_lock(hashtextextended(staff_id::text, 0))` for each involved staff member, then checks the other entity's rows. The advisory lock serializes concurrent bookings per staff member and makes the check-then-insert race impossible.
  3. **RPC pre-check** for good error messages: the booking function computes conflicts first and returns `CONFLICT` with the conflicting appointment; the constraints remain the guarantee.
  Reschedules go through the same locked RPC path — direct updates of `scheduled_start/end` or item spans are prohibited (ADR-28), which closes the verifier's "reschedule bypasses the trigger" hole. Concurrency tests (two simultaneous bookings of the same staff/slot; booking during a block; reschedule into an occupied slot) are required acceptance tests.
- Alternatives: trigger-only checking (rejected: race-prone, verifier CRITICAL); a single denormalized `staff_busy` table covering all sources (considered; rejected for MVP as it adds a sync surface — the advisory lock plus two constraints achieves the same guarantee with less machinery; revisit if plan Phase 15 resources strain the model).
- Consequences: `btree_gist` extension; booking round-trip budget (≤1s p95, NFR-4) still holds because the lock is per staff member and transactions are short; conflict engine checks across all branches (ADR-12) since the constraint is on `staff_id` without branch restriction.
- Source: backend PD-BACKEND-5 vs data-model trigger; verifier DISAGREE WITH CURRENT IMPLEMENTATION; chair ruling adopts the constraint-plus-lock design.

### ADR-25: Buffers are first-class, snapshotted, and part of the busy range
- Status: Accepted.
- Context: the requirements define prep/cleanup buffers (US-CAT-1, US-CAL-2) but the draft SQL had no buffer columns and the trigger ignored them.
- Decision: `services.buffer_before_minutes`/`buffer_after_minutes` (tenant defaults) with per-branch override capability in `service_branch_overrides`; at booking time the resolved buffers are snapshotted onto `appointment_items` and included in `busy_range` (ADR-24). Buffers are not billable and do not change `price_minor` or `duration_minutes`.
- Alternatives: compute buffers at query time only (rejected: historical bookings would shift when defaults change); ignore buffers in conflicts (rejected: fails US-CAL-2).
- Consequences: slot generation subtracts buffers; the calendar shows service duration while busy time includes buffers.
- Source: chair ruling on verifier HIGH finding (buffers absent from SQL).

### ADR-26: Opening hours, closed periods, and blocked time representation
- Status: Accepted.
- Context: the draft `branch_hours` had one `opens_at/closes_at` pair with no overnight or split-interval story; `staff_time_off` had no branch dimension; blocked time had no tables at all despite being MVP scope.
- Decision:
  - `branch_opening_hours(branch_id, day_of_week 0..6, opens_at time, closes_at time, is_closed boolean)`, unique `(branch_id, day_of_week)`. Times are branch-local wall times. **Overnight**: `closes_at < opens_at` means the branch closes after midnight (closing time belongs to the next calendar day); the availability engine and DST tests must cover this. **Revised in final round (F-final-db-5)**: `opens_at = closes_at` is rejected by the `boh_nonzero_length` check constraint unless the row carries `is_closed = true` — a zero-length interval is meaningless, a closed day is expressed with `is_closed`, and a 24-hour day is expressed as 00:00–23:59; Phase 1/5 fixtures and SQL v2 test `003_final_round_fixes.sql` cover the cases. Split intervals (siesta) are represented by a second row via a `seq smallint` discriminator, unique `(branch_id, day_of_week, seq)`.
  - `closed_periods(branch_id, starts_on date, ends_on date, name_en, name_ar)` removes all availability in the range (US-ON-4).
  - `blocked_times(staff_id, tenant_id, branch_id, blocked_time_type_id, starts_at, ends_at timestamptz, notes)` with its own exclusion constraint (ADR-24). A block belongs to the branch's calendar it was made on; **time off that spans branches (vacation, sick leave) is recorded once with `all_branches = true` and `branch_id IS NULL`** (ADR-20 rule 6, round-2 representation) and counts as busy everywhere — this explicitly answers the verifier's "document it" demand. Round 2 (F-DB-6/F-PLAN-18): **all** blocked-time writes go through the locked `staff`/blocked-time RPC (advisory lock plus the cross-entity appointment check per ADR-24 layer 2) — `blocked_times` is **not** a direct-write table, because a direct insert takes no lock and can silently block over a booked slot. Creation rights (revised in final round per ADR-53, F-final-product-1): receptionist and manager create own-branch blocks; all-branches blocks are manager and above. In MVP, staff time off is created by a manager on the staff member's behalf (the request happens in person or by phone); the MVP data model carries no request/approval state, and an in-app flow is a post-MVP candidate that requires revising ADR-53.
  - `shifts(staff_id, branch_id, tenant_id, starts_at, ends_at timestamptz)` are dated rows (not weekly templates); the shift grid UI materializes a week of rows and supports copy-previous-week. Overnight shifts (`ends_at` next day) are natural with `timestamptz`. Booking outside a shift is a soft warning with manager override recorded in `booking_overrides` (US-CAL-9, US-T-2).
- Alternatives: weekly-template working hours only (rejected: real rosters vary by date); tenant-wide time off only (rejected: branch calendars need local blocks).
- Consequences: availability engine = opening hours ∩ shift ∩ (duration + buffers) − appointments − blocked time − closed periods, computed in branch-local time with UTC storage (ADR-45); DST and overnight test cases are mandatory acceptance tests.
- Revised in round 2: F-DB-1, F-DB-6, F-PLAN-18.
- Revised in final round: F-final-db-5 (opening-hours equality), F-final-product-1 (time-off workflow moved to ADR-53).
- Source: chair ruling on verifier MEDIUM findings (branch_hours, staff_time_off) plus requirements US-T-2/US-T-3/US-ON-4.

### ADR-53: MVP staff time-off is manager-created blocked time (final round)
- Status: Accepted (final round).
- Context: the round-2 role matrix and ADR-26 said staff *request* time off and a manager approves, but `blocked_times` had no pending/approved state, no request queue existed, and no Phase 2 task implemented an approval flow — the requirement as written could not be built (final-round finding F-final-product-1). The verifier demanded a choice: manager-created blocks for MVP, or a request state plus approval flow.
- Decision: in MVP, staff time off is recorded as a manager-created blocked-time block using the existing `blocked_times` model and its locked RPC (ADR-26). The staff member asks in person or by phone; a manager (or receptionist for own-branch blocks) creates the block. Staff see their own blocked time read-only. No `status` column, no request queue, no approval task ships in MVP. The in-app request/approval flow is a post-MVP candidate (natural home: Phase 13 scheduling) and requires revising this ADR before it is built.
- Alternatives: (a) add a `status`/pending column plus a manager approval action and an Epic 2.3 task (rejected for MVP: new state machine and UI for a workflow that a phone call already covers at SpaCorner's scale); (b) leave the contradiction unresolved (rejected by the verifier — "silence is not" an option).
- Consequences: Phase 2.3 screens/acceptance/backlog reflect manager-created blocks; the parity matrix and user journeys were reworded; the requirements §3 matrix cell reading "staff request, manager approves" is superseded by this ADR via the precedence rule. Fresha handles team time off through the same calendar blocked-time mechanics (technical/settings.md § Scheduling — Blocked time types), so MVP parity is unaffected.
- Revised in final round: F-final-product-1 (this ADR is the revision).
- Source: chair ruling on the final-round verifier finding.

## Section 6: Database conventions

### ADR-44: UUID primary keys everywhere
- Status: Accepted.
- Context: ID strategy for all tables.
- Decision: `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`. Human-readable numbers (invoice, appointment ref) are separate per-branch sequence values (ADR-14), never the PK.
- Alternatives: bigint identity (rejected: enumerable, merge-hostile).
- Consequences: FK columns are uuid; TS types use string; **binding correction**: draft backend examples using integer ids are wrong. Composite `(id, tenant_id)` unique constraints exist on parent tables to support ADR-20 rule 5.
- Source: data-model PD-DB-2; verifier AGREE (with composite-FK validation requirement, folded into ADR-20).

### ADR-45: `timestamptz` storage with IANA zone per branch
- Status: Accepted with changes.
- Context: multi-timezone tenants; DST safety (NFR-8).
- Decision: all timestamps are `timestamptz` (UTC storage); each branch has an IANA `timezone` (default `Asia/Kuwait`); rendering and date grouping convert to branch-local (ADR-21, ADR-40). Wall-time inputs (opening hours, shift grid) are branch-local by definition (ADR-26).
- Alternatives: naive timestamps + offsets (rejected: DST breaks them).
- Consequences: **binding correction**: explicit DST and date-boundary conversion tests are required acceptance tests for the availability engine and report grouping, even though Kuwait has no DST (other tenants might). Round 2 (F-verifier-4, binding): every daily metric — "today", the daily sales summary, no-show counts, dashboard/home tiles — is defined as the **local calendar date in the selected branch's IANA time zone**, converted to UTC for predicates: `[local-date 00:00 at branch tz, next local date 00:00 at branch tz)`. Cross-branch and tenant-wide reports either require an explicit branch selection or aggregate each branch in its own local day and then sum (documented per report). Midnight-boundary and DST fixtures are mandatory plan Phase 7 acceptance tests (a 23:30 UTC sale lands on the correct Kuwait day in the dashboard, register, and reports alike).
- Revised in round 2: F-verifier-4.
- Source: data-model PD-DB-4; verifier AGREE.

### ADR-46: Mixed soft delete and status-based retention
- Status: Accepted with changes.
- Context: history preservation vs query simplicity.
- Decision: clients soft-delete (`is_deleted` + `merged_into`, ADR-9); services/staff/branches deactivate (`is_active`); appointments and sales are status-based (`cancelled/no_show`, `voided`) and never hard-deleted; financial rows are immutable (corrections are new rows: refunds, ADR-34). Referenced historical rows can never be hard-deleted (FKs plus this rule). Low-impact config rows (settings, cancellation reasons, block types) may hard-delete.
- Alternatives: hard delete everywhere (rejected: breaks history/audit); soft delete everywhere (rejected: query noise on immutable records).
- Consequences: consistent inactive/deleted filters in list queries and RLS; partial unique indexes ignore deleted rows; anonymization for privacy requests (NFR-11) replaces personal fields while keeping financial records.
- Source: data-model PD-DB-5; verifier AGREE WITH CHANGES.

## Section 6b: Round-2 platform, operations, and money-calculation decisions

### ADR-47: Rate limiting — platform limits in MVP; a per-tenant application limiter designed in plan Phase 9
- Status: Accepted (round 2, G-1; supersedes the round-1 backend draft's fictional config option).
- Context: NFR-12 requires rate limiting. Supabase rate-limits Auth endpoints (login, password reset) at the platform level. There is **no** per-function `[functions.<name>.rate_limit]` key in the Supabase CLI config — the documented per-function keys are `verify_jwt`, `import_map`, `entrypoint`, `static_files` (https://supabase.com/docs/guides/cli/config). The round-1 backend draft's `max_concurrent_requests` config example is therefore unbuildable and superseded.
- Decision: MVP relies on Supabase platform/Auth rate limits for authentication endpoints plus documented platform protections for Edge Functions; no fictional per-function configuration is referenced anywhere. An application-level per-tenant limiter (token bucket in `_shared`, backed by Postgres counters, with documented quotas, endpoint coverage, and failure mode — fail-open with alerting vs fail-closed) is designed and owned by the **plan Phase 9 public-booking threat model**, which covers all publicly reachable endpoints. The `RATE_LIMITED` (429) error contract (ADR-29) applies whenever a limiter is active.
- Consequences: plan Phase 7 hardening keeps its rate-limit review task (platform limits verified against the then-current Supabase docs); plan Phase 9 may not launch public booking without the completed threat model (ADR-1 consequence); skills and docs never cite a nonexistent config key again.
- Source: round-2 coverage/decisions audits (G-1, F-DB-11); verifier adjudication ACCEPT.

### ADR-48: Data residency — production region decided with an explicit legal verification gate
- Status: Accepted with an explicit assumption (round 2, G-2).
- Context: NFR-11 (Kuwait PDPA, Decree-Law 42/2023) and the GDPR baseline imply a data-residency position; no round-1 artifact picked a Supabase project region. Supabase does not offer a Kuwait region.
- Decision: the production Supabase project region defaults to **eu-central-1 (Frankfurt)** — a nearby, GDPR-aligned region — recorded as a **product/legal assumption, not a compliance claim**. No document may assert that any region "satisfies Kuwait PDPA" without legal/provider evidence. Owner: product owner with legal counsel. Verification gate: before plan Phase 8 go-live, legal confirms the PDPA posture for the chosen region and signs the data-processing terms (the go-live checklist carries the item). If legal requires a different region, a Supabase project migration is scheduled before go-live.
- Consequences: staging mirrors the production region; the environment topology (CONVENTIONS §8) records the region; backup/PITR (ADR-49) and the offboarding contract (ADR-50) apply to the chosen region's project.
- Source: round-2 decisions audit (G-2); verifier adjudication ACCEPT with change (no unsupported compliance claim).

### ADR-49: Backups, PITR, RPO/RTO, and restore drills
- Status: Accepted (round 2, G-3).
- Context: NFR-14 requires daily backups and a restore drill before GA; the round-1 plan had the drill but no retention/RPO/RTO decision.
- Decision: production runs on a Supabase paid plan with managed daily backups plus point-in-time recovery. Targets: **RPO ≤ 24 h** from daily snapshots (PITR narrows practical loss to minutes where the plan supports it), **RTO ≤ 4 h**. Retention: daily backups per the Supabase plan (≥ 7 days), plus a manual snapshot before every Phase 8 branch-cutover import. Restore-drill scope: restore a production snapshot to a scratch project, run the pgTAP smoke suite, and reconcile one daily-sales report against known totals; timed and documented. Owner: Ops.
- Consequences: the drill executes in plan Phase 7 (Epic 7.4) and is rehearsed once more in staging before each Phase 8 cutover (go-live checklist); the rollback plan (Phase 8 step 5) references the same snapshots.
- Source: round-2 decisions audit (G-3); verifier adjudication ACCEPT.

### ADR-50: Tenant offboarding and data deletion contract
- Status: Accepted (round 2, G-4).
- Context: NFR-10/11 require export and anonymization; plan Phase 17 mentions an offboarding export but no contract existed.
- Decision: offboarding runs in four ordered steps: (1) **Export** — full tenant export delivered to the tenant owner (CSV per ADR-43 plus a JSON settings dump), audit-logged; (2) **Soft-archive** — tenant marked inactive, all memberships deactivated, data retained read-only for **28 days**, with notification to remaining users; (3) **Anonymize** — personal fields in `clients`, `staff_members`, and `profiles` replaced via the NFR-11 anonymize RPC; (4) **Retain financials, then delete** — financial records (sales, payments, audit log) are retained for the Kuwaiti commercial retention period (default assumption **10 years**, confirmed by legal at plan Phase 17 scheduling), then hard-deleted. Legal owner: product owner with legal counsel.
- Consequences: plan Phase 17's offboarding export uses this contract; the anonymize RPC built in plan Phase 4 is the same machinery; audit retention (ADR-22, ≥ 2 years) is a floor, not the financial-retention period.
- Source: round-2 decisions audit (G-4); verifier adjudication ACCEPT.

### ADR-51: Deterministic checkout calculation order and rounding
- Status: Accepted (round 2, F-verifier-5; binds ADR-17's "half-up at the line level" into one executable spec).
- Context: integer minor units and KWD 3 decimals were settled, but the order and rounding of line discounts, invoice-level discounts, tips, tax, and refunds were not — two valid implementations could produce different totals and break reconciliation.
- Decision — the calculation runs in exactly this order, all-integer, rounding **half-up** at every step:
  1. Line base = `price_minor × quantity`.
  2. Line discounts: fixed-amount discounts apply first, then percentage discounts on the reduced base; the result is the discounted line base. A line discount can never exceed the line base.
  3. Invoice-level discounts allocate pro-rata across lines by discounted line base, half-up per line, with the exact remainder (positive or negative) applied to the largest line so the allocation sums to the discount to the fil.
  4. Taxable base per line = the line amount after all discounts. Tax per line = `base × rate_bp ÷ 10000`, half-up (rates stored in basis points). Tax-inclusive pricing extracts tax as `base × rate_bp ÷ (10000 + rate_bp)`, half-up, so the inclusive total stays exact.
  5. Tips never enter the taxable base and are never discounted.
  6. Line total = taxable base + tax. Sale total = Σ line totals (+ tips shown separately); `due = total − Σ payments`.
  7. Refunds reverse whole payments (MVP full refunds, ADR-10/34); any future partial refund (plan Phase 10) reallocates discounts and tax with the same pro-rata rule.
- Consequences: `packages/core` exports this calculation as pure functions with **golden fixtures** (expected fil totals for discount+tax+tip combinations); the plan Phase 6 checkout RPC implements the identical order server-side; client-supplied totals that differ from the server recomputation are rejected (tampered-total negative tests); reports and receipts inherit line-level numbers so the daily-summary reconciliation gate holds to the fil.
- Source: round-2 verifier sweep (F-verifier-5); adjudication ACCEPT.

### ADR-52: Round-2 model additions — branch calendar preferences and client source
- Status: Accepted (round 2, F-cov-7, F-cov-8, F-PLAN-12).
- Context: per-branch calendar rendering needs a week start and time format (Gulf weeks start Saturday; the Intl default would misalign the calendar and shift grid for Arabic users), the slot engine consumes a per-branch step that no phase created, and client source/attribution is cheap to add now but costly to backfill.
- Decision:
  - Branch calendar preferences live on `branches` (typed columns, not `settings` keys): `first_day_of_week smallint` (0=Sunday..6=Saturday; default **Saturday (6)** for Arabic-first tenants, configurable per branch), `time_format smallint` (12|24, default 24), `slot_step_minutes smallint` CHECK in (5,10,15,30), default 15. Created and edited in plan Phase 1 (branch editor "calendar defaults"), consumed by the plan Phase 5 slot engine and by calendar/shift-grid locale options (schedule-x week start, 12/24 rendering).
  - `clients.source text NULL` ships in the plan Phase 4 migration. Defaults: `walk-in` for manually created clients, `imported` for CSV rows lacking a source value; the clients.csv template (requirements §6) gains an optional `source` column. Source reporting/segmentation is deferred non-committed (a plan Phase 12 candidate); nothing may infer a source feature from draft-SQL columns.
- Consequences: data-model.md and requirements.md (round-1 files, unedited) are superseded on these points per the precedence rule; the i18n-rtl skill documents week-start/time-format threading; Phase 1, 4, and 5 backlogs carry the tasks.
- Source: round-2 coverage audit (F-cov-7, F-cov-8) and plan audit (F-PLAN-12); adjudication ACCEPT.

## Section 7: Backend architecture

### ADR-27: One Edge Function per bounded context
- Status: Accepted with changes.
- Context: the owner's isolation requirement (NFR-2): a failing or redeploying function must never take down the rest of the product.
- Decision: functions own business domains with lightweight internal routing (ADR-30). MVP function list (7): `bookings` (create/reschedule/cancel/no-show/status/slot queries), `checkout` (sale creation, payments, refunds, void, register sessions), `catalogue` (services, categories, overrides, eligibility), `clients` (create/update, duplicate check, CSV import, merge is plan Phase 11), `staff` (staff records, assignments, shifts, blocked time), `reports` (aggregation RPC orchestration, CSV export streaming), `onboarding` (platform-admin tenant/branch provisioning, seed defaults). Plan Phase 9 adds `notifications`, `webhooks`, `online-booking`. **Binding correction**: the `auth-hook` function is removed (ADR-19); Supabase Auth Hooks are Postgres functions or supported HTTP endpoints, not an arbitrary internal convention. Round 2 (F-DB-11): there is no per-function `rate_limit` key in the Supabase CLI config — rate limiting follows ADR-47, not a fictional config option.
- Alternatives: single router monolith (rejected: violates NFR-2); one function per action (rejected: duplication, cold-start sprawl, function-count overhead); per-tenant functions (rejected: nonsense for multi-tenant SaaS).
- Consequences: per-domain cold starts (~50–200ms) amortized by internal routing; deploy blast radius is one domain; documented Supabase limits respected (256MB, 2s CPU/request, wall-clock caps, bundle size 20MB CLI-bundled local / 5MB server-side bundled — heavy work goes to SQL or queues); health endpoint per function; external uptime monitor pings `/health`.
- Revised in round 2: F-PLAN-3/F-3, F-DB-11, F-BE-1.
- Source: backend PD-BACKEND-1; verifier AGREE WITH CHANGES.

### ADR-28: Hybrid data access with an explicit direct-write allowlist
- Status: Accepted with changes (merges PD-DB-7, PD-FE-3, PD-BACKEND-2; conflict ruled).
- Context: when may the frontend use supabase-js (PostgREST/RPC under RLS) directly, and when must it call an Edge Function?
- Decision:
  - **Reads**: direct supabase-js under RLS is the default (lists, details, calendar reads, report views per ADR-21). Complex aggregations use RPCs.
  - **Direct single-table writes** are allowed only for tables on the allowlist, where RLS + check constraints fully express the authorization and no cross-table invariant exists: `profiles` (self), `client_notes` (receptionist and above; the staff role is read-only per ADR-11 round-2 revision), `clients` (create/update of **contact/profile fields only** by receptionist and above — round 2, F-4: `is_blocked`, `is_deleted`, and `merged_into` are carved out and route through the `clients` Edge Function with role checks and audit; the staff role has no direct client writes at all, F-perm-2; duplicate warning is a UI+RPC check), `settings` (role-gated), `shifts` (manager-gated, branch-scoped). Everything else goes through an Edge Function.
  - **Prohibited for direct writes** (Edge Function or RPC only): `appointments`, `appointment_items`, `booking_overrides` (conflict machinery, ADR-24), `sales`, `sale_items`, `payments`, `register_sessions`, `invoice_counters`, `tips` (money and reconciliation), `blocked_times` (round 2, F-DB-6: cross-entity booking lock — every write goes through the locked `staff`/blocked-time RPC, ADR-24/26), `memberships`, `tenants`, `branches` (roles and provisioning), `audit_log` (ADR-22), `service_branch_overrides` + `services` when the change touches pricing (catalogue function keeps snapshots and audit consistent). Refunds and voids are owner/manager-only inside the `checkout` function (ADR-10 round 2, F-perm-1).
  - The allowlist is duplicated nowhere: it lives in CONVENTIONS.md and the `spa-platform-architecture` skill; adding a table to it requires a PR that shows the RLS policies and constraints that make it safe.
- Alternatives: all-through-functions BFF (rejected: latency and invocation cost on reads RLS already answers); all-direct (rejected: cannot express multi-table invariants).
- Consequences: RLS must be comprehensive and tested (ADR-20); Edge Functions re-validate with shared Zod schemas (ADR-39); reviewers check the allowlist on every schema PR.
- Revised in round 2: F-4, F-DB-6, F-perm-1, F-perm-2.
- Source: data-model PD-DB-7, frontend PD-FE-3, backend PD-BACKEND-2; verifier AGREE WITH CHANGES on all three, demanding exactly this allowlist.

### ADR-29: One API envelope and one error code catalogue
- Status: Accepted (conflict 5 ruled).
- Context: the frontend draft specified `{ok, error:{code,message,fieldErrors}}` with codes NETWORK/UNAUTHENTICATED/…; the backend draft specified `{error:{code,message,details}}` with VALIDATION_ERROR/UNAUTHORIZED/…. Two contracts would drift immediately.
- Decision: the single versioned envelope for all Edge Function responses is:
  - success: `{ "ok": true, "data": … }`
  - failure: `{ "ok": false, "error": { "code", "message", "fieldErrors"?, "details"? } }`
  One code catalogue, defined once in `packages/validation` (TS) and mirrored in `_shared/errors.ts` (Deno): `VALIDATION` (400), `UNAUTHENTICATED` (401), `FORBIDDEN` (403), `NOT_FOUND` (404), `CONFLICT` (409), `IDEMPOTENCY_MISMATCH` (422), `RATE_LIMITED` (429), `INTERNAL` (500), `UNAVAILABLE` (503). `NETWORK` is client-side only (fetch failed). `message` is an English, developer-facing string; user-facing copy is i18n'd on the frontend keyed by `code` (+ `error.details.reason` where needed); `fieldErrors` maps field → message key for forms.
- Alternatives: keep both contracts (rejected); HTTP-status-only errors (rejected: forms need field granularity).
- Consequences: `packages/api` `invoke()` parses the envelope into typed results or `ApiError`; contract tests assert every function emits the envelope.
- Source: chair ruling on review.md conflict 5.

### ADR-30: Public invocation shape is `/<function>/<action>`
- Status: Accepted (conflict 6 ruled).
- Context: the frontend draft called `booking-create`, `booking-reschedule`, `checkout` as separate functions; the backend proposed bounded-context functions with internal routes.
- Decision: bounded-context functions with internal action routing: `POST /functions/v1/bookings/create`, `/bookings/reschedule`, `/checkout/sale`, etc. The frontend never hand-builds these URLs: `packages/api` exposes typed wrappers (`bookingApi.create(...)`, `checkoutApi.createSale(...)`), so the invocation shape is an implementation detail behind one typed layer. Breaking changes follow the versioning path (`/bookings/v2/create`) with frontend and backend deployed from the same monorepo commit.
- Alternatives: per-action function slugs (rejected: contradicts ADR-27 granularity); GraphQL-style single endpoint (rejected: blast radius).
- Consequences: `packages/api` is the only place function names and paths appear in frontend code; the `supabase-edge-functions` skill documents the routing skeleton.
- Source: chair ruling on review.md conflict 6.

### ADR-31: Idempotency keys for money mutations
- Status: Accepted.
- Context: checkout, refunds, and (plan Phase 10) webhook processing must be retry-safe; the backend skill referenced an `idempotency_keys` table missing from the schema.
- Decision: mutations that move money require an `Idempotency-Key` header (client-generated UUID). The `idempotency_keys(key, tenant_id, function, status processing|completed|failed, response_status, response_body, created_at)` table ships in the MVP schema with unique `(tenant_id, key, function)` — **revised in the final round (F-final-db-3)** from `(tenant_id, key)` so the replay boundary is per function: one client key cannot collide across two different money mutations, and Phase 6 carries an action/function-mismatch replay test (same key, different function → independent replay; same key, same function → cached response). Replay returns the cached response; `processing` collisions return 409. Keys expire after 30 days (pg_cron cleanup). Queue consumers (ADR-33) are idempotent by the same discipline, since pgmq delivery is at-least-once within the visibility window. The table is client-inaccessible: RLS deny-all with a select-only grant; the replay protocol runs inside Edge Functions under verified scope.
- Alternatives: retry-only-with-new-key semantics (rejected: double-charge risk on flaky networks); no idempotency in MVP because payments are manual (rejected: a double-clicked cash checkout still double-records a sale).
- Consequences: `packages/api` generates and threads the key per mutation attempt; webhook handlers in plan Phase 10 reuse the table keyed by gateway reference.
- Revised in round 2: F-PLAN-3/F-3.
- Revised in final round: F-final-db-3 (per-function idempotency scope).
- Source: backend §3.8; verifier SQL finding (table missing); Supabase Queues doc citation on at-least-once semantics.

### ADR-32: Shared Edge Function code via `_shared/`, no shared mutable state
- Status: Accepted with changes.
- Context: functions must stay independently deployable (NFR-2) but share auth, errors, logging, CORS, and idempotency helpers.
- Decision: `supabase/functions/_shared/` holds the shared modules, imported by relative path; each function has its own `deno.json` import map. **Binding corrections**: `_shared` holds no mutable module-level state (no caches that outlive a request, no globals mutated at runtime — isolates make this unsound anyway); any change to `_shared` redeploys **all** functions in the same CI run (documented blast radius: a bad `_shared` change affects every domain, so it gets stricter review and its surface stays small and stable); shared Zod schemas come from `packages/validation` via a Deno-compatible export path rather than being duplicated.
- Alternatives: published npm package for shared code (rejected for MVP: versioning overhead for a small team); copy-paste per function (rejected: drift).
- Consequences: CI type-checks and tests `_shared` once and deploys all functions together (`supabase functions deploy --use-api`); per-function rollback remains available via `--slug`.
- Source: data-model PD-DB-6; verifier AGREE WITH CHANGES.

### ADR-33: Async work via pg_cron + pgmq with idempotent consumers
- Status: Accepted with changes.
- Context: notifications, reminders, exports, imports, and cleanup need scheduling and retries without long-running requests.
- Decision: pg_cron schedules Edge Function invocations via pg_net; queued work uses Supabase Queues (pgmq) with visibility timeouts and retries. **Binding corrections**: delivery is at-least-once, not exactly-once — every consumer is idempotent (ADR-31 discipline) and handles duplicate delivery; queue schemas and their migrations ship with the feature that needs them; MVP uses queues only for CSV import/export jobs (notifications themselves are plan Phase 9). Database Webhooks are not used in MVP. Round 2 (F-DB-10): `pg_cron` is installed in the hosted form `CREATE EXTENSION pg_cron WITH SCHEMA pg_catalog;` plus `GRANT USAGE ON SCHEMA cron TO postgres;` and `GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA cron TO postgres;` per the official install doc (https://supabase.com/docs/guides/cron/install); the exact migration is validated against the pinned CLI/project version. Final round (F-final-db-1): `pg_net` is created explicitly in the Phase 0 extension migration alongside `pg_cron` and `pgmq` — Supabase's scheduling pattern is pg_cron combined with pg_net (https://supabase.com/docs/guides/functions/schedule-functions) — and it is listed in the supabase-database skill and covered by the clean-migration gate.
- Alternatives: Supabase Database Webhooks (rejected for batch work: per-row fan-out); external queue (rejected: operational overkill).
- Consequences: cron jobs carry a shared secret (`auth: 'secret'` mode); export jobs stream results (ADR-43); failed messages land in an archive queue checked by the ops runbook.
- Revised in round 2: F-DB-10, F-PLAN-3/F-3.
- Revised in final round: F-final-db-1 (pg_net added to the extension set).
- Source: backend PD-BACKEND-6; verifier AGREE WITH CHANGES with official pgmq citations.

### ADR-35: Pin and CI-verify the Supabase server wrapper
- Status: Accepted.
- Context: backend examples used a `withSupabase` wrapper from `npm:@supabase/server@1` taken from an AI-prompts doc page; the verifier warned this is a draft snippet, not a tested contract.
- Decision: the request wrapper is our own thin `_shared/server.ts` (auth mode handling, context assembly, envelope emission, error mapping) built on the officially documented `@supabase/supabase-js` client and Deno.serve. If we adopt a Supabase-published server wrapper later, we pin the exact package version and add a CI smoke test that verifies the wrapper API we use; nothing depends on an unpinned draft snippet.
- Alternatives: adopt `withSupabase` as shown (rejected: unverified contract); no wrapper (rejected: every function reinvents auth/CORS/errors).
- Consequences: the `supabase-edge-functions` skill documents our wrapper; auth modes (`user | secret | none`) remain as designed in backend §3.2 since they are our own code.
- Source: chair ruling on the verifier's official-source check.

## Section 8: Frontend architecture

### ADR-36: pnpm monorepo with two apps and six packages
- Status: Accepted.
- Context: back-office now, client-facing booking app in plan Phase 9, shared types/validation/i18n between them and the Deno functions.
- Decision: pnpm workspaces: `apps/back-office` (MVP), `apps/booking` (plan Phase 9; scaffolded only in MVP), `packages/{ui,db,api,validation,i18n,core}`, plus `supabase/` (migrations + functions) in the same repo. Vite + React 18 + TypeScript `strict` (plus `noUncheckedIndexedAccess`), Node ≥ 20, pnpm. Independent build boundaries per app/package; CI filtered per workspace.
- Alternatives: single app with booking routes (rejected: couples bundles and auth models); multi-repo with published packages (rejected: ceremony without benefit at this team size).
- Consequences: `packages/validation` stays Deno-importable (ADR-32); frontend and backend deploy from the same commit (ADR-30).
- Revised in round 2: F-PLAN-3/F-3.
- Source: frontend PD-FE-1; verifier AGREE.

### ADR-37: Branch context in the URL; tenant context in the session
- Status: Accepted with changes.
- Context: users switch branches constantly; deep links must survive; a user may belong to multiple tenants (ADR-19).
- Decision: branch lives in a URL search param (`?branch=<uuid>|all`) managed by the branch switcher; tenant is session context: after sign-in the app loads memberships (tenants, roles, branch scopes) into a `SessionContext`; multi-tenant users get a tenant switcher whose active tenant is persisted per user and sent as context on function calls — where the server **verifies membership live** and never trusts the client value (ADR-19). Default branch persisted in localStorage; receptionists with one branch get a locked switcher; RLS remains the real boundary either way.
- Alternatives: tenant and branch in path segments (rejected: noise and broken deep links); session-only branch (rejected: unshareable URLs).
- Consequences: every query key carries tenant + branch scope (ADR-38); shareable links serialize branch/date/view; switching tenant clears the query cache. Round 2 (F-fe-1): the round-1 frontend draft's "one tenant per user" phrasing is superseded — a user may hold memberships in several tenants; the active tenant is application context resolved via the switcher (default persisted per user), and the server re-derives membership and scope from `memberships` on **every** request regardless of what the client sent.
- Revised in round 2: F-fe-1.
- Source: frontend PD-FE-2; verifier AGREE WITH CHANGES; data-model's `x-tenant-id` header idea is kept but demoted to verified context, never authorization.

### ADR-38: TanStack Query v5 with tenant+branch-scoped key factories; Realtime authorization tested
- Status: Accepted with changes.
- Context: server-state caching, optimistic calendar drags, cross-tab liveness (NFR-5).
- Decision: hierarchical key factories only; **binding correction**: every key that can vary by scope includes scope segments (the draft keys had branch only), so tenant switches never serve stale caches. Round 2 (F-PLAN-8/F-fe-2) the rule is qualified by entity scope: **tenant-scoped** entities key on the tenant segment (`clients.list(tenantId, filters)`, `clients.detail(tenantId, id)` — a detail key without the tenant segment is prohibited); **branch-scoped** entities key on `[tenantId, branchId]` (`appointments.calendar(tenantId, branchId, date)`). The canonical hook signature is `useRealtime(entity, tenantId, branchId)`. `queryOptions` co-located with fetchers; invalidation via factory prefixes; optimistic updates only for drags/status toggles with rollback on `CONFLICT`; staleTime defaults per frontend draft (30s lists, 60s reference, 0 money-on-reports). Realtime: `useRealtime` hooks patch caches from `postgres_changes`; **binding correction**: the test plan includes Realtime channel authorization — subscribing as tenant A/branch A must never receive tenant B or branch B payloads (verifier MEDIUM finding), tested in CI, not just UI keys.
- Alternatives: RTK Query (rejected: weaker fit); a global state mirror (rejected: footgun).
- Consequences: no server-data copies outside the cache; polling fallback (≤5s staleness, NFR-5) if Realtime authorization proves insufficient for a table.
- Revised in round 2: F-PLAN-8, F-fe-2.
- Source: frontend PD-FE-4; verifier AGREE WITH CHANGES.

### ADR-39: React Hook Form + Zod, schemas shared with Edge Functions
- Status: Accepted with changes.
- Context: form-heavy app; double validation layers drift.
- Decision: one Zod schema per operation in `packages/validation`; forms use `zodResolver`; Edge Functions import the same schema (Deno-compatible export). **Binding corrections**: schemas must stay pure JS (no Node-only APIs, no browser APIs) so Deno imports them unchanged; Zod is an input-shape defense only — server-side **authorization** is never delegated to Zod (it stays with ADR-19/20 checks); DTO types are `z.infer`, exported via `packages/api`.
- Alternatives: Formik (rejected: legacy API); separate server schemas (rejected: drift).
- Consequences: one schema change updates form and function together in the same PR.
- Source: frontend PD-FE-5; verifier AGREE WITH CHANGES.

### ADR-40: Lingui (ICU) + logical CSS + Intl; Arabic-capable search
- Status: Accepted with changes.
- Context: EN/AR with full RTL from day one is an MVP gate (PD-i18n-1, NFR-7, US-SEC-1); Arabic needs six plural categories; search must match Arabic input.
- Decision: Lingui macros with build-time compiled catalogs (`packages/i18n/locales/{en,ar}/messages.po`); `dir`/`lang` on `<html>` from the user's persisted preference; logical CSS properties only, enforced by stylelint; directional icons mirrored via `@repo/ui` primitives; all formatting via centralized `Intl` helpers (KWD 3 decimals from the currency exponent, branch time zone). **Binding corrections**: bilingual schema columns per ADR-16; **Arabic search normalization** ships in MVP: a generated `search_text` column (or equivalent) per searchable entity holding a normalized form — Arabic diacritics stripped, alef/ya/ta-marbuta variants unified, latin/arabic digits unified — with a matching GIN/trigram index, and the same normalization applied to client/staff/service name search (US-CL-6 requires EN and AR to both match).
- Alternatives: react-i18next (rejected: non-ICU plurals); react-intl runtime parsing (rejected: bundle and perf); normalization in app code only (rejected: SQL search would miss variants).
- Consequences: missing Arabic translations fail CI; E2E runs critical journeys in both locales.
- Source: frontend PD-FE-6; verifier AGREE (with schema/search normalization requirements).

### ADR-41: schedule-x wrapped in `<BookingCalendar>`; premium license conditional on a Phase 0 spike
- Status: Accepted with changes.
- Context: the calendar is the hardest screen (day/week, per-staff columns, drag reschedule, RTL, performance); building from scratch is a multi-month trap; the resource-scheduler view is a paid premium package.
- Decision: schedule-x React bindings wrapped in feature-owned `features/calendar/components/BookingCalendar`; the library never leaks outside `features/calendar`; drag-to-reschedule is an optimistic mutation with server-`CONFLICT` rollback; branch-tz rendering via local-datetime mappers. **Binding ruling (open question 9)**: the premium resource-views license budget line is approved **conditionally** — a one-week Phase 0 spike must prove the premium resource scheduler meets the MVP acceptance criteria (NFR-4 render budget, keyboard operation, RTL mirroring, ≥8 staff columns). Go: buy the license. No-go: fall back to schedule-x core with custom resource columns via its custom-view API, and the fallback must still meet the same acceptance criteria before **plan Phase 5 (calendar)** exits (round-2 correction: the former "Phase 3 (calendar)" reference matched no numbering scheme). Either outcome is recorded by updating this ADR.
- Alternatives: FullCalendar premium (rejected: commercial license model and heavier API); build in-house (rejected: months).
- Consequences: licensing becomes an explicit Phase 0 exit item rather than a surprise dependency; performance budgets (calendar chunk ≤150kB, drag frame ≤16ms) apply to either path.
- Revised in round 2: F-PLAN-3/F-3.
- Source: frontend PD-FE-7; verifier AGREE WITH CHANGES (go/no-go dependency).

### ADR-42: TanStack Router with typed search params
- Status: Accepted.
- Context: filters, dates, and view state belong in URLs; guards per role.
- Decision: typed route tree; `validateSearch` (Zod) on filter-bearing routes; `beforeLoad` role guards are UX only — RLS/Edge Function checks are the security boundary; deep links restore after login; auth via Supabase email+password (MFA/magic links deferred).
- Alternatives: React Router (rejected: weaker search-param typing).
- Consequences: route definitions colocated in features; shareable URLs per ADR-37.
- Source: frontend PD-FE-8; verifier AGREE.

### ADR-43: MVP exports stream from Edge Functions; Storage in plan Phase 9
- Status: Accepted (open question 10 ruled).
- Context: requirements need CSV exports (US-SEC-3, NFR-10: UTF-8 with BOM for Excel/Arabic, full-tenant export ≤10 min at 100k clients/1M appointments); drafts mentioned avatars/exports but no Storage design existed.
- Decision: MVP exports are generated server-side and streamed to the browser as downloads (reports function; queued via pgmq for large jobs, ADR-33) — no Storage bucket, no public URLs. Export events are audit-logged (ADR-22) and role-scoped (owner: tenant-wide incl. client contacts; branch manager: own-branch operational data only). Plan Phase 9 introduces Storage with tenant/branch-prefixed paths (`{tenant_id}/{branch_id}/...`), bucket policies mirroring RLS scope rules, and private buckets only — designed before any upload feature (avatars, receipts PDF, marketing assets) ships.
- Alternatives: export-to-bucket + signed link in MVP (rejected: Storage RLS design is not free and downloads suffice); client-side CSV generation (rejected: bypasses scope checks and chokes on large data).
- Consequences: download endpoints respect function timeouts (stream, don't buffer); the plan Phase 9 Storage design is an **unconditional named task** that ships before any upload feature, independent of whether avatars/assets are scheduled (round 2, F-PLAN-16). Round 2 (F-verifier-3): export privacy boundary per ADR-11 — client contact/allergy exports are owner-only; manager exports cover own-branch operational data only; ordinary aggregate reports redact allergy detail; role/branch negative export tests are part of plan Phase 7 acceptance. Final round (F-final-backend-1): the full-tenant export is a **chunked, resumable pgmq job** — each Edge Function invocation stays under the wall-clock limit (150 s free / 400 s paid, https://supabase.com/docs/guides/functions/limits), slices (e.g. 10k clients per message) are assembled into the final download, and the NFR-10 ≤10-minute benchmark measures end-to-end job completion, never a single invocation; resumption rides pgmq visibility timeouts with idempotent consumers.
- Revised in round 2: F-PLAN-3/F-3, F-PLAN-16, F-verifier-3.
- Revised in final round: F-final-backend-1 (chunked/resumable export job).
- Source: chair ruling; verifier MEDIUM finding (Storage absent).

---

## Rejected and deferred proposals (explicit)

| Proposal | Ruling | Where |
|---|---|---|
| PD-DB-3 `numeric(12,3)` money | **Rejected** — integer minor units per ADR-17 | ADR-17 |
| PD-BACKEND-3 tenant context from JWT claims | **Rejected** — live membership lookup per ADR-19 | ADR-19 |
| `auth-hook` Edge Function | **Rejected** — no Auth Hook in MVP | ADR-19, ADR-27 |
| Draft trigger-based double-booking check | **Rejected** — race-prone; replaced by constraints + advisory lock | ADR-24 |
| Separate `refunds` table | **Rejected** — single `payments` ledger | ADR-34 |
| Draft SQL table names (`staff`, `branch_services`, `branch_hours`) | **Rejected** — glossary names | ADR-15 |
| `resources` table in MVP | **Deferred** to plan Phase 15 | ADR-4 |
| Repeating series schema reservation | **Rejected** — no dead columns; migrate in plan Phase 11 | ADR-8 |
| Custom Access Token hook as display cache | **Deferred** — revisit only if membership-lookup performance is measured to hurt | ADR-19 |
| Supabase Database Webhooks | **Deferred** — post-MVP realtime features may revisit | ADR-33 |
| Sentinel all-branches UUID | **Rejected (round 2, F-DB-1)** — nullable `branch_id` + `all_branches` flag with partial unique indexes | ADR-20 rule 6 |
| `platform_admin` as a membership role or frontend route-guard role | **Rejected (round 2, F-DB-4/F-perm-4)** — audited, time-boxed impersonation only | ADR-20 rule 9 |
| Per-function `[functions.<name>.rate_limit]` config key | **Rejected (round 2, F-DB-11/G-1)** — the key does not exist in the Supabase CLI config | ADR-47 |
| `service_charge_total` draft column / service-charges feature | **Rejected in MVP; deferred non-committed (round 2, F-cov-4)** — if ever scheduled: `_minor bigint` money and a named phase | ADR-2 |
| Separate `refunds` table and `refunded` sale status in draft SQL | **Rejected (round 2, F-PLAN-2)** — positive-amount refund rows in the single `payments` ledger | ADR-34, ADR-7 |

## Verifier disagreements: how each was resolved

- **PD-money-1 vs PD-DB-3** (verifier DISAGREE with numeric): resolved in favor of integer minor units (ADR-17), the verifier's own recommendation. Every artifact updated accordingly.
- **PD-BACKEND-3** (verifier DISAGREE): rejected; ADR-19 adopts live lookup, the verifier's ruling on conflict 1.
- **PD-BACKEND-5** (verifier DISAGREE WITH CURRENT IMPLEMENTATION): the constraint idea is kept, the trigger-only implementation replaced; ADR-24 adds the advisory-lock serialization and reschedule path the verifier demanded, with mandatory concurrency tests.
- All AGREE WITH CHANGES verdicts: the changes are adopted as binding corrections inside the corresponding ADRs (2, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 16, 20, 22, 24, 25, 26, 27, 28, 32, 33, 34, 38, 39, 40, 41, 45, 46).
