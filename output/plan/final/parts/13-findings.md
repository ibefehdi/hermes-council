## What the council found

The plan went through three rounds: an initial member round, an adversarial review round whose 60 accepted findings reshaped the corpus, and this final round, whose verification gate and fixes are recorded below. Nothing was silently dropped: rejected proposals and stale findings stay on record with their reasons.


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

### The final independent pass over the revised plan

I re-read the revised `decisions.md`, `CONVENTIONS.md`, and `IMPLEMENTATION_PLAN.md` end to end as a fresh reviewer. The corpus is now internally consistent to a degree round 1 never reached: the phase numbering is single-scheme and swept; the money model is one representation bound by one calculation order; the authorization model is one lookup path with one role enum; the all-branches representation is single-model; the ADRs, CONVENTIONS, implementation plan, and skills cross-reference each other correctly (I traced ADR-20's ten rules, the ADR-51 order, and the allowlist in both mirrored locations). Sizes add up: Phases 0–8 sum to the stated 72 engineer-weeks, and the 22-week critical path + 20% ≈ 27 weeks is arithmetically consistent with the gantt's dependencies. The residual defects found are below (§5); none is a contradiction inside the binding documents — they are omissions or under-specifications the rounds did not catch. Two of them (export wall-clock, pg_net) depend on platform facts I verified against current Supabase documentation.

### The final round: what it checked and what changed

The final round re-read the whole revised corpus once more. Five members produced fresh drafts (Fresha parity, architecture and UML, decisions and reasoning, phases, SQL), and an independent verifier re-executed the evidence: the SQL checker over the v2 migration set (12 migrations, 33 tables, RLS on all 33, both isolation tests passing), the Mermaid checker over every diagram (40 diagrams parsed), and spot checks of more than 20 parity rows against the Fresha evidence corpus. The gate passed with ten required fixes. All ten are applied in this document and in the binding corpus:

1. `pg_net` joined the extension set (Phase 0, the database skill, and the validated v2 migrations) so the ADR-33 pg_cron invocation design holds.
2. The Phase 7.3 full-tenant export is now a chunked, resumable pgmq job; the ten-minute benchmark measures the whole job, and every invocation stays under the Edge Function wall-clock limit.
3. `appointments.during` and `appointment_items.busy_range` are documented as trigger-maintained in v2, and cancellation/no-show `status_active` transitions are part of the booking RPC contract with Phase 5 race tests.
4. The stale findings F-final-db-2 and F-final-db-4 are closed: v2 already enforces one open register per branch (`idx_rs_one_open`) and `UNIQUE (branch_id, kind)` on counters; both keep named concurrency tests.
5. Idempotency replay is scoped per function: `UNIQUE (tenant_id, key, function_name)`, applied in v2 and tested in `003_final_round_fixes.sql`, with a Phase 6 mismatch test.
6. Opening-hours equality is defined: `opens_at = closes_at` is rejected by `boh_nonzero_length` unless `is_closed`; zero-length and overnight fixtures are in Phases 1 and 5 and in the v2 test suite.
7. The MVP time-off workflow is decided and recorded as ADR-53: managers create blocks on behalf of staff; no request/approval state in MVP.
8. Corporate/house accounts are marked an uncommitted candidate with no phase placement; scheduling them requires a new ADR.
9. Post-MVP (Phases 9-17) backlogs are labeled illustrative scheduling input, preserving convention F-PLAN-17; MVP backlogs stay binding.
10. Platform operations are consistently described as the audited impersonation path, never a fifth in-app membership role.

The chair also applied three schema changes to the validated v2 set during assembly (pg_net in `000001`, the idempotency unique scope in `000009`, the `boh_nonzero_length` check in `000003`) and added test `003_final_round_fixes.sql`; the checker passes all 12 migrations and all three test files after the change.

### Final-round findings and rulings

Every residual issue raised by the final-round drafts, with the verifier's ruling and where the resolution lives now.

| Finding | Area | Ruling | Resolution |
|---|---|---|---|
| F-final-parity-1 | Parity | Accept | PLAN.md uses canonical Phase 0-17 numbering everywhere; requirements.md's old release buckets stay superseded by the precedence rule |
| F-final-parity-2 | Parity | Accept | Fresha-style sale drafts are not planned: sale creation is atomic and idempotent, `unpaid`/`part_paid` express "not settled yet"; revisit only on pilot evidence |
| F-final-parity-3 | Parity | Accept | Service charges not planned; tips (ADR-26 area) and manual items (ADR-2) cover the desk need; ADR-51 percentage machinery exists if ever demanded |
| F-final-parity-4 | Parity | Accept | Client file uploads land with the first upload feature after the unconditional Phase 9 storage design; patch tests stay a Phase 11 candidate pending a product/legal decision |
| F-final-parity-5 | Parity | Accept as UNVERIFIED | The 59-report catalogue (technical/reports.md §5) is canonical; the 58-card count in pages.md §35 is a listing/naming artifact and the discrepancy stays on record — not every report page was individually opened |
| F-final-parity-6 | Parity | Accept | Dynamic assignment is a Phase 9 candidate, not an MVP promise; the MVP slot engine already supports "any eligible staff" |
| F-final-parity-7 | Parity | Accept | Reviews and two-way inbox stay "not planned (revisit if…)" with the recorded trigger, not an eternal prohibition |
| F-final-arch-1 | Architecture | Accept | No active production migration set exists yet; the UML is ADR-level canonical intent and must be re-checked after the Phase 0/1 migrations are generated (stated in the Domain model section) |
| F-final-arch-2 | Architecture | Accept | The schedule-x premium verdict is a Phase 0 spike gate (ADR-41) |
| F-final-arch-3 | Architecture | Accept | Post-MVP sequence diagrams are intentionally deferred to scheduling time |
| F-final-arch-4 | Architecture | Accept | Storage design is an unconditional Phase 9 task before any upload capability (ADR-43, F-PLAN-16) |
| F-final-arch-5 | Architecture | Accept | eu-central-1 is a recorded assumption with a Phase 8 legal gate, never a compliance claim (ADR-48) |
| F-final-arch-6 | Architecture | Accept | Realtime channel authorization must be specified and tested at the Phase 5 gate (ADR-38) |
| F-final-sql-1 | SQL | Accept as implementation note | v2 uses triggers for `during`/`busy_range` (PGlite compatibility); production may restore `during` as generated on real Postgres; trigger bypass/update coverage is tested |
| F-final-sql-2 | SQL | Accept with test gate | The partial exclusion syntax passes the checker; pinned real Postgres/Supabase validation is still required, with a documented fallback |
| F-final-sql-3 | SQL | Accept with test gate | The booking RPC must set `status_active`/clear busy state for cancelled and no-show items; concurrent cancellation/booking tests are Phase 5 acceptance |
| F-final-sql-4 | SQL | Accept with fix | `resolve_service` converts to `RETURNS TABLE` before production (Phase 3 note); v2 keeps `record` |
| F-final-sql-5 | SQL | Accept | The `handle_new_user` auth trigger is correctly skip-blocked for PGlite and must be tested on real Supabase |
| F-final-backend-1 | Backend | Accept with required plan fix | Export chunking/resumption applied in Phase 7.3 and ADR-43 (chair fix 2 above) |
| F-final-db-1 | Database | Accept with required fix | `pg_net` added (chair fix 1 above) |
| F-final-db-2 | Database | Rejected as stale; retained as doc test | v2 already has `idx_rs_one_open`; Phase 6 gained the named concurrency test (chair fix 4 above) |
| F-final-db-3 | Database | Accept with required fix | Idempotency scoped per function (chair fix 5 above) |
| F-final-db-4 | Database | Rejected as stale; retained as doc check | v2 has `UNIQUE (branch_id, kind)` plus the two-kind CHECK; the constraint is now mentioned in the plan and counter races cover both kinds |
| F-final-db-5 | Database | Accept | Opening-hours equality defined and constrained (chair fix 6 above) |
| F-final-product-1 | Product | Accept | ADR-53 decides the MVP workflow (chair fix 7 above) |
| F-final-plan-1 | Plan | Accept as editorial | The `P6 --> P16` edge is now in the phase dependency diagram |
| R-final-phases-1 | Phases | Resolved | WhatsApp is explicitly in Phase 9.3 scope, screens, and backlog |
| R-final-phases-2 | Phases | Resolved | Inter-branch transfers are Subphase 13.4 with full scope and backlog |
| R-final-phases-3 | Phases | Resolved | Phase 17.1 details the public marketing site and signup; a native client app is noted as beyond current scope |
| R-final-phases-4 | Phases | Chair ruling | Corporate/house accounts stay UNPLACED and uncommitted; a new ADR must decide their home before any scheduling |
| R-final-phases-5 | Phases | Chair ruling | Expanded post-MVP backlogs are labeled illustrative scheduling input; F-PLAN-17 stays binding |

### Confidence by section (final verifier scores)

| Area | Confidence |
|---|---|
| Product scope and phase sequencing | 0.94 |
| Fresha parity matrix and evidence mapping | 0.88 (report-count discrepancy remains UNVERIFIED) |
| ADR reasoning and council findings | 0.93 |
| Domain architecture and UML | 0.86 (active migrations not yet present; diagrams are canonical intent until re-checked) |
| SQL v2 correctness and isolation | 0.90 (checker and all three tests pass; production PostgreSQL validation pending) |
| Security and authorization model | 0.91 (realtime authorization and the full matrix are Phase 5 gates) |
| MVP implementation phases | 0.90 |
| Post-MVP detail | 0.80 (illustrative by design) |
| Overall | 0.89 |

