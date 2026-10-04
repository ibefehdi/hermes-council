# Decisions and conventions audit

Output: `/Users/fahad/council/output/plan/review2/decisions-audit.md`

Date: 2026-10-04.  Round-2 adversarial review of `decisions.md`, `CONVENTIONS.md` and all cross-references.

Inputs read (read-only): `plan/decisions.md`, `plan/CONVENTIONS.md`, `plan/review.md`, `plan/requirements.md`, `plan/IMPLEMENTATION_PLAN.md`, `plan/backend.md`, `plan/frontend.md`, `plan/sql/*.sql` (all 13), `plan/skills/.cursor/skills/*/SKILL.md` (all 7), `plan/skills/.claude/skills/*/SKILL.md` (spot-checked, identical per parent metadata).

## Executive summary

The 46 ADRs are internally coherent and resolve every round-1 conflict and open question.  The seven skills have been corrected to match.  The real problems are in the *artifacts*:

- **The 13 SQL files under `sql/` are still the round-1 drafts** — they embody rejected decisions that, if applied, produce cross-branch/tenant data leaks, a race-prone booking trigger, and numeric money.  The chair's ruling says "Phase 1 rewrites them"; while that is a valid decision, the files sit in the repo with a `.sql` extension and no superseded marker, and `CONVENTIONS.md` instructs `supabase db reset`.  Any tool that applies these migrations inherits three blocker-class defects.

- **`backend.md` and `frontend.md` still teach round-1 conventions** that were explicitly rejected (auth-hook, JWT-claim authorization, `booking-create` function naming, old error codes, `withSupabase`, integer-ID examples, "exactly-once" queue claim, materialised views).  The chair's remediation list omits these two files; they remain in the repo as design references that teach the wrong architecture.

- **Phase-numbering is inconsistent**: ADR-18 says self-serve signup is "Phase 11" while the implementation plan places it at Phase 17.  ADRs 1-10 and 43 use requirements macro-phases (Phase 2/3) while ADR-18 uses a plan-style number.  No mapping table exists.

ADR verdicts: **40 keep, 5 keep-with-edit, 1 change (ADR-18), 0 reverse.**

Severity counts: **blocker 0**, **major 4**, **minor 5**, coverage gaps 6.  (The SQL-draft finding is rated major rather than blocker because the "Phase 1 rewrite" decision is explicit and the chair's fix list includes the SQL drafts; the hazard is an artifact-lifecycle risk, not a decision error.)

---

## 1. ADR-by-ADR verdicts

| ADR | Title | Verdict | Reason |
|---|---|---|---|
| 1 | Online booking Phase 2 | keep | Threat-model consequence on Phase 2 is well-placed. |
| 2 | Inventory Phase 3; manual_item | keep | Corrects the SQL check constraint; `manual_item` is the MVP escape hatch. |
| 3 | Packages/gift-cards/memberships Phase 3 | keep | KNET-no-recurring verified (PayTabs docs). Liability+gateway reasoning holds. |
| 4 | Staff+time conflicts only; resources Phase 3 | keep | Good scope discipline; interface abstraction for later. |
| 5 | Six MVP reports | keep | Operator-critical set; generic framework is the right investment. |
| 6 | Register sessions in MVP | keep | Cash reconciliation is a daily need; schema now includes it. |
| 7 | Fixed status enum; `in_progress` | keep | Canonical value chosen; `started` banned everywhere. |
| 8 | No series columns in MVP | keep | "No dead columns" ruling is sound; migration is cheap later. |
| 9 | Duplicate warning MVP, merge Phase 2 | keep-with-edit | `merged_into` column ships in MVP — good.  "Phase 2" should map to plan Phase 11 for clarity. |
| 10 | Full refunds + void in MVP | keep | Role-restricted, cap-enforced, ledgers net refunds. |
| 11 | Clients tenant-scoped, financials branch-scoped | keep | Safety (allergies) wins; aggregates via secured RPCs. |
| 12 | Staff single records, nullable login | keep | Cross-branch conflict + non-login staff both handled. |
| 13 | Branch override rows, snapshotted | keep | Prevents historical drift; composite FK consistency. |
| 14 | Per-branch invoice numbering | keep | Race-safe counter pattern documented. |
| 15 | Glossary naming authority | keep-with-edit | Table list omits `plan_features` (ADR-18); add it (see F-7). |
| 16 | Bilingual name columns | keep | Fallback rules defined; people columns handled. |
| 17 | Money integer minor units | keep | Correct; `numeric(12,3)` rejected.  No reasons to revisit. |
| 18 | Subscription billing, entitlement | change | "Phase 11" self-serve contradicts IMPLEMENTATION_PLAN Phase 17 (see F-3). Fix the phase reference. |
| 19 | Live membership lookup; JWT identity only | keep | Auth Hook mechanism verified; stale-JWT revocation argument is watertight. |
| 20 | Branch-scoped RLS binding rules | keep | Eight mandatory rules; every review finding addressed. |
| 21 | `security_invoker` views + secured RPCs | keep-with-edit | Verified.  Skill does not mention that invoker needs SELECT grants on base tables (see F-6). |
| 22 | Append-only audit log via triggers | keep | Triggers write regardless of path; audit rows immutable. |
| 23 | Appointment items carry own staff/span | keep-with-edit | Correct; `service_name_en` columns contradict CONVENTIONS "no table prefix" (see F-5). |
| 24 | Exclusion constraints + advisory lock | keep | Three-layer design verified; `btree_gist` needed and mentioned. |
| 25 | Buffers snapshotted in busy range | keep | Snapshot prevents historical drift; included in exclusion. |
| 26 | Opening hours, closed periods, blocked time | keep | Overnight, split-interval, sentinel all-branches time off all specified. |
| 27 | One function per bounded context (7) | keep | `auth-hook` correctly removed; 7-function list matches scope. |
| 28 | Hybrid access with allowlist | keep | Watch: `clients` allowlist needs is_blocked carve-out (see F-4). |
| 29 | One API envelope + error catalogue | keep | Single contract; `NETWORK` is client-side only. |
| 30 | `/<function>/<action>` invocation shape | keep | Good versioning story; `packages/api` is the single-seam. |
| 31 | Idempotency keys for money mutations | keep | 30-day expiry; replay returns cached response. |
| 32 | Shared `_shared/` code | keep | All-functions redeploy on `_shared` change is documented. |
| 33 | pg_cron + pgmq, idempotent consumers | keep | At-least-once delivery verified; idempotency discipline required. |
| 34 | Payments ledger; MyFatoorah Phase 2 | keep | KNET-no-recurring verified; provider fees treated as assumptions. |
| 35 | Pin CI-verify Supabase server wrapper | keep | Own `_shared/server.ts` wrapper; no unpinned draft snippet. |
| 36 | pnpm monorepo | keep | Clean build boundaries; validation is Deno-compatible. |
| 37 | Branch in URL, tenant in session | keep | Multi-tenant switch handled; server re-verifies membership. |
| 38 | TanStack Query keys tenant+branch | keep | Realtime channel-authorisation tested in CI. |
| 39 | RHF+Zod shared with Deno | keep | Pure JS schemas; Zod is shape-defence only. |
| 40 | Lingui ICU + logical CSS + Intl | keep | Arabic search normalisation and bilingual columns bound together. |
| 41 | schedule-x conditional on Phase 0 spike | keep | Premium licensing fact checked (schedule-x.dev premium docs). Go/no-go is the right decision model. |
| 42 | TanStack Router typed search params | keep | Route guards UX-only; RLS is the boundary. |
| 43 | Exports stream from EF; Storage Phase 2 | keep | No public URLs in MVP; Storage design done before uploads ship. |
| 44 | UUID PKs | keep | Human-readable numbers are separate per-branch sequences. |
| 45 | `timestamptz` + IANA zone per branch | keep | DST test requirements explicit; Kuwait has no DST but other tenants might. |
| 46 | Mixed soft delete / status retention | keep | Partial unique indexes ignore deleted rows; immutable financials. |

**Verdict counts**: keep 40, keep-with-edit 5, change 1 (ADR-18), reverse 0.

---

## 2. Coverage gaps — decisions the project needs but has no ADR

| Gap | Title | Severity | Context | Fix |
|---|---|---|---|---|
| G-1 | Rate limiting | major | NFR-12 requires rate limiting; ADR-1 defers public-booking threat model to Phase 2, but no ADR defines MVP auth-endpoint rate limiting or per-tenant throttling.  CONVENTIONS and IMPLEMENTATION_PLAN mention it only in passing. | Add ADR ruling on auth-rate-limit config (login attempts, password reset) and per-tenant API-rate-limit design (Supabase function-level vs per-tenant app-level). Tie to ADR-28 allowlist or the onboarding plan. |
| G-2 | Data residency / Supabase region | minor | NFR-11 (Kuwait PDPA) and GDPR baseline imply in-region data residency.  No ADR picks the Supabase project region or documents the residency assurance. | Add ADR naming the Supabase project region (e.g. "eu-west-1" or closest to Kuwait; document why). |
| G-3 | Backups/restore & PITR | minor | NFR-14 requires daily backups + restore drill before GA; Phase 7 + 8 contain the drill, but no ADR defines retention policy, RPO/RTO targets, or the restore procedure scope. | Add ADR on backup strategy: PITR via Supabase managed backups, RPO ≤ 24 h, RTO ≤ 4 h, restore drill in Phase 7. |
| G-4 | Tenant offboarding / data deletion | minor | NFR-10/11 require export + anonymisation; Phase 17 mentions offboarding export.  No ADR defines the offboarding contract (data retention after termination, full-delete timeline, notification to remaining users). | Add ADR: offboarding = export → soft-archive (28 days) → anonymise personal fields → retain financial records indefinitely. |
| G-5 | Runtime feature flags (vs entitlements) | minor | ADR-18 handles plan-based entitlements, but no ADR covers runtime feature flags for phased rollout or kill-switching a feature across tenants without a deploy. | Optional for MVP; add ADR if needed.  Otherwise note in CONVENTIONS that entitlements (`plan_features`) serve as the feature-gating mechanism and runtime flags are not used in MVP. |
| G-6 | Environment topology / preview branches | minor | Phase 0 specifies dev/staging/production + preview branches; CONVENTIONS §8 mentions branches.  No ADR formalises the topology. | Add ADR: Supabase projects (dev local, staging preview-branch, production paid-plan), preview branches for staging, CI deploys only from `main`.  Merge into Phase 0 documentation or a brief ADR. |

---

## 3. Consistency contradictions (both locations quoted)

### 3.1 SQL drafts vs ADRs

The 13 SQL migration files under `plan/sql/` are round-1 drafts.  They contradict the ADRs on every binding correction.  Key contradictions (representative sample; full list is the ADR-15 rewrite scope):

| Contradiction | SQL (draft) | ADR (authoritative) |
|---|---|---|
| Money representation | `default_price numeric(12,3)` (000006:32, 000009:20, 000010:29, etc.) | `bigint` minor units, column suffix `_minor` (ADR-17) |
| Appointment status | `'started'` in CHECK (000009:19) | `'in_progress'` (ADR-7) |
| Resources table | `000007_create_resources.sql` full file | MVP does not ship resources (ADR-4) |
| Double-booking | `check_staff_double_booking()` trigger with `SELECT count(*)` (000009:63-116) | Exclusion constraints + advisory lock (ADR-24); triggers are race-prone |
| Profiles RLS | `profiles_select USING (true)` (000013:27-29) | Self-read only + narrow colleague view (ADR-20 rule 2) |
| Tenants insert | `tenants_insert WITH CHECK (true)` (000013:13-15) | No direct insert; onboarding function only (ADR-20 rule 3) |
| Branch RLS | Tenant-only policies on appointments/sales/payments (000013:292-375) | Branch-scoped policies (ADR-20 rule 1) |
| Refunds table | Separate `refunds` table (000010:106-119) alongside `payments.payment_type = 'refund'` | Single `payments` ledger; no separate refunds table (ADR-34) |
| Invoice numbers | `UNIQUE (tenant_id, sale_number)` (000010:48) | `UNIQUE (branch_id, invoice_seq)` (ADR-14) |
| Report views | No `security_invoker`; comment "Views inherit RLS… No additional policies needed" (000012; 000013:452-453) | `WITH (security_invoker = true)` mandatory (ADR-21) |
| `sale_items.item_type` | Omits `manual_item` (000010:61) | Must include `manual_item` (ADR-2) |
| Table names | `staff` (000005:6), `branch_services` (000006:49), `branch_hours` (000003:29), `staff_working_hours` (000005:42), `staff_time_off` (000005:63) | `staff_members`, `service_branch_overrides`, `branch_opening_hours`, `shifts`, `blocked_times` (ADR-15) |
| Extensions | Only `btree_gist` + `pgcrypto` (000001) | Also `pg_trgm`, `pg_cron`, `pgmq` (IMPLEMENTATION_PLAN Phase 0, supabase-database skill) |
| Missing tables | No `register_sessions`, `idempotency_keys`, `blocked_times`, `tax_rates`, `tips`, `shifts` tables exist | All are MVP tables per ADR-6/15/31/26 |
| `memberships.branch_id` | `NULL` = all branches; `UNIQUE (user_id, tenant_id)` (000004:13,16) | Sentinel UUID = all branches (ADR-20 rule 6).  Multiple branch-scoped memberships per (user, tenant) allowed (ADR-19); unique must be `(user_id, tenant_id, role, branch_id)` or equivalent |
| Audit `branch_id` | Missing from `audit_log` (000011:36-45) | Required by ADR-22 & NFR-3 |

**Ruling**: ADR-15 declares "the draft SQL migrations are a starting inventory, not the final schema; Phase 1 rewrites them under these names with the corrections."  This is a valid decision, but the files remain under `plan/sql/` with `.sql` extensions and are not marked superseded.  See finding F-1.

### 3.2 backend.md vs ADRs

`backend.md` (round-1 member draft) still teaches rejected conventions (representative sample):

| Contradiction | backend.md (draft) | ADR (authoritative) |
|---|---|---|
| auth-hook function | MVP function list includes `auth-hook` (line 42); diagram includes AuthHook (line 808); `index.ts` snippet (line 161) | Removed; no auth-hook in MVP (ADR-19, ADR-27) |
| Tenant context from JWT | "ALWAYS extract tenant info from JWT claims" (§3.5, lines 254-281); `jwtClaims.app_metadata` sourced | Live membership lookup; JWT carries identity only (ADR-19) |
| Error codes | `VALIDATION_ERROR` / `UNAUTHORIZED` / `INTERNAL_ERROR` / `SERVICE_UNAVAILABLE` (lines 310-320) | `VALIDATION` / `UNAUTHENTICATED` / `INTERNAL` / `UNAVAILABLE` (ADR-29) |
| Envelope shape | `{ "error": { "code"... } }` (no `ok: false` wrapper, line 325) | `{ "ok": false, "error": { ... } }` (ADR-29) |
| Server wrapper | `import { withSupabase } from 'npm:@supabase/server@1'` (line 173) | Own `_shared/server.ts` wrapper (ADR-35) |
| Numeric IDs in Zod | `client_id: z.number().int().positive()` (line 238) | UUID strings (ADR-44) |
| Queue semantics | "exactly-once delivery" (line 430) | At-least-once; idempotent consumers required (ADR-33) |
| Materialised views | "Refresh materialised views for fast dashboard loads" (cron table line 438) | Reports use `security_invoker` views + `report_*` RPCs (ADR-21); materialised views can't use `security_invoker` |
| Function naming | Skill draft in §9 says `'booking-create'` invoke slug (implied by frontend §3 line 106: `invoke('booking-create',...)`) | `/<function>/<action>` routing (ADR-30); frontend calls through typed wrappers |

### 3.3 frontend.md vs ADRs

| Contradiction | frontend.md (draft) | ADR (authoritative) |
|---|---|---|
| Error codes | `NETWORK \| UNAUTHENTICATED \| FORBIDDEN \| VALIDATION \| CONFLICT \| NOT_FOUND \| INTERNAL` (line 143) | `NETWORK` client-side only; `UNAUTHENTICATED` / `IDEMPOTENCY_MISMATCH` / `RATE_LIMITED` / `UNAVAILABLE` added; `VALIDATION` (no `_ERROR` suffix) (ADR-29) |
| Function naming | `invoke('booking-create', input, ...)` (line 106) | `bookingApi.create(input)` wrapping `POST /bookings/create` (ADR-30) |
| Query keys | `qk.clients.list(branchId, ...)` — branchId only, no tenantId segment (line 123) | Every tenant+branch-scoped key includes `tenantId` (ADR-38) |
| RLS gate comment | `SessionContext` section says tenant "from the authenticated session" without the live-membership-verification call-out | ADR-37: tenant from session, verified server-side.  The frontend doc is consistent in spirit, just lacks the server-side re-verification call-out.  Minor. |

### 3.4 CONVENTIONS.md vs ADRs

CONVENTIONS.md is broadly aligned with the ADRs.  Two minor contradictions found:

- **§3.2 column naming**: "no table prefix (`name_en`, not `service_name_en`)."  ADR-23 requires `appointment_items` to carry `service_name_en`/`service_name_ar` snapshot columns.  The CONVENTIONS rule has a legitimate exception (snapshot columns need disambiguation); the exception is undocumented.  (Finding F-5.)

- **§6 allowlist `clients` entry**: Lists `clients (non-financial fields)` as a direct-write target, consistent with ADR-28.  However ADR-28's write-up includes "block/unblock audited by trigger" in the same parenthetical, which implies block/unblock could be a direct write.  Requirements US-CL-8 blocks are manager-only.  A direct RLS policy cannot restrict `is_blocked` per-column, so either `is_blocked` writes must route through the `clients` Edge Function (as Phase 4 plans) or the allowlist must carve it out.  (Finding F-4.)

### 3.5 IMPLEMENTATION_PLAN.md vs ADRs

The implementation plan is consistent with all ADRs.  One numbering mismatch (see F-3):

- **ADR-18**: "Self-serve signup, payment collection for subscriptions, and plan management UI are a post-MVP phase (Phase 11)."
- **IMPLEMENTATION_PLAN**: Phase 11 = "Client experience depth" (client portal, merge tool, repeating series, waitlist).  Phase 17 = "SaaS self-serve & subscription billing."
- **ADR-9**: "Interactive merge ... is Phase 2" — consistent with requirements macro-phase 2 (plans Phases 9–11).  No error, but no mapping table exists; readers cannot tell whether "Phase 2" means the requirements macro-phase or an IMPLEMENTATION_PLAN phase.

### 3.6 Seven skills vs ADRs

The seven finalised skills (`skills/.cursor/skills/`) all agree with the ADRs and CONVENTIONS.md.  One minor factual error noted in the edge-functions skill: "5MB deployed size" should be "20MB (bundled)" per current Supabase docs (F-BE-1, §5).  The supabase-database skill's `has_tenant_role` signature includes `p_branch_id DEFAULT NULL` matching ADR-19.  All money columns described as `bigint _minor`.  All RLS patterns include branch scope.  All views with `security_invoker`.  All function invocation examples use `/<function>/<action>`.  Auth-hook is absent.  JWT-claims authorisation is absent.  Skills are correct.

---

## 4. Review.md follow-up resolution

Every issue from `review.md` has been resolved in `decisions.md`:

- **10 open questions**: all 10 answered in "Rulings on the verifier's open questions" (decisions.md lines 63-73).  Money → ADR-17.  Multiple memberships → ADR-19.  Non-login staff → ADR-12.  Receptionist client visibility → ADR-11.  Multi-service visits → ADR-23.  Payment methods/refunds → ADR-34.  Tenant creation → ADR-20 rule 3.  Auth Hook → ADR-19.  schedule-x premium → ADR-41.  Exports/avatars → ADR-43.

- **8 cross-area conflicts**: all 8 ruled.  Tenant context (conflict 1) → ADR-19.  Money (2) → ADR-17.  Appointment status (3) → ADR-7.  Service/sale vocabulary (4) → ADR-2.  API/error contract (5) → ADR-29.  Function naming (6) → ADR-30.  Staff scope (7) → ADR-12.  Client privacy (8) → ADR-11.

- **Security findings** (3 CRITICAL + 3 HIGH + 3 MEDIUM): all addressed.  Branch-scoped RLS → ADR-20 rules 1/4/5/8.  `profiles_select USING(true)` → rule 2.  `tenants_insert WITH CHECK(true)` → rule 3.  `has_tenant_role` missing branch → rule 4.  Composite FKs → rule 5.  Views without `security_invoker` → ADR-21.  Service-role write convention → rule 7.  Realtime authorisation → ADR-38.  Storage paths → ADR-43.  Audit log → ADR-22.  Settings NULL → rule 6.

- **Booking findings** (1 CRITICAL + 2 HIGH + 1 MEDIUM): all addressed.  Trigger race → ADR-24 (exclusion + advisory lock).  Reschedule bypass → ADR-24 (direct updates prohibited).  Item ranges → ADR-23.  Buffers absent → ADR-25.  `staff_time_off` branch scope → ADR-26.  Branch hours representation → ADR-26.

- **SQL findings**: resolved at the decision level (ADRs 2, 6, 7, 9, 14, 15, 17, 20, 21, 23, 24, 25, 26, 31, 34, 44, 45, 46).  Implementation deferred to "Phase 1 rewrites" (ADR-15).  The hazard of keeping the uncorrected drafts in the repo is identified in finding F-1.

- **Skill-review findings**: all resolved.  The final skills in `skills/.cursor/skills/` correctly use integer minor units, `security_invoker`, live membership lookup, exclusion constraints, glossary names, and no `auth-hook`.

- **Verifier disagreements**: PD-DB-3 (numeric) → rejected (ADR-17); PD-BACKEND-3 (JWT claims) → rejected (ADR-19); PD-BACKEND-5 (trigger only) → accepted with changes (ADR-24).  All three verifier disagreements are explicitly recorded and resolved (decisions.md §"Verifier disagreements").

---

## 5. Factual claim verification (web-search evidence)

| Claim | Source in plan | Verified | Citation |
|---|---|---|---|
| Supabase EF limits: 256MB, 2s CPU, 150s/400s wall | ADR-27, backend §1.4 | Confirmed | https://supabase.com/docs/guides/functions/limits |
| Views bypass RLS by default; `security_invoker` on PG 15+ | ADR-21, review.md official-source | Confirmed | https://supabase.com/docs/guides/database/postgres/row-level-security; https://guardlayer.io/blog/supabase-security-definer-view |
| Auth Hooks support Postgres functions *and* HTTP endpoints | ADR-19 consequence | Confirmed | https://supabase.com/docs/guides/auth/auth-hooks (both `pg-functions://` URIs and HTTP URIs documented); https://supabase.com/docs/guides/auth/auth-hooks/custom-access-token-hook |
| pgmq is at-least-once; idempotent consumers needed | ADR-33, review.md official-source | Confirmed | https://dev.to/mwiginton/supabase-queues-in-production-dead-letter-queues-retries-and-poison-messages-with-pgmq-28dp ("at-least-once across a message's lifetime"); https://supabase.com/docs/guides/queues/pgmq |
| KNET does not support merchant-initiated recurring | ADR-3, ADR-34, PD-payments-1 | Confirmed | https://support.paytabs.com/en/support/solutions/articles/60000692059-knet-activation-and-workflow ("NO Auth/Cap or Recurring transactions are allowed") |
| schedule-x resource scheduler is a premium feature | ADR-41 | Confirmed | https://schedule-x.dev/docs/calendar/resource-scheduler ("This is a premium feature which requires an active license"); https://schedule-x.dev/premium |
| Supabase function size: 20MB bundled | backend §1.4, skill note about "5MB" | 20MB is correct; "5MB" is wrong | https://supabase.com/docs/guides/functions/limits ("Maximum Function Size: 20MB (After bundling using CLI)") |

Note: schedule-x premium license pricing (EUR 479/year for 2-3 developers, for-profit commercial use OK per FAQ) is factual and an acceptable budget item for the conditional spike decision.

---

## 6. Findings

### F-1: Round-1 SQL migration drafts still embody rejected decisions

- **Severity**: major (contains blocker-class defects — cross-branch/tenant data leak, double-booking race, numeric money — mitigated only by the "Phase 1 rewrites" note)
- **Location**: `plan/sql/*.sql` (all 13 files); ADR-15
- **Problem**: The 13 migration files under `sql/` are the round-1 drafts.  They still contain: numeric(12,3) money (rejected ADR-17), `started` status instead of `in_progress` (rejected ADR-7), a resources table that ought not ship (rejected ADR-4), `check_staff_double_booking()` trigger with `SELECT count(*)` race (rejected ADR-24), `profiles_select USING(true)` (critical data leak across tenants), `tenants_insert WITH CHECK(true)` (anyone can create tenants), tenant-only RLS on branch-scoped tables (branch-manager bypass), a separate `refunds` table (rejected ADR-34), `staff`/`branch_services`/`branch_hours`/`staff_working_hours`/`staff_time_off` naming (replaced by glossary names ADR-15), no `manual_item` in `sale_items.item_type`, no `register_sessions`, no `idempotency_keys`, no `blocked_times`, no `security_invoker` on views (ADR-21 violation), no branch_id on audit_log, and `memberships UNIQUE (user_id, tenant_id)` which blocks multiple branch-scoped memberships (conflicts ADR-19).
- **Evidence**: File-by-file analysis (§3.1; §5 verifications).
- **Fix**: Two options — (a) rewrite the SQL now to match the ADRs (the chair's fix list includes "the SQL drafts"), or (b) relocate the 13 files to `plan/sql/drafts-v1/` with a superseded banner in each file and remove them from the `sql/` path that tooling or developers might apply.  The "Phase 1 rewrites them" note in ADR-15 is insufficient since `CONVENTIONS.md` and the `supabase-database` skill instruct `supabase db reset` and `supabase migration new`, and nothing marks these 13 files as NOT the migration set to apply.  If (a), the rewritten files must include: `bigint _minor` money columns, `in_progress` status, removal of `resources`, exclusion constraint + advisory lock + item-spans for booking, branch-scoped RLS on all eligible tables, sentinel UUID for branch-all, composite FKs, `manual_item`, `register_sessions`, `idempotency_keys`, `blocked_times`, `security_invoker` on views, `branch_id` on audit_log, discontinued `refunds` table, and the `(user_id, tenant_id, role, branch_id)` memberships unique shape.
- **Affects**: IMPLEMENTATION_PLAN Phase 0 migration list (which already defines a different set — verify overlap); `supabase-database` skill examples; any tooling that references `sql/*.sql`.

### F-2: backend.md and frontend.md still teach rejected conventions

- **Severity**: major (skills/docs that would teach wrong conventions)
- **Location**: `plan/backend.md` (§1.3—function list, §3.5—auth/tenant context, §3.7—error model, §9—skill draft, PD-BACKEND-3); `plan/frontend.md` (§3—invoke naming, §3—error codes, §3—query keys)
- **Problem**: The round-1 member drafts were not included in the chair's fix list (swarm goal list: decisions.md, IMPLEMENTATION_PLAN.md, CONVENTIONS.md, SQL drafts, skills).  They remain in the repo as authoritative design references but teach: the `auth-hook` function (rejected ADR-19/27), JWT-claim-based authorisation (rejected ADR-19), per-action function slugs like `booking-create` (reworked by ADR-30), old error codes `VALIDATION_ERROR`/`UNAUTHORIZED` (replaced ADR-29), the `withSupabase` npm wrapper (replaced ADR-35), numeric IDs in example schemas (replaced ADR-44), "exactly-once" queue delivery (corrected ADR-33), materialised views for reports (conflicts with ADR-21), and query keys without tenant-scope (corrected ADR-38).
- **Evidence**: §3.2 (backend.md) and §3.3 (frontend.md) above; quoted line references from each file.
- **Fix**: Either (a) reconcile both files to match the ADRs (best), or (b) add a prominent superseded banner at the top of each file: "This document is a round-1 draft.  Authoritative decisions are in `plan/decisions.md`.  The architecture described here was superseded in several areas; see ADR-19 (authorisation), ADR-27 (function list), ADR-29 (envelope/errors), ADR-30 (invocation shape), ADR-33 (queue semantics), ADR-35 (server wrapper), ADR-38 (query keys), and ADR-44 (ID strategy).  Do not follow this draft."
- **Affects**: Any developer or agent reading `backend.md` or `frontend.md` before reading `decisions.md`.  The `spa-platform-architecture` skill correctly refers to the ADRs.

### F-3: Phase-numbering inconsistency between ADRs and IMPLEMENTATION_PLAN.md

- **Severity**: major (contradictory decision — anyone reading ADR-18 and IMPLEMENTATION_PLAN side by side cannot determine where self-serve billing belongs)
- **Location**: `decisions.md` ADR-18 line 222; `decisions.md` ADR-9 line 146; `IMPLEMENTATION_PLAN.md` phase table (Phase 11 vs Phase 17)
- **Problem**: ADR-18: "Self-serve signup, payment collection for subscriptions, and plan management UI are a post-MVP phase (Phase 11)."  IMPLEMENTATION_PLAN Phase 11 = "Client experience depth" (client portal, merge tool, repeating series, waitlist).  Phase 17 = "SaaS self-serve & subscription billing."  ADR-9 says "Interactive merge ... is Phase 2" (consistent with requirements macro-phase 2 -> plan Phases 9-11).  ADRs 1-10 and 43 use requirements macro-phases ("Phase 2", "Phase 3").  ADR-18 is the only ADR that uses a plan-style phase number, and it is wrong.  No mapping table between requirements macro-phases and implementation-plan phases exists in any document.
- **Evidence**: Direct quote comparison.  IMPLEMENTATION_PLAN phase table lines 9-29.
- **Fix**: (a) Change ADR-18 "Phase 11" -> "the SaaS self-serve phase" or "Phase 17".  (b) Add a phase-mapping note to `decisions.md` near the summary table: Requirements Phase 2 = plan Phases 9-11; Phase 3 = plan Phases 12-17.  (c) Optionally change ADR-9 to reference plan Phase 11 if granularity is wanted.
- **Affects**: Task-tagging in Phase 11/17 backlogs; any tooling or agent that cross-references ADR phase mentions with IMPLEMENTATION_PLAN.

### F-4: clients direct-write allowlist vs block/delete authorisation

- **Severity**: major (role-authorisation edge case users will hit; receptionist could toggle is_blocked via direct write)
- **Location**: `decisions.md` ADR-28 (allowlist); `CONVENTIONS.md` §6 (allowlist table); `requirements.md` §3 matrix (block = manager-only); IMPLEMENTATION_PLAN Phase 4 (block/unblock routes through `clients/block` Edge Function)
- **Problem**: ADR-28's direct-write allowlist includes `clients` (create/update of non-financial fields) and mentions "block/unblock audited by trigger" in the same clause.  However, US-CL-8 reserves blocking a client to managers, and the requirements matrix (§3) puts "Client delete" as owner-only.  RLS is row-level, not column-level: a receptionist updating a client via supabase-js could set `is_blocked = true` unless the policy or query explicitly prevents it.  The plan Phase 4 already routes `clients/block` through the Edge Function — but the allowlist wording does not carve out `is_blocked`, `is_deleted`, or `merged_into` as function-only columns.
- **Evidence**: ADR-28 line 362 "clients (create/update of non-financial fields — ... block/unblock audited by trigger)"; staffing matrix line 185 "Client delete — owner only"; US-CL-8 "As manager I block a client"; plan Phase 4 backlog 4.2 "clients/block (role + audit)".
- **Fix**: Amend the allowlist (both ADR-28 and CONVENTIONS §6) to state: "clients (create/update of contact/profile fields only; is_blocked, is_deleted, and merged_into are NOT on the allowlist and route through the `clients` Edge Function with role checks)."  The `clients` function already has a block action; ensure the direct write checklist in the `react-frontend` skill and `feature-delivery` skill forbids setting those fields from supabase-js.
- **Affects**: ADR-28, CONVENTIONS §6, `react-frontend` skill allowlist description, `feature-delivery` skill direct-write warning, `clients` Edge Function spec.

### F-5: CONVENTIONS "no table prefix" rule vs ADR-23 snapshot columns

- **Severity**: minor
- **Location**: CONVENTIONS.md §3.2 line 88 "no table prefix (`name_en`, not `service_name_en`)"; ADR-23 line 284 "snapshotted ... service_name_en/service_name_ar"
- **Problem**: CONVENTIONS forbids table-prefixed column names like `service_name_en`, but ADR-23 requires snapshot columns named `service_name_en` and `service_name_ar` on `appointment_items` (and `sale_items`).  The exception is legitimate (snapshot columns need disambiguation from other entities' names snapshotted on the same row), but it is undocumented.
- **Evidence**: Direct quotes from both files.
- **Fix**: Add a note to CONVENTIONS §3.2: "Exception: snapshot columns on items tables (`appointment_items`, `sale_items`) that capture entity names at write time may use `{entity}_name_{locale}` for disambiguation (e.g. `service_name_en`, `service_name_ar` per ADR-23)."
- **Affects**: CONVENTIONS.md only.

### F-6: security_invoker views require invoker to hold SELECT on base tables

- **Severity**: minor
- **Location**: `supabase-database` skill (report views section); ADR-21
- **Problem**: When a view is created `WITH (security_invoker = true)`, permissions are evaluated against the calling user, not the view owner.  That means the calling role must have SELECT grants on the underlying base tables (not just the view).  Supabase's default grants to `authenticated` may cover this, but it is not guaranteed, and the skill/ADR do not mention this requirement.  The first engineer encountering a "permission denied" error on a `security_invoker` report view would have to discover this independently.
- **Evidence**: https://guardlayer.io/blog/supabase-security-definer-view ("The caller needs SELECT on the underlying tables too. Under invoker semantics, permissions are no longer inherited from the view owner.")
- **Fix**: Add a sentence to ADR-21 consequences and the `supabase-database` skill's report section: "Security-invoker views require the invoking role (`authenticated`) to hold SELECT grants on the base tables; ensure GRANT SELECT on base tables is part of the migration/policy setup, and add a pgTAP test verifying the view returns rows (not a permission-denied error) when called by the intended role."
- **Affects**: ADR-21, `supabase-database` skill, report view pgTAP tests.

### F-7: ADR-15 canonical table list omits `plan_features`

- **Severity**: minor
- **Location**: ADR-15 line 196 (canonical table list); ADR-18 line 222 (introduces `plan_features`)
- **Problem**: ADR-15's authoritative table list names every MVP table, but `plan_features` (introduced by ADR-18 for subscription entitlement gating) is missing.  ADR-18 says "a small `plan_features` table" and Phase 1 migrations include it.
- **Evidence**: ADR-15 list does not include `plan_features`; ADR-18 explicitly creates it.
- **Fix**: Add `plan_features` to the ADR-15 canonical list.
- **Affects**: ADR-15 only.

### F-BE-1: Edge Functions deployed size 5MB vs 20MB official limit

- **Severity**: minor
- **Location**: `supabase-edge-functions` skill line 100 "5MB deployed size (keep `_shared` lean)"; also backend.md §1.4 "20 MB local / 5 MB server-side"
- **Problem**: The current Supabase Edge Functions documentation states "Maximum Function Size: 20MB (After bundling using CLI)."  The skill's "5MB deployed size" is too conservative and may cause unnecessary anxiety about `_shared` size.  (The 5MB figure matches an older, undocumented limit; the current docs settle on 20MB bundled.)
- **Evidence**: https://supabase.com/docs/guides/functions/limits
- **Fix**: Change "5MB deployed size" to "20MB bundled size (keep `_shared` lean regardless)" in the edge-functions skill.  Also correct backend.md if it is updated (F-2).
- **Affects**: `supabase-edge-functions` skill; `backend.md` (if fixed per F-2).

---

## 7. Summary table

| ID | Severity | Title |
|---|---|---|
| F-1 | major | SQL migration drafts still embody rejected decisions |
| F-2 | major | backend.md and frontend.md still teach rejected conventions |
| F-3 | major | Phase-numbering inconsistency between ADRs and IMPLEMENTATION_PLAN |
| F-4 | major | clients direct-write allowlist vs block/delete authorisation |
| F-5 | minor | CONVENTIONS "no table prefix" vs ADR-23 snapshot columns |
| F-6 | minor | security_invoker views require invoker SELECT on base tables |
| F-7 | minor | ADR-15 canonical table list omits plan_features |
| F-BE-1 | minor | Edge Functions deployed size 5MB vs 20MB official limit |
| G-1 | major (coverage) | No ADR on rate limiting |
| G-2 | minor (coverage) | No ADR on data residency / Supabase region |
| G-3 | minor (coverage) | No ADR on backups/restore & PITR |
| G-4 | minor (coverage) | No ADR on tenant offboarding / data deletion |
| G-5 | minor (coverage) | No ADR on runtime feature flags |
| G-6 | minor (coverage) | No ADR on environment topology / preview branches |

**Severity counts**:
- Blocker: 0
- Major: 5 (F-1, F-2, F-3, F-4, G-1)
- Minor: 11 (F-5, F-6, F-7, F-BE-1, G-2, G-3, G-4, G-5, G-6)