# Review round 2: data model, SQL, security and Edge Functions audit

Auditor: cartographer. Scope per `review2/briefs/data-backend.md`: `data-model.md`, `sql/*.sql` (000001–000013), `backend.md`, database/backend parts of `CONVENTIONS.md`, and the `supabase-database`, `supabase-edge-functions`, `spa-platform-architecture` skills (`.claude` copies; `.cursor` copies were diff-identical per the chair's handoff metadata). `decisions.md` and `IMPLEMENTATION_PLAN.md` were read as the binding context so that already-ruled draft defects are not re-litigated; this audit targets what the rulings missed, where the rulings themselves are wrong or unbuildable, and where the post-ADR artifacts (CONVENTIONS, IMPLEMENTATION_PLAN, skills) are inconsistent.

External claims verified during this audit (web, 2026-10-04):

- Supabase Edge Functions limits (256MB memory, 150s free / 400s paid wall clock, 2s CPU/request, 150s idle, 20MB local / 5MB server bundle, 100/1000/2000 functions, 10k log chars, 100 events/10s, 100 secrets × 48KiB): https://supabase.com/docs/guides/functions/limits — backend.md §1.4 and ADR-27's numbers are **correct as written**.
- Views bypass underlying-table RLS by default; `WITH (security_invoker = true)` is required (Postgres 15+): https://supabase.com/docs/guides/database/postgres/row-level-security — ADR-21 is correct; the draft views/`000013` comment claiming inherited RLS is wrong (already ruled).
- `supabase test db` is the pgTAP command (backend.md's `supabase db test` does not exist): https://supabase.com/docs/reference/cli/supabase-test-db
- Supabase per-function `config.toml` options are `verify_jwt`, `import_map`, `entrypoint`, `static_files` — there is no `[functions.<name>.rate_limit]` key: https://supabase.com/docs/guides/cli/config
- pg_cron on Supabase is installed with `create extension pg_cron with schema pg_catalog;` plus grants, per the official install doc: https://supabase.com/docs/guides/cron/install
- KNET recurring-billing capability: no primary source found confirming or denying; see F-DB-12.

## Attack paths exercised (brief §1) and their disposition

This was a document audit (no live staging DB exists for the plan), so each attack path below is a static trace through the draft policies in `sql/000013_enable_rls.sql` and the target policies mandated by ADR-20. Result for each: whether the draft is exploitable, and whether a ruling already closes it.

| # | Attack path | Draft SQL result | Closed by |
|---|---|---|---|
| A1 | Authenticated user of tenant A selects report views granted in `000013` → views run as owner (postgres, bypasses RLS) → all tenants' sales/payments/appointments readable | Exploitable (blocker in draft) | ADR-21 (`security_invoker` + CI check) — ruled; SQL drafts still wrong, superseded by Phase 7 rewrite |
| A2 | Any authenticated user selects `profiles` (`USING (true)`) → cross-tenant PII (names, phones) | Exploitable | ADR-20 rule 2 — ruled |
| A3 | Any authenticated user inserts into `tenants` (`WITH CHECK (true)`) → tenant spam/orphans | Exploitable | ADR-20 rule 3 — ruled |
| A4 | Branch-scoped receptionist/manager selects another branch's `appointments`/`sales`/`payments`/`shifts` (policies are tenant-only) | Exploitable | ADR-20 rule 1 — ruled |
| A5 | Member of tenant A inserts an `appointments`/`sales` row with `tenant_id = A` but `branch_id`/`client_id`/`service_id`/`staff_id` pointing at tenant B rows (FK passes; `WITH CHECK` only tests `tenant_id`; UUIDs are guessable) | Exploitable in draft; **partially closed by ADR-20 rule 5** — see F-DB-3 for the enumeration gap | ADR-20 rule 5 (needs F-DB-3 fix) |
| A6 | Branch manager inserts a `memberships` row with `role = 'tenant_owner'` (or `platform_admin`) for themselves (`memberships_insert` checks only the inserter's role) | Exploitable in draft (privilege escalation) | ADR-28 removes direct membership writes, but the function contract is unspecified — F-DB-4 |
| A7 | Member inserts `audit_log` rows forging `actor_id` (insert policy checks tenant only) | Exploitable in draft | ADR-22 — ruled |
| A8 | Staff member self-inserts/updates `staff_time_off` (policy = tenant membership only) | Exploitable in draft | Superseded by `blocked_times` design (ADR-26) + allowlist (F-DB-6 caveats) |
| A9 | Edge Function with service-role client: "include tenant_id in WHERE" is convention only | Acknowledged | ADR-20 rule 7 — ruled |
| A10 | Realtime channel subscription leaks cross-tenant/branch payloads | Untested in draft | ADR-38 binding correction — ruled |
| A11 | Client-side `sales` insert with tampered `subtotal/gross_total` (`sales_insert` = tenant membership only) | Exploitable in draft | ADR-28 (sales RPC-only) + checkout RPC reconciliation — ruled |
| A12 | Concurrent booking of same staff slot via `check_staff_double_booking()` trigger (SELECT count(*) race) | Exploitable (double booking) | ADR-24 (exclusion constraint + advisory lock) — ruled |
| A13 | Reschedule updates `appointments.scheduled_start/end` directly — trigger on `appointment_items` never fires | Exploitable in draft | ADR-24 (RPC-only reschedule) — ruled |

Conclusion: every draft-SQL hole I could construct maps to an existing binding ADR. The findings below are the residue the rulings missed.

---

### F-DB-1: The sentinel branch UUID (ADR-20 rule 6) is incompatible with the composite foreign keys (ADR-20 rule 5) — the two rules cannot both be built
- Severity: blocker
- Location: `decisions.md` ADR-20 rules 5+6; `ADR-26` (blocked_times all-branches sentinel); `CONVENTIONS.md` §3.2 (Branch key), §5; `supabase-database` skill ("Branch-scoped tables add `branch_id uuid NOT NULL REFERENCES branches(id)`; the all-branches/tenant-wide sentinel is `00000000-…`"); `spa-platform-architecture` skill (Tenancy model); `IMPLEMENTATION_PLAN.md` Phase 0 backlog ("memberships (sentinel branch, composite uniques)"), Phase 2 Epic 2.3 ("sentinel branch for all-branches time off").
- Problem: rule 5 mandates composite FKs — children reference `(branch_id, tenant_id)` against `branches(id, tenant_id)`; rule 6 mandates that "all branches" is stored as the sentinel UUID `00000000-0000-0000-0000-000000000000` in `memberships.branch_id`, `settings.branch_id`, and (per ADR-26) `blocked_times.branch_id`. Postgres FKs have no partial exception: a row with `branch_id = sentinel` violates any FK to `branches`, because no `branches` row carries the sentinel id. So either the FK is dropped on exactly the columns where tenant consistency matters most (settings, memberships, all-branches time off), or the sentinel cannot be inserted and the "all branches" case is unrepresentable. The rule-6 rationale (NULLs are distinct so `UNIQUE (tenant_id, branch_id, key)` permits duplicate tenant-wide settings) is real, but the sentinel fix collides with rule 5.
- Evidence: draft `sql/000004` (`memberships.branch_id … ON DELETE SET NULL`), ADR-20 rule 6 text, ADR-26 bullet 3 ("recorded once with `branch_id` set to the sentinel all-branches value"); Postgres FK semantics (no MATCH PARTIAL).
- Fix: replace the sentinel with a nullable `branch_id` plus an explicit `all_branches boolean NOT NULL DEFAULT false` column on `memberships`, `settings`, `blocked_times` (and any future table needing the "all branches" value):
  - `branch_id uuid NULL REFERENCES branches(id)` (composite `(branch_id, tenant_id)` where rule 5 applies); `CHECK (all_branches = (branch_id IS NULL))` keeps the two representations mutually exclusive.
  - The duplicate-tenant-wide-settings problem is solved with a partial unique index instead of the sentinel: `CREATE UNIQUE INDEX settings_tenant_wide_key ON settings(tenant_id, key) WHERE branch_id IS NULL;` (one tenant-wide row per key), next to the existing `UNIQUE (tenant_id, branch_id, key)` which then only governs branch rows.
  - Policies: `all_branches OR branch_id IN (SELECT current_branch_scope(tenant_id))`; helpers `current_branch_scope()`/`has_tenant_role()` test `all_branches` instead of the sentinel literal.
  - Update in one pass: ADR-20 rules 6 (rewritten), ADR-26 bullet 3, ADR-12/13 wherever the sentinel is cited, CONVENTIONS §3.2/§5, both skills' sentinel references, IMPLEMENTATION_PLAN Phase 0/2 backlog wording.
- Affects: ADR-20, ADR-26, ADR-12, CONVENTIONS §3.2/§5, `supabase-database` + `spa-platform-architecture` skills, IMPLEMENTATION_PLAN Phase 0 Epic 0.2 and Phase 2 Epic 2.3, and every RLS policy template that compares against the sentinel literal.

### F-DB-2: `has_tenant_role(p_tenant_id, p_roles, p_branch_id DEFAULT NULL)` is a security footgun — a forgotten third argument silently degrades branch scoping to tenant-wide
- Severity: major
- Location: ADR-20 rule 4; `supabase-database` skill "Authorization helpers" code block.
- Problem: with `p_branch_id DEFAULT NULL`, `p_branch_id IS NULL` short-circuits the branch test, so `has_tenant_role(t, 'branch_manager')` returns true for a manager of *any* branch. A policy author who intends branch-scoped writes but omits the row's branch (exactly the mistake ADR-20 rule 4 exists to prevent) ships a policy where a branch-A manager passes the role check on branch-B rows. The SELECT policy may still hide branch-B rows, but UPDATE/DELETE policies written per-table are where this bites, and any hand-written policy on a table without the branch-scoped SELECT template leaks fully.
- Evidence: skill code: `AND (p_branch_id IS NULL OR m.branch_id = '…' OR m.branch_id = p_branch_id)`.
- Fix: remove the default — `has_tenant_role(p_tenant_id uuid, p_roles text[], p_branch_id uuid)` (no DEFAULT); every call site passes the row's branch explicitly; for genuinely tenant-wide checks define a separate `has_tenant_role_any_branch(p_tenant_id, p_roles)`. Update the skill's helper block, ADR-20 rule 4 text ("helpers take the branch scope explicitly; there is no default"), and add a pgTAP row: manager-of-A fails `has_tenant_role(t, '{branch_manager}', branch_b)`.
- Affects: ADR-20, `supabase-database` skill, Phase 0 helper migration (Epic 0.2), all role-gated write policies in Phases 1–6.

### F-DB-3: ADR-20 rule 5 (composite tenant-consistency FKs) does not cover references that are not "denormalized tenant_id columns" — cross-tenant writes via `client_id`, `appointment_id`, `sale_id`, `payment_id`, `staff_id`, `register_session_id` remain open
- Severity: major
- Location: ADR-20 rule 5 (wording "Composite foreign keys enforce tenant consistency of denormalized columns"); `supabase-database` skill "Composite tenant consistency" (example covers only `branch_id`/`service_id`); draft `sql/000009/000010` FKs (single-column).
- Problem: rule 5 as worded binds the pairs where a child row carries both `tenant_id` and a parent id *of the same tenant dimension* (branch, service, staff). But the same attack works through every other FK: a member of tenant A inserts an appointment with `client_id` of tenant B (draft `appointments.client_id` is a plain FK to `clients(id)`; RLS on clients blocks the SELECT but not the INSERT reference), a `sale_items.appointment_id` pointing at tenant B's appointment, a `payments.sale_id`/`refunds_payment_id` pointing at another tenant's sale/payment, `tips.staff_id` at another tenant's staff member. UUIDs are guessable only with difficulty, but this is exactly the "can a user of tenant A write tenant B rows through any path" question the brief asks, and guessing is unnecessary once any ID leaks through a report, export, or error message.
- Evidence: draft `sql/000009` lines 10/48/49 (plain FKs `client_id`, `staff_id`, `resource_id`), `sql/000010` lines 60/70/86/111 (plain FKs `sale_id`, `appointment_id`, `payment_id`); `WITH CHECK` clauses in `000013` test only `tenant_id`.
- Fix: extend rule 5 to: "every foreign key to another tenant-owned table is composite on `(id, tenant_id)`" and enumerate the pairs in the ADR and the skill: `appointments(client_id, tenant_id) → clients`, `appointment_items(service_id|staff_id, tenant_id) → services|staff_members`, `sales(client_id, tenant_id) → clients`, `sale_items(sale_id|appointment_id|staff_id, tenant_id)`, `payments(sale_id|register_session_id|client_id, tenant_id)`, `payments(refunds_payment_id, tenant_id) → payments`, `tips(staff_id|sale_id, tenant_id)`, `register_sessions(branch_id, tenant_id)`, `blocked_times(staff_id, tenant_id)`, `shifts(staff_id, tenant_id)`. Parents expose `UNIQUE (id, tenant_id)` (already in ADR-44). Add the attack-path pgTAP test to the Phase 0 harness (insert referencing tenant B's client must fail with FK violation).
- Affects: ADR-20 rule 5, ADR-44, `supabase-database` skill, Phase 0 pgTAP harness, Phase 5/6 migrations.

### F-DB-4: Role-grant rules are unspecified, and `platform_admin` survives in the memberships role enum against CONVENTIONS §5
- Severity: major
- Location: draft `sql/000004` (role CHECK includes `platform_admin`; `memberships_insert` lets a branch_manager insert any role); `CONVENTIONS.md` §5 ("Platform admin is an ops path, never a standing data role"); `decisions.md` ADR-19/20 (no rule on who may grant which role); `IMPLEMENTATION_PLAN.md` Phase 1 Epic 1.3.
- Problem: (a) CONVENTIONS says platform admin is never a data role, but nothing removes `platform_admin` from the memberships enum — Phase 0 will rewrite this migration and can inherit it; (b) ADR-28 correctly forces all membership writes through an Edge Function, but no ADR, phase, or skill states the grant rules that function must enforce: requirements §3 says "Assign roles — tenant owner only", and nothing prevents a compromised owner session from minting `platform_admin` rows if the value exists in the enum, or defines whether an owner may grant roles on branches they don't scope (trivially yes for owner, but managers must not grant manager+). The round-1 escalation path (A6) is only half-closed.
- Fix: (1) memberships role CHECK becomes `('tenant_owner','branch_manager','receptionist','staff')` — `platform_admin` is deleted from the enum; platform ops go through the audited impersonation path (ADR-20 rule 3, NFR-1). (2) Add ADR-20 rule 9: membership/role mutations only via the `onboarding`/`staff` functions, which enforce: caller is `tenant_owner` (or platform-admin service path); the granted role is not above the caller's own tenant role (managers may only add receptionist/staff scoped to their own branch); `tenant_owner` grants are owner-only; every change writes an audit row. (3) Phase 1 Epic 1.3 backlog gains a line for these checks + pgTAP rows (manager cannot grant owner/manager; nobody can set `platform_admin`).
- Affects: ADR-20 (new rule 9), draft `000004` (superseded rewrite), CONVENTIONS §5, Phase 1 Epic 1.3, `spa-platform-architecture` skill roles list (already correct — verify after enum change).

### F-DB-5: Two role-matrix rows are unimplementable as specified: staff "own lines only" sales visibility, and staff "B" client writes
- Severity: major
- Location: `requirements.md` §3 (rows "Sales/invoices view — Staff: S own lines only", "Clients (create/edit/…) — Staff: B"); `ADR-20` policy templates (branch scope only); `ADR-28` allowlist; `IMPLEMENTATION_PLAN.md` Phase 6 (no staff-visibility policy or pgTAP row), Phase 4.
- Problem: `sales` has no `staff_id` (attribution lives on `sale_items`/`tips`), so the branch-scoped SELECT policy mandated by ADR-20 gives a staff login visibility of *all* sales at their branch — the matrix demands their own lines only. No ADR, phase scope, pgTAP row, or skill pattern expresses the restriction; Phase 6's "branch-scoped RLS select-only" would ship the over-broad policy. Similarly, "Clients — Staff: B" is meaningless for a tenant-scoped table (clients carry no branch), so the direct-write allowlist (`clients` non-financial) plus tenant-level RLS lets any staff member edit any client's contact fields tenant-wide, contradicting requirements §2.4 ("their clients' basic profiles").
- Fix: (1) Staff sales visibility: staff role reads sales via a `report_own_sales` SECURITY DEFINER RPC (or a `security_invoker` view over `sales JOIN sale_items si ON si.sale_id = sales.id AND si.staff_id IN (caller's staff_members)`) — the sales table's SELECT policy excludes plain `staff` role; add the pgTAP row to Phase 6. (2) Staff client access: define it in requirements §3 as "read basic profile fields of clients with appointments at their assigned branches (via column-restricted view), no direct writes" — remove `clients` from what staff may write; receptionist/manager keep tenant-wide create/edit. Both fixes need one clarifying line each in the matrix and corresponding policy/pgTAP rows in Phases 4/6.
- Affects: requirements §3 (two cells), ADR-20 (policy note), ADR-28, IMPLEMENTATION_PLAN Phase 4 Database work + Phase 6 pgTAP, `supabase-database` skill.

### F-DB-6: `blocked_times` on the ADR-28 direct-write allowlist contradicts ADR-24's cross-entity serialization
- Severity: major
- Location: ADR-28 ("Direct single-table writes … `blocked_times` (own-branch, constraint-protected)"); CONVENTIONS §6 allowlist table; `spa-platform-architecture` skill allowlist; IMPLEMENTATION_PLAN Phase 2 scope ("blocked_times per allowlist direct-write (own branch, constraint-protected)").
- Problem: the exclusion constraint on `blocked_times(staff_id, blocked_range)` only prevents block-vs-block overlaps. A block overlapping an existing *appointment* for the same staff member is a cross-entity conflict that ADR-24 layer 2 explicitly says must be checked inside a transaction that first takes the per-staff advisory lock. A direct supabase-js insert (allowed by the allowlist) takes no advisory lock and runs no cross-entity check — a receptionist can silently block over a booked slot (or the same race two users creating a block + booking concurrently). "Constraint-protected" is only true for the single-entity case.
- Fix: remove `blocked_times` from the direct-write allowlist; all blocked-time writes go through the `staff` function calling the same locked RPC pattern as bookings (`pg_advisory_xact_lock(hashtextextended(staff_id::text,0))` → check appointments + blocks → insert). Update ADR-28's list, CONVENTIONS §6, both skills' allowlist tables, and Phase 2 scope/backlog ("blocked-time editor calls staff/blocked-time RPC").
- Affects: ADR-28, CONVENTIONS §6, `spa-platform-architecture` skill, IMPLEMENTATION_PLAN Phase 2.

### F-DB-7: Appointment `ref_number` has no uniqueness constraint, no generation scheme, and no ADR — yet Phase 5 ships it and global search depends on it
- Severity: major
- Location: draft `sql/000009` (`ref_number text NOT NULL`, no unique index); `data-model.md` §8 "generated by the application layer using `invoice_sequences`" (a sales-only mechanism, superseded); `IMPLEMENTATION_PLAN.md` Phase 5 (`appointments (envelope, ref_number …)`, acceptance "Global search finds … an appointment by ref"); no ADR covers appointment numbering (ADR-14 is sales only).
- Problem: `ref_number` is NOT NULL but nothing generates it or keeps it unique — duplicates are insertable, which breaks the search-by-ref acceptance criterion and any future client-facing reference. The draft's `idx_appointments_*` set has no unique index on it.
- Fix: rule it in ADR-14's terms: `appointments.branch_id` + per-branch counter reuse is overkill for appointments; simplest buildable rule — `ref_number` is generated by the booking RPC as `<branch prefix>-A<seq>` from the same `invoice_counters` row pattern (separate `kind` column or a second counter table), with `UNIQUE (branch_id, ref_number)`; or drop `ref_number` from MVP and let search use the UUID. Either way, add the decision to ADR-14 (or a new ADR-47) and the constraint to Phase 5's migration backlog so the rewrite doesn't inherit the naked column.
- Affects: ADR-14 (extend), IMPLEMENTATION_PLAN Phase 5 (migration + RPC backlog), draft `000009` (superseded rewrite).

### F-DB-8: Report-view SQL defects the Phase 7 rewrite would inherit: `report_top_services` references a non-existent column; `report_client_summary` inflates counts through a 1:N join
- Severity: major
- Location: draft `sql/000012_create_views.sql` lines 115–140; `data-model.md` §7.1 (same design, plus the false claim "All views include `tenant_id` in their SELECT so RLS applies"); `IMPLEMENTATION_PLAN.md` Phase 7 (views "rewritten for `_minor` and branch scope" — the rewrite re-derives from the same data-model patterns).
- Problem: (a) `report_top_services` selects and groups by `si.service_id`, but `sale_items` has `item_id` + `item_type` (no `service_id`) — `CREATE VIEW report_top_services` fails on a fresh project with "column si.service_id does not exist", which also aborts migration `000012` midway and the subsequent `000013` GRANTs; (b) `report_client_summary` does `count(*) FILTER (…)` over `clients LEFT JOIN sales` — a client with 5 sales counts 5× in `total_clients`/`new_this_month`; the metrics are wrong for any client with more than one sale; (c) the data-model §7.1 sentence claiming tenant_id in the SELECT list makes RLS apply is false (see verified Supabase doc above) — already ruled by ADR-21 but the sentence should not survive as the pattern Phase 7 copies.
- Fix: (a) join on `sale_items.item_id = services.id AND sale_items.item_type = 'service'`; (b) aggregate sales per client in a subquery before joining, or `count(DISTINCT c.id) FILTER (WHERE c.is_deleted = false)` / `count(*) FILTER` moved to a pre-aggregated CTE; (c) delete the §7.1 sentence and point at ADR-21. Fold (a)/(b) into the Phase 7 "report data" backlog line so the rewrite carries correct SQL, and add fixture reconciliation tests that would have caught both (multi-sale client; top-services on a service sold via a sale item).
- Affects: `sql/000012` (superseded rewrite), `data-model.md` §7.1, IMPLEMENTATION_PLAN Phase 7 Epic 7.1.

### F-DB-9: "One `staff_members` row per person per tenant" (ADR-12) has no enforcing constraint
- Severity: minor
- Location: ADR-12 decision text; draft `sql/000005` (`staff.user_id` plain FK, no unique); `supabase-database` skill; IMPLEMENTATION_PLAN Phase 2 Database work.
- Problem: ADR-12's core invariant (single identity per tenant; cross-branch conflict checking depends on it) is not backed by any UNIQUE constraint; two staff rows for the same user in a tenant would fragment the conflict lock (advisory lock keyed by staff_id) and double calendar columns.
- Fix: `CREATE UNIQUE INDEX staff_members_tenant_user ON staff_members(tenant_id, user_id) WHERE user_id IS NOT NULL;` (partial because `user_id` is nullable for non-login staff, ADR-12). Add to Phase 2 migration backlog and the skill's required-patterns list.
- Affects: Phase 2 Epic 2.1, `supabase-database` skill.

### F-DB-10: `supabase-database` skill teaches the wrong pg_cron install form for Supabase
- Severity: minor
- Location: `supabase-database` skill, "Migration workflow" ("Extensions are enabled once in `000001`: `btree_gist`, `pgcrypto`, `pg_trgm`, `pg_cron`, `pgmq`"); IMPLEMENTATION_PLAN Phase 0 Database work.
- Problem: Supabase's official install doc for Cron specifies `create extension pg_cron with schema pg_catalog;` plus `grant usage on schema cron to postgres; grant all privileges on all tables in schema cron to postgres;` — a plain `CREATE EXTENSION pg_cron;` in a migration is not the documented form and historically fails or mis-schemas on the hosted platform. The skill's blanket sentence would be copied into `000001` verbatim.
- Evidence: https://supabase.com/docs/guides/cron/install
- Fix: change the skill line to spell the forms out: `btree_gist`, `pgcrypto`, `pg_trgm` plain; `pg_cron` as `CREATE EXTENSION pg_cron WITH SCHEMA pg_catalog;` (+ the two grants); `pgmq` per the Supabase Queues doc (own schema). Mirror in the Phase 0 migration backlog item.
- Affects: `supabase-database` skill, IMPLEMENTATION_PLAN Phase 0 Epic 0.2.

### F-DB-11: backend.md carries unverified/wrong operational claims not superseded by any ADR, plus two corrupted text artifacts in plan files
- Severity: minor
- Location: `backend.md` §7.4 (`[functions.bookings.rate_limit] max_concurrent_requests = 20`), §6.4 (`supabase db test`), §3.2 line 767 (`Authorization: ***'Authorization')!`); `IMPLEMENTATION_PLAN.md` Phase 5 acceptance ("Realtime channel authorization: branch *** session receives no branch A payloads").
- Problem: (a) per-function `config.toml` supports `verify_jwt`, `import_map`, `entrypoint`, `static_files` — there is no `rate_limit` key (verified: https://supabase.com/docs/guides/cli/config), so the documented "built-in rate limiting … configurable via config.toml" is unbuildable as written and the MVP has no real per-endpoint rate-limit story besides platform defaults; (b) `supabase db test` is not a CLI command — `supabase test db` is (verified: https://supabase.com/docs/reference/cli/supabase-test-db); the chair-updated docs and skills use the correct form, so this is a stale-doc trap; (c) two `***` redaction/corruption artifacts make an acceptance criterion unreadable ("branch *** session") — it should read "branch B session". (backend.md's §1.4 limits table itself verified correct against current docs — no change needed there.)
- Fix: (a) replace §7.4 with the real mechanism: platform-level protection only in MVP (auth endpoints covered by Supabase Auth rate limits), custom per-tenant limiter in `_shared` post-MVP, Phase 9 threat model owns public endpoints; (b) `supabase test db`; (c) restore the two corrupted strings. Mark backend.md as superseded-by-ADRs where applicable so readers weight it below CONVENTIONS/skills.
- Affects: backend.md §6.4/§7.4, IMPLEMENTATION_PLAN Phase 5 acceptance, (optionally) a note in CONVENTIONS §7 pointing at the correct command (already correct there).

### F-DB-12: The one "design-driving" gateway fact ADR-34 keeps (KNET cannot do merchant-initiated recurring billing) is itself sourced only from third-party blogs
- Severity: minor
- Location: ADR-34 Decision (Phase 2) "The one constraint we keep as design-driving …: KNET does not support merchant-initiated recurring billing"; sources cited in requirements PD-payments-1 (kuwaitdev.com, dsrpt.com comparison posts).
- Problem: this fact drives a real architectural commitment (Phase 3/14 memberships on tokenized cards, never KNET), yet ADR-34 exempts it from the Phase 10 re-verification that applies to every other gateway claim. My search found no primary source (KNET/gateway official docs) confirming or denying it.
- Evidence: web search 2026-10-04 returned only generic gateway tokenization/MIT pages (e.g. https://developer.mastercard.com/mastercard-gateway/documentation/gateway-features/cit-mit/) and no KNET-specific primary statement; UNVERIFIED either way.
- Fix: one-line ADR-34 amendment: the KNET-recurring constraint joins the Phase 10 discovery re-verification list; the tokenized-card design stays as the default (it is correct for cards regardless), but the "KNET can never" claim is labeled an assumption until an official source confirms it.
- Affects: ADR-34, IMPLEMENTATION_PLAN Phase 10 scope line.

### F-DB-13: The `SET search_path` rule covers only the three helper functions, not the SECURITY DEFINER RPC surface ADR-24/Phase 5-6 mandate
- Severity: minor
- Location: `supabase-database` skill "Authorization helpers" (search_path present there only); ADR-24 RPCs (`book_appointment`, `reschedule_appointment`, `cancel_appointment`, `set_appointment_status`), Phase 6 RPCs (`create_sale`, `settle_balance`, `refund_payment`, `void_sale`, `open_register`, `close_register`), ADR-22 audit trigger functions.
- Problem: every one of those is `SECURITY DEFINER`; without `SET search_path` (or schema-qualified names) each is a search-path hijack vector and a Supabase linter failure — the skill teaches the convention only for the three helpers, so the booking/checkout RPCs written from the skill can miss it. (The draft SQL's `set_updated_at` and `check_staff_double_booking` also lack it, but the trigger is already rejected; the pattern must not survive into the rewrite.)
- Fix: add to the skill's "Authorization helpers" section and ADR-20 (or ADR-24 consequences): every `SECURITY DEFINER` function — helpers, booking/checkout RPCs, audit triggers, `resolve_service`, refund-cap trigger — is written `SET search_path = public` (or fully schema-qualified) and the pgTAP/CI gate runs `supabase db lint` on every migration (already in Phase 0's CI list — keep it pointed at this).
- Affects: `supabase-database` skill, ADR-20/22/24 consequences text, Phase 5/6 RPC implementations.

---

## Verified-correct items (no finding)

- Edge Functions limits in backend.md §1.4 and ADR-27 match current official docs exactly (memory, wall clock, CPU, idle, bundle size, function counts, log limits, secrets) — https://supabase.com/docs/guides/functions/limits.
- ADR-21's `security_invoker` requirement and its Supabase citation are correct (verified above); the skill and Phase 7 CI check encode it.
- The direct-write allowlist is consistent across ADR-28, CONVENTIONS §6, and the `spa-platform-architecture` skill (same six tables, same prohibited list) — no drift found. (F-DB-6 argues one entry is wrong, but the three documents agree with each other.)
- ADR-24's advisory-lock pattern (`pg_advisory_xact_lock(hashtextextended(staff_id::text, 0))`) is sound Postgres (hashtextextended: PG 13+; bigint advisory locks), the generated `busy_range` + partial exclusion constraint is valid SQL, and per-staff serialization genuinely closes the check-then-insert race; the concurrency tests in Phase 5 are the right gate.
- ADR-14's `invoice_counters` `UPDATE … RETURNING` under row lock is the correct gap-tolerant pattern, and the draft's `(tenant_id, sale_number)` unique index is explicitly superseded.
- Money: ADR-17's integer-minor-units ruling is internally consistent across decisions, CONVENTIONS, skills, and plan (all `_minor`/bigint, no `numeric` survivors in the chair-updated artifacts; the `Number.MAX_SAFE_INTEGER` bound holds for any realistic fils amount).
- Commands in the chair-updated artifacts are correct: `supabase test db`, `supabase migration new`, `supabase gen types`, `supabase functions deploy --use-api`/`--slug`.
- Draft-SQL defects (views without `security_invoker`, trigger race, `started` status, `numeric` money, `branch_services`/`branch_hours`/`staff` names, `resources` in MVP, `refunds` table, `payment_method` enum, missing `register_sessions`/`blocked_times`/`shifts`/`idempotency_keys`/`merged_into`, `profiles USING (true)`, `tenants WITH CHECK (true)`, tenant-only policies on branch tables) are all real but every one is already converted into a binding ADR correction (ADR-2/4/5/6/7/9/12/13/15/17/19/20/21/22/23/24/25/26/31/34/46); Phase 1+ rewrites carry them. They are listed here for the chair's cross-check, not re-ruled.

## Summary table

| id | severity | title |
|---|---|---|
| F-DB-1 | blocker | Sentinel branch UUID contradicts composite FKs (ADR-20 rules 5+6 unbuildable together) |
| F-DB-2 | major | `has_tenant_role` default-NULL branch param silently drops branch scoping |
| F-DB-3 | major | Composite-FK rule misses client/appointment/sale/payment/staff/register references — cross-tenant writes still possible |
| F-DB-4 | major | Role-grant rules unspecified; `platform_admin` still in the memberships enum against CONVENTIONS §5 |
| F-DB-5 | major | Staff "own lines only" sales visibility and staff client "B" writes are unimplementable as specified |
| F-DB-6 | major | `blocked_times` on the direct-write allowlist bypasses ADR-24 cross-entity locking |
| F-DB-7 | major | Appointment `ref_number`: no uniqueness, no generator, no ADR |
| F-DB-8 | major | Report-view SQL defects the Phase 7 rewrite inherits (`si.service_id` invalid; join-inflated client counts) |
| F-DB-9 | minor | No UNIQUE (tenant_id, user_id) on staff_members for ADR-12's one-row invariant |
| F-DB-10 | minor | Skill teaches wrong pg_cron install form for Supabase |
| F-DB-11 | minor | backend.md: fictional config.toml rate_limit, wrong `supabase db test`, corrupted `***` artifacts |
| F-DB-12 | minor | KNET-no-recurring kept as design-driving fact on blog-only evidence — add to Phase 10 re-verification |
| F-DB-13 | minor | `SET search_path` rule missing for the SECURITY DEFINER RPC/trigger surface |

Counts: **1 blocker, 7 major, 5 minor** (13 findings).
