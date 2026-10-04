# Final verification report

Date: 2026-10-04
Scope: final-round drafts (`parity.md`, `architecture-uml.md`, `reasoning.md`, `phases.md`, `sql.md`) and corrected SQL v2.

## Verification result

GATE: PASS WITH REQUIRED CHAIR FIXES

The drafts are sufficiently complete and internally coherent for the chair to assemble PLAN.md. The SQL checker passes all 12 migrations and both isolation tests; all Mermaid diagrams parse. The pass is conditional on carrying the required fixes below into PLAN.md and, where stated, into the binding corpus before implementation. These are not reasons to block the chair: the final brief explicitly assigns fixes to the chair.

Evidence executed:

- `node /Users/fahad/council/check-sql.mjs /Users/fahad/council/output/plan/sql/v2/migrations /Users/fahad/council/output/plan/sql/v2/tests`
  - 12 migrations OK.
  - 33 public tables; 33 have RLS enabled.
  - `001_tenant_isolation.sql` OK.
  - `002_branch_isolation.sql` OK.
  - Warning: `public.idempotency_keys` has RLS with no policies (deny-all), which is appropriate for a client-inaccessible mutation table but must be documented.
- `check-mermaid.mjs` over every final draft: 31 diagrams in architecture, 6 in phases, 3 in parity; all parsed. `reasoning.md` and `sql.md` contain no Mermaid blocks.
- Read all five drafts, the final-round briefs, revised `decisions.md`, `CONVENTIONS.md`, `IMPLEMENTATION_PLAN.md`, SQL README, and all 12 SQL migrations.

## Verdict table

| Claim | Source member | Status | Evidence |
|---|---|---|---|
| Canonical plan numbering is Phases 0–17 | phases, parity, reasoning | CONFIRMED | Drafts consistently use 0–17; revised `IMPLEMENTATION_PLAN.md` and ADR-41/18 use the same numbering. Old release-bucket language is explicitly called superseded. |
| MVP is back-office core operations with manual/cash payments; online booking is Phase 9 | parity, reasoning, phases | CONFIRMED | ADR-1/34 and Phase 9 scope agree; parity places calendar, booking, checkout, register, reports in MVP and public booking later. |
| Four membership roles; `platform_admin` is not a membership role | architecture, reasoning, phases | CONFIRMED | Revised ADR-20 and SQL membership role constraint contain only `tenant_owner`, `branch_manager`, `receptionist`, `staff`. Architecture correctly models platform operations as audited impersonation, although one prose sentence should avoid calling it a fifth in-app role. |
| Tenant and branch isolation use live membership lookup, branch-scoped RLS, composite FKs, nullable `branch_id` plus `all_branches` | architecture, reasoning, sql | CONFIRMED | ADR-19/20, SQL v2 migrations, and the two passing isolation tests agree. The SQL checker reports RLS on all 33 tables. |
| Money is KWD integer minor units and refund rows are positive ledger entries | parity, architecture, reasoning, sql | CONFIRMED | ADR-17/34/51, `payments.amount_minor bigint CHECK >= 0`, refund-cap trigger, and Phase 6 acceptance criteria agree. No separate refunds table is active in v2. |
| Deterministic checkout order and server-side recomputation | reasoning, architecture, phases | CONFIRMED | ADR-51 is repeated consistently: line base, line discounts, invoice discount allocation, tax, tips; Phase 6 includes golden fixtures and tampered-total rejection. |
| Register sessions are MVP and one open register per branch | parity, architecture, phases, sql | CONFIRMED | v2 migration `000009` has `idx_rs_one_open` partial unique index; Phase 6 includes open/close and reconciliation. The reasoning residual claiming no named enforcement is stale and should be rejected/closed. |
| Appointment items carry staff/time snapshots; buffers are in the busy range | architecture, reasoning, phases, sql | PARTIAL | Domain intent and SQL columns/triggers agree. v2 uses trigger-maintained `during`/`busy_range`, while architecture prose sometimes says generated columns. PLAN.md must state trigger-maintained columns for the PGlite-compatible v2 implementation. |
| Double-booking is protected by exclusion constraints plus advisory locks/RPC checks | architecture, reasoning, phases, sql | PARTIAL | The v2 exclusion constraint and documented RPC path exist, and checker accepts them. However the SQL comment says cancelled rows require RPC maintenance of `status_active`; the partial predicate does not include `status_active`. Phase 5 must explicitly test cancellation/reschedule races and ensure cancelled/no-show rows clear or otherwise cannot retain a conflicting busy range. |
| Cross-branch reschedule re-resolves price, duration and buffers | parity, architecture, reasoning, phases | CONFIRMED | ADR-13/F-walk-1, reschedule sequence, and Phase 5 acceptance criteria all require target-branch resolution plus old/new audit values. |
| `resolve_service` is production-ready as written | architecture, reasoning, sql | PARTIAL | SQL checker passes, but v2 returns `record`, requiring a call-site column definition. Convert to `RETURNS TABLE` or document the typed call contract before production. |
| Idempotency keys prevent duplicate money mutations | architecture, reasoning, phases, sql | PARTIAL | Table and replay protocol exist and checker passes, but v2 uniqueness is `(tenant_id, key)` while the table has `function_name`; cross-action key reuse is not isolated. Bind a function/action dimension or explicitly enforce one key per mutation in the API and tests. |
| Invoice and appointment reference counters cannot fork | architecture, phases, sql | CONFIRMED | v2 `invoice_counters` has `kind` check and `UNIQUE(branch_id, kind)`; appointment ref uniqueness is `(branch_id, ref_number)`. The reasoning residual F-final-db-4 is stale for SQL but documentation should mention the constraint. |
| Overnight and split opening hours are modeled | parity, architecture, phases, sql | PARTIAL | `seq`, `is_closed`, and overnight rule are present. Equality `opens_at = closes_at` remains ambiguous unless explicitly defined or rejected; add a constraint/semantic rule and fixtures. |
| Reports are seven MVP reports, branch-local by IANA day boundaries | parity, reasoning, phases | CONFIRMED | ADR-5/45, Phase 7.1, and parity's report table agree. Fixtures include midnight and DST cases; client-contact export and allergy redaction boundaries are explicitly stated. |
| Full-tenant export meets the stated benchmark | reasoning, phases | WRONG AS A SINGLE INVOCATION / PARTIAL AS A JOB | Reasoning correctly identifies a conflict: Supabase Edge Function wall-clock limits are 150s free/400s paid, while Phase 7.3 says <=10 minutes. The plan must make the export chunked/resumable via queues, with the benchmark measuring the whole job. |
| pg_cron can invoke Edge Functions in the v2 extension set | reasoning, phases, sql | WRONG / MISSING | ADR-33 mentions `pg_net`, but `000001_enable_extensions.sql` creates pg_cron and pgmq, not pg_net. Add `pg_net` in Phase 0/skill guidance or revise the invocation architecture; validate on the pinned CLI. |
| Fresha calendar, booking, checkout, client, catalogue, team, reports, marketing, online booking, payments, and settings claims are evidenced | parity | CONFIRMED for sampled claims | Spot checks across more than 20 rows found citations to the local evidence corpus: calendar/booking (`pages.md §2`, `TECHNICAL_REPORT.md §4.3`), appointment drawer (`pages.md §39`), sales/payments (`pages.md §§6–7`), clients (`pages.md §11`, `flows.md §Flow 1`), catalogue (`pages.md §§15–20`, `flows.md §§2–3`), team (`pages.md §§31–34`), reports (`technical/reports.md §§5–6`), messaging/online booking/settings (`pages.md §§21–30, 37–41`, `settings.md` sections). No sampled row copied Fresha UI, text, branding, or API shapes. |
| Fresha has 59 reports while pages lists 58 cards | parity | UNVERIFIED / PRESENTED WITH CAVEAT | Both source counts are cited and the discrepancy is recorded as F-final-parity-5. PLAN.md should use the canonical technical report count only, without asserting that every card was individually verified. |
| Extra features do not expand MVP | parity, phases | CONFIRMED | WhatsApp is Phase 9, transfers Phase 13, self-serve onboarding/billing Phase 17; the draft explicitly keeps Phases 0–8 unchanged. Corporate accounts remain unplaced and require an ADR. |
| Expanded post-MVP subphases are binding implementation commitments | phases | PARTIAL | The requested deliverable needs detailed post-MVP phases, and the draft supplies them. Revised corpus convention F-PLAN-17 says post-MVP backlogs are produced at scheduling time. PLAN.md must label post-MVP task lists illustrative/scheduling input, not binding backlog commitments. |
| Staff time-off request/approval is implementable | architecture, phases, reasoning | UNVERIFIED | Role matrix/ADR-26 say staff request and manager approves, but no pending state, queue, or Phase 2 task exists. Chair must choose manager-created blocks for MVP or add a request state and approval flow. |
| Corporate accounts are covered | parity, phases | WRONG / MISSING | B8 identifies corporate/house accounts as a candidate, while phases explicitly leave it UNPLACED. PLAN.md must state this as an uncommitted candidate requiring a new ADR, not as delivered scope. |
| Architecture diagrams match the validated schema | architecture, sql | PARTIAL | Mermaid syntax passes and core entities/relationships align. ER diagrams describe intended composite relationships more fully than the current v2 DDL; active v2 is still a validation set rather than the eventual `supabase/migrations` set. Keep F-final-arch-1 visible and re-check diagrams after active migrations exist. |

## Corrections required in PLAN.md

1. Add `pg_net` to Phase 0 extension/infrastructure work, the database skill extension list, and the clean-migration gate, unless the team deliberately changes the pg_cron invocation design.
2. Rewrite Phase 7.3 export acceptance as a chunked/resumable queued job. Each invocation must remain below the documented Edge Function wall-clock limit; the 10-minute target measures end-to-end job completion.
3. State that `appointments.during` and `appointment_items.busy_range` are trigger-maintained in v2/PGlite compatibility mode, and make the cancellation/no-show `status_active` transition part of the booking RPC contract and tests.
4. Close or correct the stale F-final-db-2 and F-final-db-4 findings: v2 already has the one-open-register partial unique index and `UNIQUE(branch_id, kind)` for counters. Keep their requirements as documentation checks, not unresolved schema defects.
5. Resolve idempotency scope: prefer `UNIQUE(tenant_id, key, function_name)` plus an action/function mismatch test, or explicitly bind one key to exactly one mutation/action in `packages/api` and test it.
6. Define opening-hours equality semantics (`opens_at = closes_at`) and add zero-length/24-hour cases to Phase 1/5 fixtures.
7. Choose and record the MVP staff time-off workflow; do not leave the role matrix contradictory to the data model.
8. Mark corporate accounts as an uncommitted candidate requiring a new ADR and phase placement.
9. Label post-MVP expanded subphase backlogs as illustrative and scheduling-time material, preserving F-PLAN-17's binding convention.
10. Normalize terminology in the architecture context paragraph: platform operations are not an in-app membership role; call them an ops impersonation path.

## Rulings on every draft residual finding

### Parity findings F-final-parity-1 through F-final-parity-7

- F-final-parity-1: ACCEPT. PLAN.md must use canonical 0–17 numbering.
- F-final-parity-2: ACCEPT. Sales drafts are not planned; unpaid/part-paid is the deliberate MVP model.
- F-final-parity-3: ACCEPT. Service charges are not planned; retain the reason and revisit trigger.
- F-final-parity-4: ACCEPT. Put storage design in Phase 9 before uploads; patch tests/forms remain a candidate requiring a product/legal decision.
- F-final-parity-5: ACCEPT AS UNVERIFIED. Use technical/reports.md's 59-report catalogue as canonical and retain the discrepancy note.
- F-final-parity-6: ACCEPT. Dynamic assignment is a Phase 9 candidate, not an MVP promise.
- F-final-parity-7: ACCEPT. Reviews and two-way inbox remain not planned with a revisit trigger, not an eternal prohibition.

### Architecture findings F-final-arch-1 through F-final-arch-6

- F-final-arch-1: ACCEPT. No active production migration set exists yet; diagrams are ADR-level canonical intent and must be rechecked after Phase 0/1 migrations.
- F-final-arch-2: ACCEPT. schedule-x verdict is a Phase 0 spike gate.
- F-final-arch-3: ACCEPT. Post-MVP sequence diagrams are intentionally deferred to scheduling time.
- F-final-arch-4: ACCEPT. Storage design is an unconditional Phase 9 task before upload capability.
- F-final-arch-5: ACCEPT. eu-central-1 is an assumption with a legal gate, never a compliance claim.
- F-final-arch-6: ACCEPT. Realtime authorization must be specified and tested at the Phase 5 gate.

### SQL findings F-final-sql-1 through F-final-sql-5

- F-final-sql-1: ACCEPT AS IMPLEMENTATION NOTE. Trigger-maintained ranges are valid for the checker; document the production-v2 choice and test trigger bypass/update coverage.
- F-final-sql-2: ACCEPT WITH TEST GATE. Checker accepts the partial exclusion syntax, but pinned real Postgres/Supabase validation is still required; retain a fallback decision only if the real target rejects it.
- F-final-sql-3: ACCEPT WITH TEST GATE. The RPC must set `status_active`/clear busy state for cancelled and no-show items; add concurrent cancellation/booking tests.
- F-final-sql-4: ACCEPT WITH FIX. Prefer `RETURNS TABLE` before production to avoid fragile call-site record definitions.
- F-final-sql-5: ACCEPT. The auth trigger is appropriately skipped by PGlite and must be tested in a real Supabase environment.

### Reasoning findings F-final-backend-1, F-final-db-1 through F-final-db-5, F-final-product-1, F-final-plan-1

- F-final-backend-1: ACCEPT WITH REQUIRED PLAN FIX. Chunk/resume exports as described above.
- F-final-db-1: ACCEPT WITH REQUIRED PLAN/CORPUS FIX. Add pg_net or change the scheduling design.
- F-final-db-2: REJECT AS STALE SCHEMA FINDING, RETAIN AS DOC TEST. The v2 partial unique index already enforces the invariant; add a named concurrency test and update the finding.
- F-final-db-3: ACCEPT WITH REQUIRED API/SCHEMA FIX. Function/action must be part of the idempotency boundary.
- F-final-db-4: REJECT AS STALE SCHEMA FINDING, RETAIN AS DOC CHECK. v2 has `UNIQUE(branch_id, kind)` and a two-kind CHECK; mention it in ADR/plan.
- F-final-db-5: ACCEPT. Equality semantics remain under-specified.
- F-final-product-1: ACCEPT. Choose manager-created MVP blocks or implement pending approval state.
- F-final-plan-1: ACCEPT AS EDITORIAL. Add the direct P6→P16 edge or explain the transitive dependency.

## Additional missing coverage and links

- Phase 0 must include `pg_net` or explicitly remove the pg_net invocation claim from ADR-33.
- Phase 7.3 must link export chunking to pgmq visibility timeouts, retry/idempotency, and a final-part assembly/download mechanism.
- Phase 5 must link cancellation/no-show state transitions to the exclusion/range maintenance path, not only to the UI state machine.
- Phase 6 must link the existing v2 one-open-register index to the concurrency acceptance test and daily cash-up invariant.
- The final plan should link `invoice_counters (branch_id, kind)` uniqueness to both invoice and appointment-ref race tests.
- Corporate/house accounts, client patch tests/forms, and gender-specific behavior remain candidates rather than missing MVP features.
- The active migration set is not yet present; the clean migration gate and post-generation diagram review are mandatory before implementation work treats the UML as authoritative.

## Confidence scores

- Product scope and phase sequencing: 0.94
- Fresha parity matrix and evidence mapping: 0.88 (report-count discrepancy remains unverified)
- ADR reasoning and council findings: 0.93
- Domain architecture/UML: 0.86 (intended schema is strong; active migrations are not yet present and trigger-vs-generated wording needs correction)
- SQL v2 correctness and isolation: 0.90 (checker and both isolation tests pass; production PostgreSQL validation and missing pg_net remain)
- Security and authorization model: 0.91 (RLS/composite-FK model is coherent; realtime and full matrix are future gates)
- MVP implementation phases: 0.90
- Post-MVP detail: 0.80 (useful requested detail, but must be labeled scheduling-time/illustrative)
- Overall final map: 0.89

## Chair assembly order

1. Start with product definition, scope boundary, canonical glossary, and document precedence.
2. Insert the decision digest and council findings, preserving ADR precedence and all rejected/accepted rulings.
3. Insert the architecture/UML and data-access/security sections, correcting trigger-maintained ranges and ops impersonation wording.
4. Insert Phases 0–8 as the binding MVP delivery plan, including the pg_net, export chunking, idempotency, register, opening-hours, and time-off fixes.
5. Insert the Fresha parity matrix and beyond-Fresha features, preserving evidence citations and marking candidates/unplanned features accurately.
6. Insert post-MVP Phases 9–17 as requested, but label detailed backlogs illustrative until each phase is scheduled; keep corporate accounts unplaced pending ADR.
7. Include residual issues and confidence scores; do not silently delete unresolved assumptions.
8. Before implementation, update `decisions.md`, `CONVENTIONS.md`, and the relevant skills for pg_net, idempotency scope, opening-hours equality, time-off workflow, and export chunking. Then regenerate active migrations and re-run SQL, isolation, Mermaid, generated-type, and full RLS/realtime gates.
