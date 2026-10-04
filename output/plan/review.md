# Verifier review

## Summary

The council has a strong product scope and a useful first-pass domain model, but this pass is not safe to approve as implementation-ready. The central blocker is an unresolved security architecture contradiction: `data-model.md` and the frontend use live membership lookup/RLS, while `backend.md` and `supabase-edge-functions.md` require JWT tenant claims and service-role writes. The SQL migrations also do not implement the stated branch isolation, expose reporting views without `security_invoker`, and contain an incorrect/concurrency-unsafe booking design. Resolve these before the chair freezes decisions or implementation begins.

Evidence reviewed: `requirements.md`, `data-model.md`, `sql/*.sql`, `backend.md`, `frontend.md`, and all three skill drafts. Official references checked include Supabase RLS, Auth Hooks, Edge Function limits, and Queues documentation.

## Decision verdicts

| Decision | Owner | Verdict | Required ruling/change |
|---|---|---|---|
| PD-scope-1 online booking Phase 2 | requirements | AGREE | Keep Phase 2, but preserve a public-booking threat model and rate limits in the Phase 2 plan. |
| PD-scope-2 inventory Phase 3/manual item | requirements | AGREE WITH CHANGES | Add `manual_item` to the SQL `sale_items.item_type` check; it currently permits only service/product/package/gift_card. |
| PD-scope-3 packages/gift cards/memberships Phase 3 | requirements | AGREE | Keep the liability and recurring-billing sequencing. |
| PD-scope-4 staff+time conflicts MVP | requirements | AGREE WITH CHANGES | Do not create Phase 3 resource constraints in the MVP trigger. The current migration checks resources even though the scope says resources are deferred. |
| PD-scope-5 six MVP reports | requirements | AGREE WITH CHANGES | Define branch filtering and role-scoped views/RPCs before implementation; current views are not safely branch-scoped. |
| PD-scope-6 register MVP | requirements | AGREE WITH CHANGES | Add `register_sessions` (and cash movements/close reconciliation) to the schema and migration list; it is currently only a glossary/requirements concept. |
| PD-scope-7 fixed appointment statuses | requirements | AGREE WITH CHANGES | Normalize `started` vs `in_progress`; requirements/data-model/SQL use `started`, while glossary and user story use `in_progress`. |
| PD-scope-8 repeating series Phase 2 | requirements | AGREE | Leave out MVP series fields unless the chair explicitly wants a nullable reservation. |
| PD-scope-9 duplicate warning, merge Phase 2 | requirements | AGREE WITH CHANGES | Add the promised `merged_into` column (or formally remove that promise); it is absent from `clients` SQL. |
| PD-scope-10 full refunds/void MVP | requirements | AGREE WITH CHANGES | Ensure refund policy is branch/role constrained and add checks preventing refunds above captured amount. |
| PD-tenant-1 tenant-scoped clients | requirements | AGREE | Tenant-wide client visibility is consistent with the stated safety requirement, but financial aggregates must be branch-filtered. |
| PD-tenant-2 one staff record/cross-branch conflict | requirements | AGREE WITH CHANGES | Enforce assignment tenant/branch consistency with composite foreign keys or trigger; current FKs allow cross-tenant references. |
| PD-tenant-3 branch service override rows | requirements | AGREE WITH CHANGES | Rename/align `branch_services` with glossary terminology and enforce that branch/service/tenant all match. |
| PD-tenant-4 per-branch invoice sequence | requirements | AGREE WITH CHANGES | Use one authoritative branch sequence rule; requirements say per-branch while data-model text says sale numbers are unique per tenant and SQL unique index is `(tenant_id, sale_number)`. |
| PD-payments-1 MyFatoorah primary/Tap fallback | requirements | AGREE WITH CHANGES | Treat gateway fees, approval rates, and recurring-billing claims as vendor-confirmed integration assumptions, not settled facts. Keep provider abstraction and verify official gateway API/webhook documentation before Phase 2. |
| PD-i18n-1 EN/AR + RTL day one | requirements | AGREE WITH CHANGES | Add bilingual columns to schema where required (`name_en/name_ar` etc.); current SQL uses single `name` fields. |
| PD-money-1 integer minor units | requirements | DISAGREE WITH CURRENT SQL | The decision is sound, but `data-model.md`, SQL, views, glossary skill, and database skill all use `numeric(12,3)`. Choose one representation. Recommended: integer minor units plus currency exponent, with a deliberate decimal presentation boundary. |
| PD-billing-1 tenant subscription/no wallet | requirements | AGREE | Add a minimal entitlement/plan representation to the implementation plan; do not let billing be an undocumented hardcoded assumption. |
| PD-DB-1 live membership lookup, not JWT claims | data-model | AGREE WITH CHANGES | Prefer live DB-derived authorization for revocation and branch scope. Add explicit caching/performance tests and ensure all helpers filter `is_active`. Do not combine this with backend JWT-only authorization. |
| PD-DB-2 UUID keys | data-model | AGREE | UUIDs are appropriate; still validate composite tenant ownership on all FKs. |
| PD-DB-3 numeric money | data-model | DISAGREE | Conflicts directly with PD-money-1 and the glossary. The chair must select integer minor units or numeric, then update every document, migration, type, and skill consistently. |
| PD-DB-4 timestamptz + IANA zone | data-model | AGREE | Add explicit DST/date-local conversion tests and define how overnight shifts/opening hours are represented. |
| PD-DB-5 mixed soft delete/status | data-model | AGREE WITH CHANGES | Add `merged_into`, consistent inactive/deleted filters, and prevent hard deletion of referenced historical rows. |
| PD-DB-6 `_shared` Edge Function modules | data-model | AGREE WITH CHANGES | Shared source is acceptable, but document versioning/redeploy impact and prohibit shared mutable state. |
| PD-DB-7 direct CRUD plus Edge Functions | data-model | AGREE WITH CHANGES | Direct writes are only acceptable where database constraints/RLS fully express authorization. Appointment, checkout, role, settings, and all financial mutations must use controlled RPC/function paths. |
| PD-FE-1 pnpm monorepo | frontend | AGREE | Keep independent app/package build boundaries. |
| PD-FE-2 branch in URL, tenant in session | frontend | AGREE WITH CHANGES | Tenant may not be treated as a single-tenant session assumption; support multiple memberships using an active tenant context, and validate it server-side. |
| PD-FE-3 reads direct, invariant writes via Edge Functions | frontend | AGREE WITH CHANGES | Align with PD-DB-7 and explicitly prohibit direct writes to role, financial, booking, and cross-table tables. |
| PD-FE-4 TanStack Query branch-scoped keys/realtime cache | frontend | AGREE WITH CHANGES | Query keys must include tenant and branch scope; Realtime channel authorization must be tested for cross-tenant and cross-branch leakage. |
| PD-FE-5 RHF+Zod shared schemas | frontend | AGREE WITH CHANGES | Make schemas Deno-compatible and ensure server-side authorization is not delegated to Zod. |
| PD-FE-6 Lingui/logical CSS/Intl | AGREE | frontend | Keep; add schema and search normalization requirements for Arabic names. |
| PD-FE-7 schedule-x premium resources | AGREE WITH CHANGES | frontend | Make premium licensing a go/no-go dependency and ensure the fallback still meets the MVP accessibility/performance acceptance criteria. |
| PD-FE-8 TanStack Router typed search params | AGREE | frontend | Keep; route guards remain UX-only as documented. |
| PD-BACKEND-1 bounded-context functions | AGREE WITH CHANGES | backend | Good isolation boundary, but remove the `auth-hook` as an Edge Function unless the selected Auth Hook mechanism supports it; Supabase Auth Hooks are configured as supported Postgres functions or supported HTTP endpoints, not an arbitrary internal function convention. |
| PD-BACKEND-2 hybrid direct CRUD/Edge transactions | AGREE WITH CHANGES | backend | Same caveat as PD-FE-3: direct writes need a table-by-table allowlist and role policies, not merely “single-table”. |
| PD-BACKEND-3 JWT tenant claims | DISAGREE | backend | Contradicts PD-DB-1 and the requirement for immediate membership revocation. Use JWT only for user identity, or treat claims as a non-authoritative cache and re-check membership/branch/role in DB for every privileged operation. |
| PD-BACKEND-4 MyFatoorah later phase | AGREE WITH CHANGES | backend | Keep provider-neutral interfaces; re-verify gateway claims from official provider docs during Phase 2 discovery. |
| PD-BACKEND-5 exclusion constraints for double booking | DISAGREE WITH CURRENT IMPLEMENTATION | backend | The migration does not implement the proposed constraint and instead uses a non-serialized trigger. A trigger `SELECT count(*)` is race-prone under concurrent inserts. Use a denormalized staff-time range table with a real exclusion constraint, or a carefully locked transactional conflict procedure with concurrency tests. |
| PD-BACKEND-6 pg_cron + pgmq | AGREE WITH CHANGES | backend | Supabase documents pgmq visibility timeouts and retry behavior, but exactly-once is bounded by the visibility window and requires idempotent consumers. Add duplicate-delivery handling and queue schema/migrations. |

## Conflicts between areas and ruling

1. Tenant context: data-model PD-DB-1 says no tenant/branch claims and live membership lookup; backend PD-BACKEND-3 says all authorization comes from JWT claims; frontend says the Edge Function re-derives context from DB. Ruling: use `auth.uid()` plus live, SECURITY DEFINER membership/branch/role checks as the authorization source of truth. JWT claims may optimize display/context only and must never authorize service-role writes.

2. Money: requirements PD-money-1 and `spa-domain-glossary` require integer minor units; data-model, SQL, and `supabase-database` require numeric(12,3). Ruling: chair must choose one before migrations are accepted. Recommended integer minor units, because it is the explicit product decision and keeps frontend/backend arithmetic consistent.

3. Appointment status: SQL/data-model use `started`; requirements user story and glossary use `in_progress`. Ruling: use one enum, preferably `in_progress`, and update all checks, queries, translations, and diagrams.

4. Service/sale vocabulary: requirements says `manual_item`; SQL rejects it. Glossary says `service | manual_item` for MVP but SQL says `service | product | package | gift_card`. Ruling: SQL must include `manual_item`; future item types can be enabled by later migrations.

5. Function API/error contract: frontend handoff describes `{ok, error:{code,message,fieldErrors}}` and codes such as `NETWORK`/`UNAUTHENTICATED`; backend describes `{error:{code,message,details}}` and different codes. Ruling: define one versioned envelope and one code catalogue in `packages/validation`/`packages/api` before coding.

6. Edge Function naming: frontend uses `booking-create`, `booking-reschedule`, and `checkout`; backend proposes bounded-context functions `bookings` and `checkout` with internal routes. Ruling: select one public invocation shape and document it in the conventions skill.

7. Scope of staff records: requirements allows staff who may not have login accounts; data-model SQL makes `staff.user_id` mandatory. Ruling: make `user_id` nullable for non-login staff or explicitly change onboarding requirements.

8. Client privacy: requirements says client profiles are tenant-wide but financial aggregates branch-scoped; SQL client/profile and report policies are tenant-wide. Ruling: expose branch-filtered financial aggregates through secured RPCs/views, not the unrestricted client row.

## Security and tenancy findings

- CRITICAL: Most SQL policies are tenant-only, not branch-scoped. `appointments`, `sales`, `payments`, `refunds`, `staff_time_off`, `staff_working_hours`, `resources`, and related tables can be selected/inserted/updated by any member of the tenant regardless of their `branch_id` scope. This violates the explicit branch-manager/receptionist isolation invariant.
- CRITICAL: `profiles_select USING (true)` exposes every profile to every authenticated user across tenants. Replace it with self-only or a narrowly scoped tenant relationship policy, and avoid exposing unnecessary personal fields.
- CRITICAL: `tenants_insert WITH CHECK (true)` permits any authenticated user to insert arbitrary tenant rows through the data API. Remove the direct insert policy and make onboarding a locked-down platform operation or a narrowly authorized RPC.
- HIGH: `has_tenant_role` checks role but not branch scope. A branch manager can satisfy the role check for a row in another branch. Role helpers must accept/validate branch context and all branch-scoped policies must compare the row branch with allowed memberships.
- HIGH: Denormalized `tenant_id` columns are not constrained to match parent tenant IDs. For example, a `branch_services` row can pair Tenant A's `tenant_id` with Tenant B's branch/service IDs if an authorized write path or service-role bug supplies that combination. Add composite unique keys and composite foreign keys, or database validation triggers.
- HIGH: Report views are granted to `authenticated` and comments claim underlying RLS applies, but views normally bypass underlying-table RLS by default. Supabase explicitly documents `WITH (security_invoker = true)` for safe view behavior on Postgres 15+. Add it, or revoke direct view access and expose secured RPCs.
- HIGH: Service-role writes are described as “include tenant_id in WHERE clauses”, but this is a convention, not a database boundary. Privileged functions must derive and verify tenant/branch/role from live membership and use transaction-scoped checks.
- MEDIUM: Realtime is not covered by the RLS test plan. Test channel subscriptions and payloads for tenant and branch isolation; do not rely only on UI query keys.
- MEDIUM: Storage paths and policies are absent despite the requirements mentioning exports/avatars in architecture. Define tenant/branch path prefixes and Storage RLS before adding uploads.
- MEDIUM: Audit log has an insert policy for authenticated clients and no database-enforced append-only mechanism. Prefer a trigger/security-definer writer, revoke direct insert/update/delete from tenant roles, and capture branch_id as required by NFR-3.
- MEDIUM: `settings` uses nullable `branch_id` in a unique constraint; PostgreSQL permits multiple NULL keys, so tenant-wide settings can duplicate. Use a sentinel, expression unique index, or separate tenant/branch settings tables.

## Booking and time findings

- CRITICAL: `check_staff_double_booking()` performs an ordinary `SELECT count(*)` before insert. Two concurrent transactions can both observe zero conflicts and commit. It does not satisfy NFR-4. Use an actual exclusion constraint over a row carrying `staff_id` and the effective time range, or serialize on a stable staff lock in a transactional procedure and test concurrent requests.
- HIGH: The trigger fires on `appointment_items`, but changing `appointments.scheduled_start` or `scheduled_end` does not fire it. A reschedule can therefore create an overlap without any conflict check unless all updates are forbidden outside a controlled RPC.
- HIGH: The trigger uses the parent appointment's entire range for each item. It cannot represent sequential multi-service items with different staff/time spans as required by US-CAL-8. Model item ranges or explicitly defer multi-staff/sequential visits.
- HIGH: The stated buffers are not present in the SQL `services` table or appointment items. The trigger checks appointment range only, so buffer enforcement is not implemented.
- MEDIUM: `staff_time_off` is not branch-scoped in the schema, despite branch-specific schedules and the branch isolation requirement. If time off is tenant-wide by design, document that explicitly; otherwise add branch_id.
- MEDIUM: `branch_hours` stores one `opens_at` and `closes_at` pair and does not specify overnight or split intervals. Define the representation and local-date/DST behavior before availability implementation.
- MEDIUM: Appointment and sale financial snapshots are incomplete. Appointment items lack per-item buffer/time range and bilingual service-name snapshot; sale totals can be written independently of line sums. Checkout RPC must be authoritative and enforce reconciliation checks.

## SQL review

- Migration dependency order is broadly sensible, and indexes exist for many tenant/branch columns.
- The SQL is not a complete implementation of the prose model: no `register_sessions`, no idempotency table despite the backend skill requiring it, no blocked-time types/booking overrides, no merged client pointer, no tax tables, and no explicit branch-scoped permission tables.
- `profiles`, settings, views, and several tables do not have the required consistent audit/update fields described in the data model.
- `services`, categories, cancellation reasons, and other operator-facing names are single-language `name` fields, conflicting with EN/AR from day one.
- `sale_items.item_type` omits `manual_item`, making the advertised MVP quick-sale path impossible.
- `payments.payment_method` only permits `cash` and `other`, while requirements explicitly name manual KNET, bank transfer, and configurable methods. Either use a configurable method table or include the agreed stable enum values.
- `payments` permits `payment_type = refund` while a separate `refunds` table exists. Define one canonical accounting model; do not allow both representations without reconciliation rules.
- `refunds` has no constraint tying its `payment_id`/`sale_id`/tenant/branch to the same parent records and no amount ceiling.
- The data-model example exclusion constraint is invalid as written because PostgreSQL exclusion expressions cannot contain the shown cross-table subqueries. The document notices this, but the backend decision still claims the constraint exists. Replace the example with executable SQL or remove it.
- `appointment_items` lacks `created_at`/`updated_at`, contrary to the stated table convention, and its staff/resource indexes do not include the effective time range needed for conflict queries.
- RLS policy coverage is inconsistent: many tables have no update/delete policy (which is fail-closed but may silently break required operations), while broad insert/update policies allow ordinary authenticated users to perform mutations outside the role matrix.
- Report view date grouping uses database/session date semantics; reports must convert timestamps to each branch's IANA timezone before grouping.

## Skill review

- `supabase-database` is clear and prescriptive, but it codifies numeric money and a trigger-based booking approach that conflict with the requirements and backend decisions. It also says every branch-scoped table gets branch RLS, while the actual policy migration does not implement that rule.
- `supabase-edge-functions` is useful operationally, but its “always JWT claims” rule is unsafe under the selected live-membership design. Its examples use numeric IDs while the schema uses UUIDs, and it refers to `idempotency_keys` that is not in the schema.
- `spa-domain-glossary` is valuable but currently conflicts with the schema: it names `staff_members`, `service_branch_overrides`, `blocked_times`, `register_sessions`, integer money, `manual_item`, and `in_progress`, while SQL uses `staff`, `branch_services`, no blocked-times table, no register table, numeric money, no manual item, and `started`. The chair must reconcile vocabulary before finalizing skills.
- All skills need a concrete “how to add X” path for branch-scoped tables, RLS tests, an Edge Function, and a report view/RPC that includes tenant and branch authorization. The database skill has a useful table checklist, but it must include composite parent-tenant checks and secure-view rules.

## Scope review

MVP coverage is directionally good for SpaCorner's daily operation: branches, staff, shifts, services, clients, calendar, manual checkout, sales, reports, EN/AR, audit, and export are all identified. Essential gaps before implementation are register sessions, blocked-time data, import/idempotency infrastructure, branch-scoped authorization, receipt configuration, and a fully specified audit writer. The plan also promises multi-service visits, manual items, refunds, roles, and branch switching that the migrations cannot currently execute safely.

Features correctly deferred include public online booking, online payments, reminders, marketing, inventory, packages/gift cards/memberships, resources, payroll, and marketplace/channel integrations. Keep those deferrals, but do not place Phase 3 tables or resource conflict behavior in the MVP migration unless they are explicitly inert and tested.

## Official-source checks

- Supabase Edge Function limits support the cited 256 MB memory, 150s free/400s paid wall-clock, 2s CPU/request, 150s idle timeout, and 100/1000/2000 function limits: https://supabase.com/docs/guides/functions/limits
- Supabase Auth Hooks documentation describes the Custom Access Token Hook and supported configuration/security model; it is not evidence that an arbitrary `auth-hook` Edge Function can replace a Postgres Auth Hook: https://supabase.com/docs/guides/auth/auth-hooks and https://supabase.com/docs/guides/auth/auth-hooks/custom-access-token-hook
- Supabase explicitly warns that views bypass RLS by default and recommends `security_invoker = true` on Postgres 15+: https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase Queues documents visibility timeout and retry behavior. “Exactly once” is bounded by the visibility window, so consumers still need idempotency: https://supabase.com/docs/guides/queues/pgmq and https://supabase.com/docs/guides/queues/consuming-messages-with-edge-functions
- Supabase's current Edge Function examples support `withSupabase`, but the implementation should pin the documented package/version and verify the wrapper API in CI rather than treating the draft snippet as a tested contract: https://supabase.com/docs/guides/getting-started/ai-prompts/edge-functions

## Open questions for the owner

1. Should money be integer minor units (the explicit product decision) or `numeric(12,3)`? This affects every migration, type, report, and skill.
2. Is one authenticated user allowed memberships in multiple tenants? If yes, what is the active-tenant switch and how is it refreshed without trusting client headers?
3. Are non-login staff supported? If yes, make `staff.user_id` nullable and define how they appear in reports.
4. Is a receptionist allowed to see tenant-wide client contact/history, or only client records needed for their assigned branches? The requirements currently mix tenant-wide clients with branch-scoped privacy.
5. Must MVP support multi-service visits with different staff and sequential spans, or can that story move to Phase 2?
6. Which payment methods are first-class manual methods in Kuwait (cash, card terminal, KNET terminal, bank transfer, other), and are refunds represented in `payments`, `refunds`, or both?
7. Is a platform admin allowed to create tenants directly, and through which non-public onboarding path?
8. Which Auth Hook mechanism will be used (Postgres function or supported HTTP hook), and what is the fallback if JWT claims are intentionally non-authoritative?
9. Which schedule-x premium license/fallback is approved for the MVP calendar?
10. Are exports and avatars required in MVP? If yes, define Storage bucket/path/RLS rules before implementation.

## Confidence by section

- Product scope and phase placement: 0.88 (strong requirements coverage; a few schema omissions).
- Multi-tenant and branch authorization: 0.35 (major policy and architecture contradictions; not implementation-safe).
- Data model and SQL migrations: 0.48 (good table inventory/index intent, but incomplete constraints, missing MVP tables, money/status conflicts, and unsafe views/RLS).
- Booking integrity and time zones: 0.42 (time-zone direction is sound; concurrency, buffers, rescheduling, and multi-item ranges are unresolved).
- Backend Edge Function architecture: 0.55 (bounded-context isolation and async direction are reasonable; JWT/auth-hook and runtime/API examples conflict with other areas).
- Frontend architecture and i18n/RTL: 0.76 (coherent and testable; dependent on backend contract, money choice, and calendar licensing).
- Skills/conventions: 0.58 (good structure and practical commands; terminology and security rules are inconsistent).
- Overall implementation readiness: 0.46 (conditional only; resolve the critical security, money, and booking issues first).
