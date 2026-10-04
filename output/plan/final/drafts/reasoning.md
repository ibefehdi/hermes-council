# Decisions, reasoning and council findings

This section is the "why" of the plan: a plain-language digest of every decision record (ADR), the story of what the council caught across its two review rounds, a fresh end-to-end pass over the revised plan, the questions only the owner can answer, and the issues that remain. Read it alongside `decisions.md` (the binding ADRs); where anything here disagrees with an ADR, the ADR wins.

Fresha references below cite the reverse-engineering evidence (clean-room: we compare behaviour, never copy UI, text, branding, or API shapes). Web references cite official documentation for claims a decision depends on.

## 1. Decision digest

### Product scope (ADR-1..10)

**ADR-1 — Online booking is plan Phase 9, not MVP.** We build staff-facing core operations first; the public booking page, shareable links and reminders come in plan Phase 9. The trade-off: the most demanded feature ships later, but MVP has zero external dependencies and no public attack surface. Fresha has online booking at its core, so this is a deliberate sequencing difference, not a product difference — the slot engine and conflict rules built in MVP must be reusable for public traffic (ADR-1's consequence). For builders: do not leak staff-only assumptions into the conflict model; Phase 9 must carry a public-booking threat model (ADR-47).

**ADR-2 — Inventory is Phase 13; MVP checkout has a manual item line.** SpaCorner is services-first; incidental retail is handled at the desk with a free-text `manual_item` line (price + quantity), not a product/SKU/stock model. Fresha has a full products/stock/suppliers area (technical/flows.md § Flow 3) — we consciously defer it. Round 2 rejected a draft `service_charge_total` money column found in the quarantined SQL: service charges are out of scope, non-committed (Fresha has them, technical/settings.md § Sales — Service charges, but they have no requirements home in our plan).

**ADR-3 — Packages, gift cards, memberships are Phase 14, in that order.** All three create prepaid liabilities and (memberships) need recurring card billing. Fresha sells packages and gift cards (technical/settings.md § Sales — Gift cards; technical/architecture.md § Entity: Package); we defer because liability accounting plus a gateway dependency is not MVP work. Packages first (no gateway), then gift cards, then memberships on tokenized cards — KNET cannot do merchant-initiated recurring charges (provider-specific assumption, PayTabs: https://support.paytabs.com/en/support/solutions/articles/60000692059-knet-activation-and-workflow, re-verified at Phase 10 discovery). Builders: `sale_items.item_type` stays extensible; never hardcode "sale = appointment services".

**ADR-4 — MVP conflict dimensions are staff + time only; resources/rooms are Phase 15.** A resource dimension doubles the conflict engine and the calendar UI. Fresha has a resources setup page (technical/settings.md § Scheduling — Resources), so this is a parity gap we accept temporarily. The trade-off is a smaller engine now against a Phase 15 rewrite later — mitigated by designing the conflict engine around a "busy sources" list so resources plug in without a rewrite. Binding: no `resources` table in any MVP migration.

**ADR-5 — MVP report set is six reports (plus a seventh, taxes, added in round 2).** Sales summary, payments summary, appointments summary, client list, staff performance, shifts — on one generic report framework — plus the round-2 taxes summary. Fresha has 59 reports (technical/reports.md); we ship the operator-critical subset with metric definitions fixed in requirements §4.8 (cancellation rate = cancelled ÷ (completed + cancelled + no_show)). Rich KPI dashboards and comparison-period reports are explicitly deferred non-committed (round 2, F-cov-2): if scheduled they are a separate "dashboards & analytics" workstream after Phase 12 data exists. Builders: every report view must be branch-scoped for branch-scoped roles and group dates in the branch's IANA time zone.

**ADR-6 — Register sessions (cash open/close) are in MVP.** One open session per branch, starting cash vs counted cash, difference recorded. Kuwaiti salons reconcile daily; Fresha likewise has cash registers (technical/settings.md § Sales — Registers). No float transfers or multi-register in MVP. Round 2 settled the edge case (F-walk-2): a cash refund when no register session is open is allowed (manager-approved), recorded with `register_session_id IS NULL`, and flagged in the daily summary and audit; cash payments *in* still require an open session per branch config. Builders: ledger and register tests must cover both paths.

**ADR-7 — Fixed appointment status enum, `in_progress`.** `booked, confirmed, arrived, in_progress, completed, cancelled, no_show`, with a code-level state machine; only legal transitions allowed (manager override for backward moves, audit-logged). Fresha's observed lifecycle is Booked/Confirmed/Canceled/No-show/Completed (technical/architecture.md § Entity: Appointment) and it additionally offers *custom* appointment statuses (technical/settings.md § Scheduling — Appointment statuses); we differ: custom statuses are deferred non-committed (candidate for Phase 12 automations, round 2 F-cov-5). Sale status is likewise fixed: `unpaid, part_paid, completed, voided` — the glossary's `draft`/`paid` are dropped as redundant and the draft `refunded` status is rejected (refunds are ledger rows, ADR-34).

**ADR-8 — Repeating series are Phase 11; no series columns in MVP.** Single appointments only. The chair explicitly rejected even a nullable `series_id` reservation: adding a nullable column later is a cheap migration; carrying a dead column through MVP is not. Fresha has waitlist and series-style depth we consciously sequence later (waitlist is Phase 11).

**ADR-9 — Duplicate clients: warn in MVP, merge tool in Phase 11.** Families share phone numbers; imports create duplicates. MVP warns on create (tenant-wide name/phone/email match) with an explicit proceed-and-record choice; import offers skip/merge-later/create. Interactive merge is Phase 11; the `merged_into` pointer column ships in the MVP migration so merges later have something to point with.

**ADR-10 — Full refunds and same-day void in MVP; partial refunds Phase 10.** A refund never mutates or deletes the original record; a void keeps the sale with status `voided` and requires a reason. The database enforces total refunded ≤ original payment. Round 2 elevated this to a blocker fix (F-perm-1): refunds and voids are **owner + branch manager only; receptionists are forbidden** — while keeping checkout, discounts, and tips. The requirements matrix cell that lumped them together is superseded. The `checkout` function enforces the split server-side, never UI-only. Partial refunds wait for gateway machinery in Phase 10.

### Tenancy and domain model (ADR-11..16)

**ADR-11 — Clients belong to the tenant; financial aggregates respect branch scope.** Clients visit any branch, and safety (allergies recorded at branch A must be visible to a therapist at branch B) demands tenant-wide client records — this is by design, not a leak (stated explicitly, round 2 F-walk-3). Financial aggregates (lifetime value, balances) come from secured RPCs filtered by the caller's branch scope. Round 2 hardened the edges: the staff role reads only basic fields (name, phone, allergy flags) through a column-restricted view limited to clients with appointments at their assigned branches, has no writes to client master data, and sees sales only through a `report_own_sales` RPC (F-DB-5/F-perm-2); client contact/allergy CSV exports are owner-only (F-verifier-3). Builders: negative export tests are Phase 7 acceptance criteria.

**ADR-12 — One staff record per person per tenant; branch assignments; optional login.** A therapist working at two branches is one row plus `staff_branch_assignments` (with default-branch and bookable flags); the conflict engine checks busy time across all branches. Non-login staff exist as records (nullable `user_id`); they appear in schedules and reports but never authenticate. Fresha's team-member flow was never safely exercisable in our survey (technical/flows.md § Flow 4 — UNVERIFIED), so this design is our own. Round 2 added the uniqueness guard (F-DB-9): partial unique `(tenant_id, user_id) WHERE user_id IS NOT NULL`, with a Phase 2 test. Builders: composite FKs (ADR-20 rule 5) prevent pairing tenant A's tenant_id with tenant B's staff or branch.

**ADR-13 — Services use branch override rows, snapshotted at booking.** Tenant-level `services` (defaults) plus `service_branch_overrides` (price/duration/enabled) resolved per branch and **snapshotted** onto `appointment_items`/`sale_items` at booking/checkout — history never drifts when prices change. Fresha prices services per location (technical/settings.md § Locations); we match that behaviour. Round 2's money-correctness fix (F-walk-1): a cross-branch reschedule must re-resolve price, duration, and buffers via `resolve_service(target_branch)` and re-snapshot them, with old and new values in the audit record — reusing the old branch's snapshot is a billing error and is acceptance-tested in Phase 5.

**ADR-14 — Invoice numbering is per branch, sequential, gap-tolerant.** Each branch has an `invoice_prefix` and its own row-locked counter; a sale gets `(branch_id, invoice_seq)` unique across the branch; gaps after failed transactions are allowed and documented. Operators think per branch (Fresha sale numbers likewise render per location context, technical/architecture.md § Entity: Sale). Round 2 (F-DB-7) extended the same discipline to appointment `ref_number`: `<prefix>-A<seq>` from a `kind`-discriminated counter, `UNIQUE (branch_id, ref_number)`, generated inside the booking RPC — a naked NOT NULL text column with no generator is prohibited.

**ADR-15 — The domain glossary is the naming authority.** One canonical table list (`staff_members`, `service_branch_overrides`, `branch_opening_hours`, …; `plan_features` added in round 2, F-7); banned synonyms (`location`, `employee`, `team_member`, `customer`) stay banned. The round-1 SQL drafts used conflicting names and are now **quarantined** under `sql/drafts-v1/` with superseded banners, outside the active migration path, with a CI gate that fails on any reference to them (round 2, F-1/F-verifier-2). Builders: the fresh migration set is written from the ADRs under `supabase/migrations/`; never apply a drafts-v1 file.

**ADR-16 — Bilingual name columns where operators see names.** `name_en`/`name_ar` on services, categories, block types, cancellation reasons, branches, tenants; people carry both scripts where available (clients: user's script plus `_alt` columns). Free-text notes stay single-script. Display falls back to the other language when one is missing. Fresha serves KW-specific configuration (technical/architecture.md § Localization); we match the bilingual intent from day one. Builders: every migration, form, and receipt template handles both columns.

### Money, payments and billing (ADR-17, 18, 34, 51)

**ADR-17 — Money is integer minor units (`bigint`), never numeric or float.** The sharpest conflict of round 1: KWD has three decimals, and the drafts split between integer fils and `numeric(12,3)`. Integer won because it keeps one representation across SQL, Deno, and TypeScript — `numeric` is exact but invites float conversion at every JS boundary. A `currencies` table holds the ISO-4217 exponent (KWD = 3); only the presentation layer renders decimals; column names end in `_minor`. Fresha's observed money fields are decimals rendered to the fil (technical/architecture.md § Entity: Sale), which is a rendering choice — our storage choice is the integer. Builders: no decimal.js/Dinero dependency in MVP; JSON stays within Number.MAX_SAFE_INTEGER (any realistic fils total is far below 2^53).

**ADR-18 — Subscription billing per tenant; minimal entitlement model in MVP.** We are a conventional B2B SaaS: `tenants.plan` plus a `plan_features` table and a `tenant_has_feature()` helper — feature gating is data, not code. Fresha uses Unleash feature flags (technical/architecture.md § Feature Flags); we differ: no runtime flags in MVP (round 2 G-5), entitlements only — flags would need a new ADR. Fresha also runs a wallet/FinanceAccount with a balance (technical/architecture.md § Entity: Wallet); we reject in-product wallets as a marketplace mechanic. Self-serve signup and subscription payment collection are Phase 17; until then the platform admin sets the plan during onboarding.

**ADR-34 — Manual payment methods in MVP; MyFatoorah in Phase 10 behind an abstraction.** MVP checkout records cash, card-terminal, KNET-terminal, bank-transfer, or "other" (each branch enables a subset); split payments across methods are allowed. The ledger is one `payments` table: `payment_type ∈ {payment, refund}`, refunds are positive amounts referencing the original payment (`refunds_payment_id`), a trigger caps total refunds ≤ original, no separate refunds table (round 2 blocker F-PLAN-2 — the requirements' "negative payment" phrasing is superseded). Fresha's checkout flow was never exercised in our survey (technical/flows.md § Checkout — NOT EXERCISED), so the checkout design is clean-room. Phase 10 adds MyFatoorah (Tap Payments as documented GCC alternative) behind a provider-neutral interface; all provider fee/settlement claims are integration assumptions re-verified at Phase 10 discovery. Webhook signature verification and idempotency are mandatory; merchant KYC starts before Phase 10 code freeze. Builders: Phase 10 adds rows to the same ledger — it does not introduce a new model.

**ADR-51 — Deterministic checkout calculation order and rounding (round 2).** Integer money was necessary but not sufficient: two valid implementations could still produce different totals. ADR-51 binds one executable order — line base → line discounts (fixed then percentage, capped at the line) → invoice-level discount allocated pro-rata by line (half-up per line, exact remainder to the largest line) → tax per line in basis points (inclusive prices extract `base × rate_bp ÷ (10000 + rate_bp)`) → tips outside the taxable base, never discounted → totals derived and checked server-side. `packages/core` exports this as pure functions with golden fil-level fixtures; tampered client totals are rejected. Builders: the Phase 6 RPC implements the identical order; reports and receipts inherit line-level numbers so the daily-summary reconciliation gate holds to the fil.

### Authorization and security (ADR-19..22)

**ADR-19 — Authorization from live membership lookup; the JWT is identity only.** The central contradiction of round 1: JWT-claim authorization means a revoked membership survives until token expiry. We rule: `auth.uid()` is the only identity input; tenant, role, and branch scope are derived per request from `memberships` via STABLE SECURITY DEFINER helpers; Edge Functions re-verify before privileged writes; a client-sent tenant/branch id is cross-checked against the derived scope, never trusted. A Custom Access Token hook may later cache claims for display only — never as the authorization source. Multi-tenant users keep an active-tenant context client-side (ADR-37), re-verified server-side. Builders: `memberships(user_id, tenant_id)` is the hot path; pgTAP proves revocation takes effect immediately.

**ADR-20 — Branch-scoped RLS is the security boundary.** Ten rules, binding on every migration: branch-scoped policies on every branch table; `profiles` self-only; `tenants` never client-insertable (onboarding function under service role, audit-logged); `has_tenant_role()` takes an **explicit** branch parameter (a forgotten argument must be a compile/SQL error, not a silent tenant-wide check — round 2 F-DB-2); **every** tenant-owned FK is composite on `(parent_id, tenant_id)` with attack-path pgTAP tests (F-DB-3); "all branches" is `branch_id NULL` + `all_branches` flag + partial unique indexes — the sentinel UUID is withdrawn because it cannot satisfy the composite FKs (blocker F-DB-1); role enum is exactly `tenant_owner | branch_manager | receptionist | staff` — no `platform_admin` role; platform operations use explicit, time-boxed, audited impersonation with a visible banner (F-DB-4/F-perm-4); SECURITY DEFINER functions set `search_path` (F-DB-13). Builders: the Phase 0 pgTAP harness (branch-A manager fails branch-B checks; cross-tenant FK inserts fail; nobody can set `platform_admin`) is the security regression suite every later phase extends.

**ADR-21 — Reports via `security_invoker` views and secured RPCs, grouped in branch-local time.** Postgres views bypass underlying-table RLS by default (Supabase: https://supabase.com/docs/guides/database/postgres/row-level-security), so report views are `WITH (security_invoker = true)` and heavy aggregates are SECURITY DEFINER RPCs that internally apply `current_branch_scope()`; day/week/month grouping converts to the branch's IANA zone before truncation. Round 2 (F-6): grants still apply — every view migration ships explicit GRANTs plus a pgTAP read test. Builders: CI checks every view for `security_invoker`.

**ADR-22 — Audit log is append-only, written by the database.** Triggers on audited tables and Edge Function paths write `audit_log`; direct DML is revoked from `anon` and `authenticated`; reads are role-scoped (owner tenant-wide, manager branch-scoped); retention ≥ 2 years. Direct supabase-js writes still produce audit rows because the trigger fires regardless of path; exports of client data are themselves audited. Builders: there is deliberately no client-insert path into the audit log.

### Booking integrity and time (ADR-23..26)

**ADR-23 — Appointment items carry their own staff member and time span.** A multi-service visit is an appointment envelope with items that each have `staff_id` and their own `effective_start/end` inside the window — sequential or parallel, conflict-checked per item over that item's span. The round-1 draft checked every item against the parent's whole range, which cannot represent two therapists working in parallel. Fresha's appointment entity is one service/one team member per card (technical/architecture.md § Entity: Appointment); our item model is richer because real spa workflows need it. Builders: snapshots (price, duration, buffers, bilingual service name) live on the item.

**ADR-24 — Double-booking prevention: exclusion constraints plus per-staff advisory locking.** The round-1 trigger did `SELECT count(*)` before insert — two concurrent transactions both see zero and both commit; the constraint the data model sketched was invalid SQL (cross-table subqueries are not allowed in exclusion constraints). Three layers now, in order of authority: (1) a real `EXCLUDE USING gist (staff_id WITH =, busy_range WITH &&)` on `appointment_items` (with a busy-status flag column, `btree_gist` extension), and an equivalent on `blocked_times`; (2) cross-entity conflicts (appointment vs block) serialize on `pg_advisory_xact_lock` per staff member inside the write transaction; (3) an RPC pre-check for friendly `CONFLICT` errors. Reschedules go through the same locked path — direct updates of time columns are prohibited, closing the "reschedule bypasses the trigger" hole. Concurrency tests (same-slot races) are the Phase 5 phase gate.

**ADR-25 — Buffers are first-class, snapshotted, part of the busy range.** Prep/cleanup minutes resolve per branch at booking time, snapshot onto the item, and extend `busy_range` — not billable, not added to duration. The calendar shows service duration while busy time includes buffers; slot generation subtracts them. Query-time-only buffers were rejected because historical bookings would shift when defaults change.

**ADR-26 — Opening hours, closed periods, blocked time.** `branch_opening_hours` handles overnight (`closes_at <= opens_at` = closes after midnight) and split intervals (a `seq` discriminator); `closed_periods` removes whole date ranges (Fresha parity: technical/settings.md § Scheduling — Closed periods); `blocked_times` are per-staff with a configurable type list (Fresha parity: technical/settings.md § Scheduling — Blocked time types), branch-scoped or all-branches via the ADR-20 rule-6 representation, and **every write goes through the locked staff RPC** because a direct insert takes no advisory lock and can silently land on a booked slot (round 2 F-DB-6). Creation rights: receptionist/manager create own-branch blocks; staff request time off and a manager approves; all-branches blocks are manager+. `shifts` are dated rows (not templates) with copy-previous-week; booking outside a shift is a soft, manager-overridable warning recorded in `booking_overrides`. The availability engine is opening hours ∩ shifts ∩ (duration + buffers) − appointments − blocked time − closed periods, in branch-local time with UTC storage.

### Database conventions (ADR-44..46)

**ADR-44 — UUID primary keys everywhere.** Human-readable numbers (invoice seq, appointment ref) are separate per-branch sequences, never the PK. Fresha's appointment IDs are integers (technical/architecture.md § Entity: Appointment) — enumerable and merge-hostile; we differ deliberately. Composite `(id, tenant_id)` uniques exist on parent tables to support ADR-20 rule 5.

**ADR-45 — `timestamptz` storage with an IANA zone per branch.** UTC in, branch-local rendering and grouping out. Round 2 (F-verifier-4) bound the daily semantics: **every daily metric is the local calendar date in the selected branch's zone**, converted to UTC for predicates (`[local 00:00, next local 00:00)`); cross-branch reports aggregate each branch in its own day then sum; midnight-boundary and DST fixtures are mandatory Phase 7 tests even though Kuwait has no DST (other tenants might). Builders: a 23:30 UTC sale must land on the correct Kuwait day in dashboard, register, and reports alike.

**ADR-46 — Mixed soft delete and status-based retention.** Clients soft-delete (`is_deleted`/`merged_into`); services/staff/branches deactivate (`is_active`); appointments and sales are status-based and never hard-deleted; financial rows are immutable (corrections are new refund rows); low-impact config rows may hard-delete. Soft-delete-everywhere was rejected as query noise on immutable records. Anonymization for privacy requests replaces personal fields while keeping financial records.

### Platform and operations (round 2: ADR-47..50, 52)

**ADR-47 — Rate limiting: platform limits in MVP; a per-tenant limiter designed in Phase 9.** Supabase rate-limits Auth endpoints at platform level, but there is **no** per-function `rate_limit` key in the Supabase CLI config (documented keys are `verify_jwt`, `import_map`, `entrypoint`, `static_files` — https://supabase.com/docs/guides/cli/config). The round-1 draft's config example was unbuildable and is superseded. MVP relies on platform/Auth limits; the application-level per-tenant limiter (token bucket, documented quotas and failure mode) is designed and owned by the Phase 9 public-booking threat model.

**ADR-48 — Data residency: eu-central-1 as a recorded assumption with a legal gate.** Supabase has no Kuwait region. Production defaults to Frankfurt (GDPR-aligned, near), recorded as a **product/legal assumption, not a compliance claim** — no document may assert the region "satisfies Kuwait PDPA" without legal/provider evidence. Owner: product owner with legal counsel; verification gate before Phase 8 go-live; if legal requires another region, the project migration is scheduled before go-live.

**ADR-49 — Backups, PITR, RPO/RTO, restore drills.** Paid plan with managed daily backups plus PITR; targets RPO ≤ 24 h (practical loss minutes with PITR), RTO ≤ 4 h; retention ≥ 7 days plus a manual snapshot before every Phase 8 cutover import. The drill — restore a production snapshot to a scratch project, run pgTAP smoke, reconcile one daily-sales report, timed — executes in Phase 7 and rehearses before each cutover.

**ADR-50 — Tenant offboarding and data deletion contract.** Four ordered steps: full export (audited) → soft-archive 28 days (memberships deactivated, read-only) → anonymize personal fields (the Phase 4 anonymize RPC) → retain financials for the Kuwaiti commercial period (default assumption 10 years, legal confirms at Phase 17 scheduling), then delete. Audit retention (≥ 2 years) is a floor, not the financial period.

**ADR-52 — Branch calendar preferences and client source.** Branches get typed columns — `first_day_of_week` (default **Saturday**, Gulf weeks; the Intl default would misalign Arabic calendars), `time_format` (default 24), `slot_step_minutes` (5/10/15/30, default 15) — created in Phase 1, consumed by the Phase 5 slot engine and calendar/shift-grid rendering. `clients.source` (nullable; `walk-in` for manual, `imported` for CSV rows without a value) ships in Phase 4: cheap now, costly to backfill; source reporting is deferred non-committed. Fresha has first-class client sources (technical/settings.md § Clients — Client sources); we add the column now and the analytics later.

### Backend architecture (ADR-27..35)

**ADR-27 — One Edge Function per bounded context.** Seven MVP functions (`bookings`, `checkout`, `catalogue`, `clients`, `staff`, `reports`, `onboarding`) with internal action routing; Phase 9 adds `notifications`, `webhooks`, `online-booking`. A failing or redeploying function must never take down the rest (the owner's isolation requirement). Fresha runs a single GraphQL API host (technical/architecture.md § API Hosts and Catalogue); we differ deliberately for blast radius. The round-1 `auth-hook` function is removed (ADR-19), and the fictional per-function rate-limit config is gone (ADR-47). Builders: documented limits respected — 256 MB memory, 2 s CPU/request, 150/400 s wall clock, bundle 20 MB CLI-bundled / 5 MB server-side (https://supabase.com/docs/guides/functions/limits); heavy work goes to SQL or queues.

**ADR-28 — Hybrid data access with an explicit direct-write allowlist.** Reads go direct via supabase-js under RLS (lists, details, report views); single-table writes are allowed only where RLS + check constraints fully express the authorization and no cross-table invariant exists: `profiles` (self), `client_notes` (receptionist+), `clients` contact/profile fields (receptionist+; `is_blocked`/`is_deleted`/`merged_into` carved out through the `clients` function — round 2 F-4), `settings` (role-gated), `shifts` (manager-gated). Everything money-, conflict-, or provisioning-shaped — appointments, items, sales, payments, register, tips, counters, blocked times, memberships, tenants, branches — goes through a function or RPC. The allowlist lives in exactly two mirrored places (CONVENTIONS and the architecture skill) and a PR must show the policies that make any addition safe.

**ADR-29 — One API envelope and one error code catalogue.** `{ok, data}` / `{ok, error:{code, message, fieldErrors?, details?}}` with nine codes (`VALIDATION`…`UNAVAILABLE`), defined once in `packages/validation` and mirrored in `_shared/errors.ts`. Two member drafts proposed two different contracts; drift would have been immediate. `message` is a developer string; user copy is i18n'd on the frontend keyed by code.

**ADR-30 — Public invocation shape `/<function>/<action>`.** Bounded-context functions with kebab-case internal actions (`POST /functions/v1/bookings/reschedule`); the frontend never hand-builds these URLs — `packages/api` typed wrappers are the only place slugs appear. Breaking changes version the path and ship frontend+backend in the same commit. Per-action function slugs were rejected as contradicting ADR-27 granularity.

**ADR-31 — Idempotency keys for money mutations.** Checkout, refunds, and (Phase 10) webhooks take a client-generated `Idempotency-Key` UUID; the `idempotency_keys` table replays the cached response on retry, `processing` collisions return 409, keys expire after 30 days via pg_cron. A double-clicked cash checkout must not double-record a sale. Queue consumers are idempotent by the same discipline (delivery is at-least-once).

**ADR-32 — Shared Edge Function code via `_shared/`, no shared mutable state.** Functions stay independently deployable but share auth/errors/logging/CORS/idempotency helpers. Binding corrections: no mutable module-level state (isolate lifecycles make it unsound anyway); any `_shared` change redeploys **all** functions in the same CI run — documented blast radius, stricter review, small stable surface. Shared Zod schemas come from `packages/validation` via a Deno-compatible export, never duplicated.

**ADR-33 — Async work via pg_cron + pgmq, idempotent consumers.** Scheduling is pg_cron (hosted install form with `pg_catalog` schema and grants, per https://supabase.com/docs/guides/cron/install); queued work is Supabase Queues (pgmq) with visibility timeouts. Delivery is **at-least-once** — the round-1 draft's "exactly-once" was wrong and is superseded. MVP uses queues only for CSV import/export jobs; notifications come in Phase 9. Database Webhooks are not used in MVP.

**ADR-35 — Pin and CI-verify the Supabase server wrapper.** The round-1 examples used a `withSupabase` wrapper from an AI-prompts doc page — a draft snippet, not a tested contract. We build our own thin `_shared/server.ts` on the documented `@supabase/supabase-js` client and Deno.serve; if a Supabase-published wrapper is adopted later, it is version-pinned with a CI smoke test of the exact API surface we use.

### Frontend architecture (ADR-36..43)

**ADR-36 — pnpm monorepo, two apps, six packages.** `apps/back-office` (MVP) and `apps/booking` (Phase 9, scaffold only) over `packages/{ui,db,api,validation,i18n,core}` plus `supabase/` in one repo. Frontend and backend deploy from the same commit. Multi-repo with published packages was rejected as ceremony at this team size. Visual design stays undefined here — it comes from the owner's external design skill, and only `packages/ui` touches it.

**ADR-37 — Branch context in the URL; tenant context in the session.** Branch is a URL search param (shareable deep links persist); tenant is session context loaded from memberships after sign-in, with a switcher for multi-tenant users (round 2 F-fe-1 superseded the "one tenant per user" phrasing). The server re-derives membership and scope on every request regardless of what the client sent (ADR-19). Default branch persists in localStorage; single-branch receptionists get a locked switcher; RLS remains the real boundary.

**ADR-38 — TanStack Query v5 with scope-aware key factories; Realtime authorization tested.** Every cache key carries its entity's scope: tenant-scoped entities (clients) key on the tenant segment; branch-scoped entities (appointments) on `[tenantId, branchId]` — so tenant switches never serve stale caches (round 2 F-PLAN-8/F-fe-2 qualified the round-1 "always branch" rule). Realtime patches caches from `postgres_changes`; channel authorization (tenant A/branch A must never receive tenant/branch B payloads) is a CI test, not just UI key discipline. Fresha's dashboard showed no WebSocket in our survey — polling only (technical/architecture.md § Realtime); we go beyond observed Fresha behaviour, which is why the leakage tests are mandatory. Polling (≤5 s staleness) is the fallback if channel auth proves insufficient.

**ADR-39 — React Hook Form + Zod, schemas shared with Edge Functions.** One Zod schema per operation in `packages/validation`; forms use `zodResolver`; functions import the same schema — one change updates both in one PR. Zod stays pure JS (Deno-importable) and is input defense only: authorization is never delegated to a schema.

**ADR-40 — Lingui (ICU) + logical CSS + Intl; Arabic-capable search.** Full EN/AR with RTL from day one is an MVP gate. Lingui build-time catalogs; `dir`/`lang` from the persisted preference; logical CSS properties only (stylelint-enforced); directional icons mirrored via `@repo/ui` primitives (`flipOnRtl` — raw `scaleX(-1)` advice is superseded); KWD with 3 decimals and branch time zones via centralized `Intl` helpers; missing Arabic translations fail CI. Binding: a normalized `search_text` (diacritics stripped, alef/ya/ta-marbuta unified, latin/arabic digits unified) with a trigram index so Arabic search matches variants (US-CL-6).

**ADR-41 — schedule-x behind a `<BookingCalendar>` wrapper; premium license conditional on a Phase 0 spike.** The calendar is the hardest screen; building from scratch is a multi-month trap. schedule-x is wrapped in a feature-owned component and never leaks. The premium resource-scheduler license is approved **conditionally**: a one-week Phase 0 spike must prove NFR-4 render budget, keyboard operation, RTL mirroring, ≥8 staff columns — go: buy; no-go: schedule-x core with custom resource columns, meeting the same bar before Phase 5 exits. Either way the verdict is recorded by updating the ADR.

**ADR-42 — TanStack Router with typed search params.** Filters, dates, and view state live in URLs (typed `validateSearch` with Zod); role guards in `beforeLoad` are UX only — RLS and function checks are the security boundary; deep links restore after login; Supabase email+password auth (MFA/magic links deferred). React Router lost on search-param typing.

**ADR-43 — Exports stream from Edge Functions; Storage comes in Phase 9.** MVP CSV exports (UTF-8 BOM for Excel/Arabic) are generated server-side and streamed as downloads, queued for large jobs; export events are audited and role-scoped (owner tenant-wide incl. contacts; manager own-branch operational only; client-contact exports owner-only). Phase 9 introduces Storage with tenant/branch-prefixed paths and bucket policies mirroring RLS — that design task is unconditional and ships before any upload feature (round 2 F-PLAN-16), while the upload capability itself stays conditional. Client-side CSV generation was rejected: it bypasses scope checks and chokes on large data.

## 2. The council's findings

### The story in brief

Round 1 produced five member drafts (requirements, data model, backend, frontend) plus an adversarial review that ruled on conflicts and open questions; the chair resolved them into 46 ADRs. The round-1 review's biggest catches: **money representation** (integer fils vs `numeric`, ruled integer), **authorization source** (JWT claims vs live lookup, ruled live lookup), **double-booking** (a race-prone `SELECT count(*)` trigger, ruled constraints + advisory locks), **tenant isolation** (tenant-only policies on branch tables, world-readable profiles, unconstrained denormalized `tenant_id` — ruled the ten binding rules of ADR-20), and **buffers/multi-service visits missing from the draft SQL** (ruled ADR-23/25).

Round 2 was a four-way adversarial audit (coverage, data/backend, decisions, plan/skills) adjudicated by a verifier with web fact-checking, then applied by the chair as 60 accepted findings (5 blockers, 20 majors, 26 minors, 5 verifier-sweep majors; 3 rejections honored). The blocker class: **the sentinel UUID for "all branches" could not satisfy the composite tenant FKs** (replaced by nullable `branch_id` + `all_branches` flag + partial unique indexes); **refund semantics were three-way contradictory** (negative amounts vs positive ledger rows vs a separate refunds table — bound to positive `payment_type='refund'` rows); **two phase-numbering schemes made gates ambiguous** (canonicalized to plan Phases 0–17); **the MVP home screen was promised but unbuilt anywhere** (US-DASH-1 added to Phase 7); and **receptionists could issue refunds** because the matrix cell lumped them with checkout (split: owner/manager only, receptionist forbidden, enforced server-side).

The verifier's own sweep added five majors the four auditors had all missed: no document-precedence rule (unsafe drafts stayed actionable — fixed by the precedence rule plus quarantine), no clean-migration CI gate proving schema+functions+types build together, no privacy boundary for tenant-wide client data in reports/exports, no binding definition of "today" for daily metrics across time zones, and no deterministic money-calculation order (ADR-51).

Six new ADRs (47–52) closed decision-level gaps the audits exposed: rate limiting (no fictional config keys), data residency (eu-central-1 as an assumption with a legal gate), backups/RPO/RTO with restore drills, a tenant offboarding contract, the deterministic checkout calculation, and branch calendar preferences + client source. The round also rebuilt Phase 8 on real import software (Epic 8.0) instead of a runbook, added the taxes summary report, and committed to one schedule number (22-week critical path + 20% buffer ≈ 27 weeks).

### Round 2 findings table

Built from `review2/adjudication.md` and `REVISION_LOG.md`. "Lives in" = where the fix is now binding.

| Finding(s) | Severity | Verifier ruling | Resolution — lives in |
|---|---|---|---|
| F-PLAN-1 / F-cov-1 | Blocker | Accept (choose: implement or remove) | US-DASH-1 home/today screen implemented in Phase 7 (scope, Epic 7.2, acceptance, default post-login route); ADR-45 day boundaries |
| F-PLAN-2 | Blocker | Accept | Positive-amount refund ledger; ADR-34 binding clarification + ADR-7 + glossary + Phase 6 work/AC/pgTAP; draft SQL 000010 quarantined |
| F-PLAN-3 / F-3 | Blocker | Accept, merged | Canonical plan Phases 0–17; swept every ADR, CONVENTIONS, and 5 skill files; ADR-41 gate → plan Phase 5; ADR-18 → plan Phase 17 |
| F-DB-1 | Blocker | Accept (nullable+flag) | Sentinel UUID withdrawn; `branch_id NULL` + `all_branches` + CHECK + partial unique indexes; ADR-20 rule 6, ADR-26, CONVENTIONS §3.2/§5, Phase 0/2 |
| F-perm-1 | Blocker | Accept | Refunds/voids owner+manager only, receptionist FORBIDDEN; ADR-10 (supersedes the §3 matrix cell), CONVENTIONS §5/§6, Phase 6 ACL tests |
| F-DB-2 | Major | Accept | `has_tenant_role` explicit branch param (no default) + `has_tenant_role_any_branch`; ADR-20 rule 4; Phase 0 pgTAP |
| F-DB-3 | Major | Accept | Composite `(parent_id, tenant_id)` FKs on every tenant-owned pair + attack-path tests; ADR-20 rule 5; CONVENTIONS §3.2; Phase 0 harness |
| F-DB-4 / F-perm-4 | Major | Accept, merged | `platform_admin` removed from role enum; grant rules + audited impersonation banner; ADR-20 rule 9; Phase 1 Epic 1.3 |
| F-DB-5 / F-perm-2 | Major | Accept | Staff read-only basic client fields via column-restricted view, no writes; `report_own_sales` RPC; ADR-11; Phase 4/6 |
| F-DB-6 / F-PLAN-18 | Major | Accept with change | Blocked-time roles restored; all writes via locked staff RPC; removed from direct-write allowlist; ADR-26/28; Phase 2 Epic 2.3 |
| F-DB-7 | Major | Accept (generate + constrain) | Appointment `ref_number` from `invoice_counters.kind` counter, `UNIQUE (branch_id, ref_number)`; ADR-14; Phase 5 |
| F-DB-8 | Major | Accept | Report SQL joins fixed (`sale_items.item_id/item_type`), pre-aggregated counts, grants; false "tenant_id makes views safe" claim banned; Phase 7 Epic 7.1 |
| F-PLAN-4 | Major | Accept | Currency lock: UI predicate in Phase 1, DB trigger + pgTAP in Phase 6 (one cross-phase reference) |
| F-PLAN-5 | Major | Accept | Diagram `P9 --> P12` added; gantt fixed (p12 after p9, p13 after p8, p16 after p8); Mermaid re-validated |
| F-PLAN-6 | Major | Accept | Epic 8.0 import software (branches/staff/services/shifts functions, staging RPCs, dry-runs, idempotent batches, grant discipline) |
| F-PLAN-7 | Major | Accept | Client-profile history named to Epic 5.3 (appointments + no-show count) and Epic 6.4 (sales history) |
| F-PLAN-8 / F-fe-2 | Major | Accept, merged | Query keys qualified by entity scope (tenant vs tenant+branch); canonical `useRealtime(entity, tenantId, branchId)`; ADR-38; Epic 5.4 |
| F-PLAN-9 | Major | Accept | Stylelint `property-disallowed-list` (or logical-CSS plugin) with citation; physical-property exceptions preserved; i18n-rtl skill |
| F-PLAN-10 | Major | Accept | Risk register gained an accountable Owner (role) column; Owner signal kept separate |
| F-PLAN-11 | Major | Accept | Go-live checklist: bilingual privacy notice, DPA, ADR-48 confirmation, audit/export demo, Arabic content review; Epic 8.1 task |
| F-cov-2 | Major | Accept with change | Rich analytics deferred non-committed; separate "dashboards & analytics" workstream after Phase 12 if scheduled; ADR-5 |
| F-walk-1 | Major | Accept | Cross-branch reschedule re-resolves and re-snapshots price/duration/buffers, old+new audited; ADR-13; Phase 5 AC |
| F-1 | Major | Accept with change (quarantine) | 13 draft SQL files → `sql/drafts-v1/` with banners + `sql/README.md`; CI clean-migration gate fails on any reference; ADR-15 |
| F-2 | Major | Accept with change (banner) | Precedence rule (F-verifier-1) + explicit stale-area list in CONVENTIONS header; member files left unedited per chair brief (deliberately open) |
| F-4 | Major | Accept | `is_blocked`/`is_deleted`/`merged_into` carved out of direct writes via `clients` function; ADR-28; Phase 4 |
| G-1 | Major | Accept | ADR-47 rate limiting; no fictional config key; Phase 9 threat model owns the limiter design |
| F-verifier-1 | Major (sweep) | Accept | Document-precedence rule in decisions.md + CONVENTIONS header |
| F-verifier-2 | Major (sweep) | Accept | CI clean-migration acceptance gate (reset → gen types → build → test db → adversarial fixtures; fails on drafts-v1) |
| F-verifier-3 | Major (sweep) | Accept | Report/export privacy boundary: tenant-wide lookup for safety, branch-scoped aggregates, owner-only contact exports, allergy redaction, negative tests; ADR-11/43 |
| F-verifier-4 | Major (sweep) | Accept | Every daily metric = branch-local calendar date → UTC predicates; midnight/DST fixtures; ADR-45; Phase 7 |
| F-verifier-5 | Major (sweep) | Accept | ADR-51 deterministic checkout order/rounding + golden fixtures; CONVENTIONS §7; Phase 6 |
| F-DB-9 | Minor | Accept | Partial unique `(tenant_id, user_id) WHERE user_id IS NOT NULL`; ADR-12; Phase 2 |
| F-DB-10 | Minor | Accept with verification | pg_cron hosted install form + official citation; ADR-33; Phase 0; validate against pinned CLI |
| F-DB-11 | Minor | Accept with change | Fictional `rate_limit` key removed; corrupted text restored; `supabase test db` pinned-CLI note |
| F-DB-12 | Minor | Accept with change (verification only) | KNET-no-recurring labeled a provider-specific assumption (PayTabs citation); Phase 10 re-verification list; design stands |
| F-cov-3 | Minor | Accept | `report_taxes_summary` added to Phase 7 as the seventh report; ADR-5 |
| F-cov-4 | Minor | Accept with change | Service charges out of scope, non-committed; draft column rejected with the quarantined SQL; ADR-2 |
| F-cov-5 | Minor | Accept | Custom appointment statuses deferred non-committed (Phase 12 candidate); ADR-7 |
| F-cov-6 | Minor | Accept | Client forms (consent/intake) non-committed Phase 11 candidate |
| F-cov-7 | Minor | Accept | ADR-52 branch `first_day_of_week` (Saturday default), `time_format`, editor in Phase 1, threaded to Phase 5 |
| F-cov-8 | Minor | Accept | ADR-52 `clients.source` nullable with walk-in/imported defaults; CSV template column; Phase 4 |
| F-perm-3 | Minor | Accept | Client CSV import owner-only; ADR-20 rule 8 note; Phase 4 |
| F-fe-1 | Minor | Accept | Multi-tenant memberships + switcher; server re-derives every request; ADR-37 |
| F-fe-3 | Minor | Accept | Degraded-network UX (Reconnecting banner, same-key retry, stale indicator); no offline-first writes in MVP; CONVENTIONS §7 |
| F-i18n-1 | Minor | Accept | Bidi isolation (`<bdi>`/`dir=auto`) guidance + mixed-direction test; i18n-rtl skill; CONVENTIONS §7 |
| F-i18n-2 | Minor | Accept | `flipOnRtl` as the only mirroring primitive; raw `scaleX(-1)` superseded via precedence rule |
| F-term-1 | Minor | Accept | `in_progress` canonical everywhere in the editable corpus; requirements' "Started" superseded via ADR-7 |
| F-skill-1 | Minor | Accept | Glossary gained Tax rate, Currency (+ Client source, Appointment reference) entries |
| F-walk-2 | Minor | Accept | Out-of-session cash refunds: manager-approved, unlinked, flagged in daily summary/audit; ADR-6; Phase 6 |
| F-walk-3 | Minor | Accept | Explicit statement: clients/allergies/notes intentionally tenant-visible; operational/financial branch-scoped; CONVENTIONS §5; Phase 8 training |
| F-5 | Minor | Accept | Snapshot-column exception to the no-prefix naming rule; CONVENTIONS §3.2 |
| F-6 | Minor | Accept with change | security_invoker views need explicit grants + pgTAP read test; Supabase grants-and-policies guidance cited; ADR-21 |
| F-7 | Minor | Accept | `plan_features` added to the ADR-15 canonical table list |
| F-BE-1 | Minor | **Rejected as stated** | Both bundle limits stated (20 MB CLI-bundled local / 5 MB server-side) with official citation; the "5 MB is wrong" claim was false in context |
| G-2 | Minor | Accept with change | ADR-48 region assumption (no PDPA claim); Phase 8 legal gate |
| G-3 | Minor | Accept | ADR-49 backups/PITR, RPO ≤ 24 h, RTO ≤ 4 h, restore drill scope, Ops owner |
| G-4 | Minor | Accept | ADR-50 offboarding contract (export → 28-day archive → anonymize → 10-year-default financial retention, legal confirms) |
| G-5 | Minor | **Rejected as a required ADR** | Convention instead: no runtime feature flags in MVP; entitlements gate; a new ADR only if flags are introduced |
| G-6 | Minor | Accept with change | Environment topology normative in CONVENTIONS §8 (local CLI / staging preview branch / production paid plan in ADR-48 region; deploys from `main`) |
| F-PLAN-12 | Minor | Accept | `slot_step_minutes` field/editor in Phase 1, consumed by the Phase 5 slot engine (ADR-52) |
| F-PLAN-13 | Minor | Accept | One schedule commitment: 22-week critical path + 20% buffer ≈ 27 weeks; 72-ew arithmetic explained |
| F-PLAN-14 | Minor | Accept | Drafting prose replaced with the settings/onboarding routing rule (Phase 1) |
| F-PLAN-15 | Minor | Accept | Arabic plural example covers all six categories (i18n-rtl skill) |
| F-PLAN-16 | Minor | Accept with change | Phase 9 Storage design task unconditional, ships before any upload feature; upload capability conditional |
| F-PLAN-17 | Minor | Accept with change | Recorded decision: post-MVP phases decision-level only; backlogs at scheduling time |

### Were all accepted findings actually applied?

I verified the revision rather than trusting it. Checks run against the revised corpus (grep + read, not just the log's claims):

- The five blockers: US-DASH-1 present in Phase 7 scope/Epic 7.2 with default-route behavior; positive refund ledger in ADR-34/Phase 6; canonical 0–17 numbering swept (no bare release-"Phase 2/3" references found); sentinel UUID absent from active docs (grep over `skills/` and `sql/` excluding drafts-v1: zero hits) with the nullable+flag model in ADR-20 rule 6 and CONVENTIONS; refund/void split in ADR-10 and Phase 6 AC.
- Spot-checks of majors and minors across every area: F-DB-2 (`has_tenant_role_any_branch` in the database skill), F-DB-7 (counter `kind` + `UNIQUE (branch_id, ref_number)` in ADR-14 and Phase 5), F-cov-3 (`report_taxes_summary` in Phase 7), F-PLAN-5 (`P9 --> P12` edge present), F-walk-1/2 (ADR-13/ADR-6 amendments + Phase 5/6 tests), F-PLAN-13 (22-week + 20% buffer in the plan header), F-DB-9/10/13 (ADR-12/33/20 rule 10), F-6/F-7 (ADR-21 grant language, `plan_features` in ADR-15), F-PLAN-9 (`property-disallowed-list` in the i18n-rtl reference), F-skill-1 (Tax rate glossary entry), F-PLAN-15 (six Arabic plural categories in the skill), F-1 (banners present in every `sql/drafts-v1` file).
- The three rejections were honored, not quietly dropped: F-BE-1's "5 MB is wrong" correction was rejected and both limits are stated in ADR-27 with the official citation; G-5 became a convention, not an ADR; F-DB-12's severity rationale was superseded with only the re-verification action retained.

**No accepted finding was found unapplied.** The two gaps that remain are recorded deliberately: the round-1 member files (requirements/data-model/backend/frontend) were not edited (chair brief), so their superseded passages are handled by the precedence rule and the stale-area list; and the active migration set is Phase 0/1 build work (drafts are quarantined, not rewritten). Both are in the "deliberately left open" list of REVISION_LOG.md and §4 below.

## 3. Final independent pass

I re-read the revised `decisions.md`, `CONVENTIONS.md`, and `IMPLEMENTATION_PLAN.md` end to end as a fresh reviewer. The corpus is now internally consistent to a degree round 1 never reached: the phase numbering is single-scheme and swept; the money model is one representation bound by one calculation order; the authorization model is one lookup path with one role enum; the all-branches representation is single-model; the ADRs, CONVENTIONS, implementation plan, and skills cross-reference each other correctly (I traced ADR-20's ten rules, the ADR-51 order, and the allowlist in both mirrored locations). Sizes add up: Phases 0–8 sum to the stated 72 engineer-weeks, and the 22-week critical path + 20% ≈ 27 weeks is arithmetically consistent with the gantt's dependencies. The residual defects found are below (§5); none is a contradiction inside the binding documents — they are omissions or under-specifications the rounds did not catch. Two of them (export wall-clock, pg_net) depend on platform facts I verified against current Supabase documentation.

## 4. Open questions for the owner

Each with the council's recommended answer.

1. **Data residency (ADR-48).** Do you accept eu-central-1 (Frankfurt) as the production region — pending legal confirmation of the Kuwait PDPA posture before Phase 8 go-live — or do you want a different region investigated now? *Recommendation: accept eu-central-1 as the working assumption and engage legal counsel early enough that the Phase 8 gate is a confirmation, not a discovery.*
2. **Financial retention period (ADR-50).** The offboarding contract assumes 10 years for sales/payment records. Is that the retention your accountant/lawyer wants? *Recommendation: keep 10 years as the default assumption and have legal confirm it at Phase 17 scheduling (it only binds then).*
3. **schedule-x premium license budget (ADR-41).** The calendar spike runs in Phase 0 week 1; a "go" verdict means buying the license immediately. *Recommendation: pre-approve the budget now so a go verdict doesn't stall Phase 5.*
4. **Merchant onboarding for online payments (Phase 10).** MyFatoorah KYC (commercial registration, IBAN, bank process) has multi-week lead time. *Recommendation: start merchant onboarding before Phase 10 code freeze — ideally around Phase 8 — even though online payments are later.*
5. **Lift the round-1 file edit restriction?** requirements.md, data-model.md, backend.md, frontend.md still contain superseded passages (handled by the precedence rule + stale-area list). *Recommendation: keep the restriction for this round; if anyone will onboard new team members who read those files raw, reconcile them as a small follow-up task.*
6. **Notification providers (Phase 9).** Email (Resend/SendGrid) and SMS/WhatsApp (Twilio/WATI) are named but deferred to Phase 9 discovery. *Recommendation: plan email-first (cheapest, covers receipts/reminders) and WhatsApp for the Kuwait market, and confirm costs/API terms at Phase 9 discovery.*
7. **Staff time-off approval workflow (see F-final-product-1).** ADR-26 says staff *request* time off and a manager approves. The request/approval state needs a small design decision (pending column vs request queue) or an explicit deferral. *Recommendation: in MVP, let managers create blocks on behalf of staff (phone/in-person request, no app workflow) and defer the in-app request/approval flow to Phase 9+; record the choice either way.*
8. **Team assumptions.** The plan assumes 3 engineers, a part-time QA engineer from Phase 5, and an Arabic-speaking content reviewer for Phase 8 cutover. Are these committed? *Recommendation: confirm before Phase 5; QA-from-Phase-5 is load-bearing for the calendar/checkout phase gates.*
9. **`supabase test db` command form.** To be re-confirmed against the pinned Supabase CLI at Phase 0 (current Supabase docs use `supabase test db`; the round-1 draft's `supabase db test` is superseded). *Recommendation: treat this as a Phase 0 checklist item, not an open question.*

## 5. Residual issues

Found during the final independent pass. Format follows the round-2 finding convention.

### F-final-backend-1: Full-tenant export benchmark exceeds the Edge Function wall-clock limit
- Severity: major
- Location: ADR-43; IMPLEMENTATION_PLAN Phase 7 (Epic 7.3 "Full-tenant export job (≤10 min benchmark)"); NFR-10
- Problem: ADR-27/CONVENTIONS document the Edge Function wall-clock limit (150 s free / 400 s paid plans — https://supabase.com/docs/guides/functions/limits), yet the full-tenant export benchmark is ≤10 min (600 s) for 100k clients / 1M appointments. A single invocation — streamed or not, queue-consumer or request-handler — cannot legally run that long; the plan never says how a >400 s export is supposed to complete.
- Evidence: Supabase limits page (verified 2026-10-04): "Maximum Duration (Wall clock limit): Free plan: 150s, Paid plans: 400s".
- Fix: specify a chunked/resumable export job: pgmq messages per data slice (e.g. 10k clients each), each processed well under the wall-clock limit, parts assembled into the final download (or streamed as parts); the ≤10-min benchmark then measures the whole job, not one invocation. Add the design note to ADR-43 and an Epic 7.3 task.
- Affects: ADR-43, Phase 7 Epic 7.3, NFR-10.

### F-final-db-1: pg_net extension missing from the Phase 0 extension list
- Severity: minor
- Location: IMPLEMENTATION_PLAN Phase 0 database work; ADR-33
- Problem: ADR-33 says "pg_cron schedules Edge Function invocations via pg_net", and Supabase's scheduling documentation requires both extensions (https://supabase.com/docs/guides/functions/schedule-functions), but the Phase 0 extension migration lists only `btree_gist`, `pgcrypto`, `pg_trgm`, `pg_cron` (hosted form), and `pgmq`. `pg_net` is never created anywhere.
- Evidence: Supabase docs — scheduling Edge Functions uses `pg_cron` "in combination with the `pg_net` extension" (verified 2026-10-04).
- Fix: add `create extension pg_net;` to the Phase 0 extensions migration (Epic 0.2) and to the supabase-database skill's extension list; validate against the pinned CLI in the F-verifier-2 clean-migration gate.
- Affects: Phase 0 Epic 0.2, ADR-33, skills/supabase-database.

### F-final-db-2: One-open-register-per-branch invariant has no named enforcement
- Severity: minor
- Location: ADR-6; IMPLEMENTATION_PLAN Phase 6 (`register_sessions`)
- Problem: ADR-6 requires "one open session at a time" per branch, and Phase 6 AC tests the open→close cycle, but no mechanism is specified and no test pins the invariant under concurrency.
- Evidence: ADR-6 decision text; Phase 6 database work and pgTAP list (no unique/partial-index item).
- Fix: add a partial unique index `ON register_sessions(branch_id) WHERE closed_at IS NULL` (or equivalent `opened_at/closed_at` nullity column) and a Phase 6 pgTAP/concurrency test (two simultaneous opens on one branch — one fails).
- Affects: ADR-6, Phase 6 Epic 6.1.

### F-final-db-3: idempotency key uniqueness ignores the function/action dimension
- Severity: minor
- Location: ADR-31; CONVENTIONS §4.3
- Problem: `idempotency_keys` has a `function` column but the uniqueness is `(tenant_id, key)`. If a client (or a future wrapper bug) reuses a key across different actions, the replay returns the wrong cached response or a confusing mismatch instead of a clean per-action replay boundary.
- Evidence: ADR-31 decision text.
- Fix: either make the unique constraint `(tenant_id, key, function)` (action-level safety) or state the one-key-per-mutation discipline as a binding rule in `packages/api` with a negative test. The first is safer; the second is free.
- Affects: ADR-31, Phase 6 pgTAP, packages/api.

### F-final-db-4: invoice_counters uniqueness with the `kind` discriminator is unstated
- Severity: minor
- Location: ADR-14 (round-2 F-DB-7 extension)
- Problem: `invoice_counters` gained a `kind` discriminator (`invoice | appointment_ref`) so a branch can hold multiple counter rows, but the table's uniqueness is nowhere stated — without `UNIQUE (branch_id, kind)`, a duplicate counter row of the same kind could silently fork the sequence.
- Evidence: ADR-14: "one row per branch" (original) vs "gains a `kind` discriminator" (round 2).
- Fix: state `UNIQUE (branch_id, kind)` (plus `CHECK kind IN ('invoice','appointment_ref')`) in ADR-14's consequences and the Phase 1 migration; extend the counter-race test to both kinds.
- Affects: ADR-14, Phase 1 Epic 1.1, Phase 5 concurrency tests.

### F-final-db-5: Overnight-hours representation makes a 24-hour day ambiguous
- Severity: minor
- Location: ADR-26 (`branch_opening_hours`)
- Problem: `closes_at <= opens_at` means "closes after midnight", which makes `closes_at = opens_at` ambiguous (a zero-length interval or a 24-hour day?) and gives closed days no explicit representation beyond `is_closed`.
- Evidence: ADR-26 decision text.
- Fix: forbid equal values (`CHECK (closes_at <> opens_at OR is_closed)`) or define equality as 24-hour open; add the case to the mandatory overnight/DST test fixtures in Phase 1/5.
- Affects: ADR-26, Phase 1 DB work, Phase 5 slot-engine tests.

### F-final-product-1: Staff time-off request/approval flow has no data model or task
- Severity: minor
- Location: ADR-26; IMPLEMENTATION_PLAN Phase 2 (Epic 2.3); CONVENTIONS §5
- Problem: ADR-26 and the role matrix say staff *request* time off and a manager approves (creates it), but `blocked_times` has no pending/approved state, there is no request queue, and no Phase 2 backlog task implements an approval flow — the requirement as written cannot be built.
- Evidence: ADR-26 round-2 text; Epic 2.3 task list (RPC + role rows only).
- Fix: pick one: (a) MVP simplification — managers create blocks on behalf of staff, no in-app request state, recorded as an ADR-26 note (matches the owner-question recommendation in §4.7); or (b) add a `status` column + manager approval action + Epic 2.3 task. Either is fine; silence is not.
- Affects: ADR-26, Phase 2 Epic 2.3, requirements §3 matrix reading.

### F-final-plan-1: Phase 16 dependency note cites P6 but neither diagram nor gantt shows it
- Severity: minor
- Location: IMPLEMENTATION_PLAN dependency diagram / gantt / timeline note
- Problem: the note says payroll (16) "depends on Phases 2/6/8", but the diagram has only `P2 → P16` and `P8 → P16` edges and the gantt has `p16 after p8`. The P6 dependency is transitive (P6 → P7 → P8), so nothing is wrong in effect — the inconsistency is cosmetic but will trip a future scheduler.
- Evidence: diagram and gantt vs timeline note.
- Fix: either add the `P6 --> P16` edge or reword the note to "Phases 2 and 8 (Phase 6 transitively via Phase 8)".
- Affects: IMPLEMENTATION_PLAN diagrams only.

All eight residual issues are small, none invalidates an ADR, and none blocks Phase 0. F-final-backend-1 and F-final-db-1 should be folded into the plan before the Phase 7 and Phase 0 backlogs respectively are scheduled; the rest can be fixed as editorial amendments at any time.
