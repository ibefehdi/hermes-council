# Round 2 verifier adjudication

Scope: adjudication of coverage.md, data-backend.md, decisions-audit.md, and plan-skills-audit.md. I read all four reports and the referenced plan corpus. No reviewer file is missing or truncated. Findings below are merged where they describe the same defect; IDs are retained so the chair can trace every disposition.

## Factual checks used in rulings

- Supabase Edge Functions limits page confirms 256 MB memory, 150/400 s wall-clock limits, 2 s CPU/request, 150 s idle timeout, and distinguishes 20 MB CLI-bundled local size from 5 MB server-side bundled size: https://supabase.com/docs/guides/functions/limits
- Supabase configuration documentation lists per-function `verify_jwt`, `import_map`, `entrypoint`, and `static_files`; it does not list a `rate_limit` function config key: https://supabase.com/docs/guides/cli/config
- Supabase RLS documentation states that grants and policies both apply and that Postgres 15+ views should use `security_invoker = true`: https://supabase.com/docs/guides/database/postgres/row-level-security
- Stylelint documents `declaration-property-value-disallowed-list` as property/value pairs and `property-disallowed-list` as the rule for banning properties: https://stylelint.io/user-guide/rules/declaration-property-value-disallowed-list/ and https://stylelint.io/user-guide/rules/property-disallowed-list
- The Supabase CLI/RLS documentation itself uses `supabase test db` in its current RLS guide; therefore the reports' claim that this command is invalid is not reliable without pinning a CLI version. The plan should pin the project CLI and use the command documented for that version rather than assert a universal correction.
- The KNET recurring claim has an official PayTabs support citation in decisions-audit.md: https://support.paytabs.com/en/support/solutions/articles/60000692059-knet-activation-and-workflow. The claim is sufficiently supported for the current decision, but gateway discovery should still re-check provider terms before Phase 10.

## Adjudication by finding

### Blockers accepted

1. F-PLAN-1 / F-cov-1 — ACCEPT. The requirements explicitly promise a reduced MVP home/today surface, while the implementation plan has no route, story, acceptance criterion, screen, or phase. This is an MVP omission, not merely a naming issue. Fix: add US-DASH-1, Phase 7 scope/backlog/fixture acceptance, and default-route behavior; or record an explicit ADR removing the MVP promise. The chair should choose one, not leave both documents inconsistent.

2. F-PLAN-2 — ACCEPT. Refund semantics are materially contradictory: requirements says negative payment, ADR-34 says positive amount with `payment_type=refund`, and the draft SQL has a separate refunds table plus a `sale` enum value. The authoritative decision must be positive ledger rows, `payment_type='payment'|'refund'`, linked refund payment, nonnegative amount check, and netting in reports. Update ADR-34/glossary/Phase 6 wording and rewrite or quarantine SQL 000010. Drop `refunded` if ADR-7 excludes it.

3. F-PLAN-3 / F-3 — ACCEPT, merged. Two phase-numbering schemes and ADR-41's nonexistent “Phase 3 (calendar)” make implementation gates ambiguous. Declare IMPLEMENTATION_PLAN 0–17 as canonical; map old release Phase 2 to plan Phases 9–11 and old release Phase 3 to plan Phases 12–17; sweep ADRs, CONVENTIONS, and all skills. ADR-18 must say plan Phase 17; ADR-41 must say plan Phase 5. Re-run Mermaid and skill checks.

4. F-DB-1 — ACCEPT as blocker. The sentinel UUID cannot satisfy the composite branch foreign key unless a sentinel branch row is created, which the plan does not define. Do not silently add a fake branch. Replace it consistently with nullable `branch_id` plus `all_branches` and a check constraint, partial unique indexes, policy/helper updates, and one migration-wide rewrite. If the chair instead chooses a real sentinel branch, that must be an explicit alternative ADR with tenant ownership and all FK behavior specified; mixing both models is forbidden.

## Major findings accepted or accepted with changes

5. F-DB-2 — ACCEPT. Remove the default `p_branch_id DEFAULT NULL` from branch-sensitive authorization helpers. Add a separate explicit any-branch helper and pgTAP proving branch-A manager fails for branch B. This closes a security footgun rather than relying on caller discipline.

6. F-DB-3 — ACCEPT. Extend composite tenant-consistency FKs to every tenant-owned parent reference, not only denormalized branch/service/staff columns. Enumerate appointment/client, appointment-item, sale/payment/register, tips/staff, and related pairs; add `UNIQUE(id,tenant_id)` parents and negative cross-tenant pgTAP tests. A plain UUID FK plus tenant-only check is insufficient.

7. F-DB-4 plus F-perm-4 — ACCEPT, merged. Remove `platform_admin` from the memberships role enum. Specify role-grant rules in ADR-20 and the onboarding/staff function: owner-only owner grants; branch managers may grant only receptionist/staff in their branch; all changes audited; platform operations use explicit audited impersonation. Remove platform_admin from ordinary frontend membership guards and model impersonation as an audited session mode/banner.

8. F-perm-1 — ACCEPT, blocker. Split refund/void from checkout/discount/tips in requirements: owner and manager only; receptionist forbidden. Mirror in ADR-10, CONVENTIONS allowlist, Phase 6 ACL and tests. This is a direct money-control authorization defect.

9. F-DB-5 plus F-perm-2 — ACCEPT, merged. The staff client rule and staff sales visibility cannot be implemented from the current matrix. Choose and document: staff read only basic fields for clients with appointments at assigned branches, no master-data writes; notes/allergy writes only if explicitly intended and separately authorized. Staff sales must be exposed through an own-sales secured RPC/view joining sale items, not branch-wide sales-table SELECT. Add policy and pgTAP/fixture tests.

10. F-DB-6 plus F-PLAN-18 — ACCEPT with change. The reports disagree over who creates blocked time, and direct writes bypass the cross-entity booking lock. Keep the requirements intent explicit: receptionist/manager may create own-branch blocks, staff requests and manager approval creates them, all-branch blocks are manager+. Route every write through a locked staff/blocked-time function; remove blocked_times from direct-write allowlists. Update Phase 2 ACLs and tests.

11. F-DB-7 — ACCEPT. Appointment `ref_number` is required by search but has no generator or uniqueness. Either remove it from MVP and search UUID, or add a booking-RPC counter and `UNIQUE(branch_id, ref_number)` with an ADR and concurrency test. The chair should not leave a naked NOT NULL text column.

12. F-DB-8 — ACCEPT. The view SQL has a nonexistent `sale_items.service_id` reference and a 1:N join that inflates client counts. Rewrite with the actual item/type join and pre-aggregate or DISTINCT counts; remove the false claim that selecting tenant_id makes a view RLS-safe. Add multi-sale and top-service fixtures to Phase 7.

13. F-PLAN-4 — ACCEPT. Move the DB currency-lock trigger/test to Phase 6 when sales exists, while Phase 1 tests only the UI/predicate contract. Keep one cross-phase acceptance reference so the requirement is not lost.

14. F-PLAN-5 — ACCEPT. Make dependency text, Mermaid, and gantt agree: marketing depends on notifications/Phase 9; retail depends on Phase 8; payroll need not depend on Phase 15 unless explicitly justified. Re-run Mermaid validation.

15. F-PLAN-6 — ACCEPT. Phase 8 assumes branch/staff/service/override/shift import software that is only stubbed or absent. Add implementation tasks for all import functions, dry-run validation reports, idempotent batches, role creation, audit logging, and staging RPCs; retain the runbook as execution documentation.

16. F-PLAN-7 — ACCEPT. Client profile appointment history, branch labels, sales history, and no-show count are promised but left as stubs. Assign concrete Phase 5 and 6 frontend tasks and acceptance tests; remove vague “wired in Phases 5–7” language.

17. F-PLAN-8 / F-fe-2 — ACCEPT, merged. Canonicalize query keys by entity scope: tenant segment for tenant-scoped clients, tenant+branch for branch-scoped data, and tenant+id for client detail. Qualify the “always scope” rule. Reconcile the skill, frontend.md, and realtime signatures in both skill trees.

18. F-PLAN-9 — ACCEPT. Replace the incorrect Stylelint rule with `property-disallowed-list` (or a validated logical-CSS plugin), preserve reviewed physical-property exceptions, and run the lint gate.

19. F-PLAN-10 — ACCEPT. Add an accountable role Owner column to the risk register; retain Owner signal separately. A monitoring signal is not ownership.

20. F-PLAN-11 — ACCEPT. Add legal/privacy sign-off and Arabic content review to go-live, including bilingual notice/terms, export/audit demonstration, migrated names, receipt copy, and UI review.

21. F-cov-2 — ACCEPT with change. Rich KPI/comparison reports and performance insights have no implementation home. Add a concrete analytics phase/backlog after the dependency point, or explicitly defer/remove every affected requirements row and parity claim. “Phase 3” alone is not an executable commitment.

22. F-walk-1 — ACCEPT. Cross-branch reschedule must call target-branch service resolution and re-snapshot price, duration, and buffers, recording old/new values in audit. Add this to US-CAL-4, ADR-13, and Phase 5 RPC acceptance.

23. F-1 — ACCEPT with change. The SQL drafts are not safe migration inputs and contain rejected security, booking, money, naming, and schema decisions. Best fix is to rewrite them before they are treated as migrations. If that cannot happen now, move them under `sql/drafts-v1/`, prepend a superseded banner, and ensure tooling never applies them. Do not claim the plan is build-ready while unsafe `.sql` files remain in the active migration path.

24. F-2 — ACCEPT with change. Reconcile backend.md/frontend.md to ADRs, preferably rather than merely banner them. At minimum add a prominent superseded banner and remove stale examples from any “getting started” path. Correct auth-hook/JWT authorization, function routing, envelope/error names, server wrapper, UUIDs, queue semantics, materialized-view advice, and query keys.

25. F-4 — ACCEPT. Carve `is_blocked`, `is_deleted`, and `merged_into` out of direct client writes; route through the clients function with role checks and audit. Keep ordinary contact/profile writes only where the final matrix permits them.

26. G-1 — ACCEPT. Add an ADR distinguishing Supabase/Auth platform limits from an application per-tenant limiter, with endpoint coverage, quotas, failure mode, and Phase 9 public-booking threat-model ownership. Do not invent a nonexistent `[functions.<name>.rate_limit]` config key; the official config reference does not list it.

## Minor findings accepted

27. F-DB-9 — ACCEPT. Add the partial unique index `(tenant_id,user_id)` for non-null login identities and a Phase 2 test.

28. F-DB-10 — ACCEPT with verification. Correct the pg_cron installation wording to the hosted Supabase-supported form and cite the official install document; validate the exact migration against the chosen CLI/project version.

29. F-DB-11 — ACCEPT with change. Replace the fictional rate_limit config claim and restore corrupted `***` text. For the test command, pin the Supabase CLI version and use the command its official documentation supports; do not rely on the report's universal “db test is invalid” assertion because current Supabase RLS documentation itself shows `supabase test db`.

30. F-DB-13 — ACCEPT. Require `SET search_path = public` or fully qualified names on every SECURITY DEFINER helper, RPC, trigger, resolver, and refund-cap function; lint and test this convention.

31. F-DB-12 — ACCEPT with change only as a Phase 10 verification reminder, not as a claim that the current ADR is unsupported. The PayTabs support citation is adequate for the present design. Label it provider-specific and re-verify gateway terms before implementation.

32. F-cov-3 — ACCEPT. Add a tax summary/list report to Phase 7 or explicitly defer it; taxes cannot be called fully MVP-ready while collection has no reconciliation output.

33. F-cov-4 — ACCEPT with change. Decide explicitly that service charges are out of scope/deferred and remove the draft column, or assign the feature and rename the money field to bigint `_minor`. Do not infer a feature from an unsafe draft column.

34. F-cov-5 and F-cov-6 — ACCEPT. Assign custom statuses and consent/intake forms to named later phases or mark them non-committed; replace dangling “Phase 3” language.

35. F-cov-7 — ACCEPT. Add branch `first_day_of_week`, `time_format`, defaults, editor, and calendar/shift-grid threading. Saturday/default behavior for Arabic tenants must be explicit.

36. F-cov-8 — ACCEPT. Add nullable client source with import defaults and report/defer behavior, or explicitly defer it. Update model, US-CL-1, and CSV contract together.

37. F-perm-3 — ACCEPT. Add owner-only CSV client import to the matrix.

38. F-fe-1 — ACCEPT. Replace “one tenant per user” with active-membership context and multi-tenant switcher semantics; server re-derives membership every request.

39. F-fe-3 — ACCEPT. Specify timeout/reconnect UX and idempotent retry behavior; explicitly state no offline-first writes in MVP.

40. F-i18n-1 — ACCEPT. Add `<bdi>`/`dir=auto`/unicode isolation guidance and a mixed Arabic/LTR test.

41. F-i18n-2 — ACCEPT. Use the shared UI `flipOnRtl` primitive; remove raw `scaleX(-1)` guidance from frontend.md.

42. F-term-1 — ACCEPT. Replace “Started” with “In progress” / `in_progress` everywhere.

43. F-skill-1 — ACCEPT. Add canonical Tax rate and Currency glossary entries.

44. F-walk-2 — ACCEPT. Choose and document whether after-hours cash refunds require an open session or are recorded as manager-approved unlinked cash movements; add ledger/register tests.

45. F-walk-3 — ACCEPT. State explicitly that operational and financial data are branch-scoped while clients/allergies/notes are intentionally tenant-visible for safety.

46. F-5 — ACCEPT. Document the snapshot-column exception to the no-table-prefix convention.

47. F-6 — ACCEPT with change. Security-invoker views still require suitable grants as well as RLS policies. Add explicit grants/policy setup and a pgTAP read test; cite Supabase's grants-and-policies guidance rather than a secondary source.

48. F-7 — ACCEPT. Add `plan_features` to ADR-15's canonical table list.

49. F-BE-1 — REJECT as stated. The report's “5 MB is wrong” conclusion is false in context: current Supabase documentation distinguishes 20 MB CLI-bundled local size from 5 MB server-side bundled size. Correct the skill/backend wording to state both limits, not to replace 5 MB with 20 MB universally.

50. G-2 — ACCEPT with change. Add a region/data-residency decision or an explicit legal/product assumption with owner and verification gate. Do not assert that a particular region satisfies Kuwait PDPA without legal/provider evidence.

51. G-3 — ACCEPT. Add RPO/RTO, retention, restore-drill scope, and owner to the backup/PITR decision.

52. G-4 — ACCEPT. Add offboarding sequence, retention/anonymization/deletion timelines, export contract, and legal owner.

53. G-5 — REJECT as a required ADR. Runtime flags are optional and not necessary if MVP uses plan entitlements only. Add a short CONVENTIONS statement that runtime flags are not used in MVP; create an ADR only if the product chooses to introduce them.

54. G-6 — ACCEPT with change. Document environment topology and deploy boundaries in Phase 0/CONVENTIONS; an ADR is useful but not mandatory if the decision is recorded normatively once.

55. F-PLAN-12 — ACCEPT. Add slot-step field/default/editor in Phase 1 and consume it in Phase 5.

56. F-PLAN-13 — ACCEPT. State one schedule commitment: 22-week critical path plus 20% buffer, approximately 27 weeks; explain the 72 engineer-week arithmetic separately.

57. F-PLAN-14 — ACCEPT. Replace rhetorical drafting prose with the final settings/onboarding routing rule.

58. F-PLAN-15 — ACCEPT. Make the quick-start Arabic plural example include all six categories, matching the reference.

59. F-PLAN-16 — ACCEPT with change. Make the Storage design task unconditional before the first upload feature, while allowing actual upload capability to remain conditional.

60. F-PLAN-17 — ACCEPT with change. Record an explicit decision that post-MVP phases are decision-level only and receive detailed backlogs at scheduling time; otherwise the chair brief's backlog requirement remains silently unmet.

## Findings rejected or superseded

- F-DB-12 is not rejected wholesale, but its original “blog-only / unverified” severity rationale is superseded by the official PayTabs citation. Only the re-verification action remains.
- F-BE-1 is rejected as a correction to 20 MB; both 20 MB local CLI and 5 MB server-side limits must be retained.
- G-5 is rejected as a mandatory architecture gap; a normative “no runtime flags in MVP” note is sufficient.
- Any duplicate assertion that the draft SQL is already safe because ADRs exist is rejected. ADRs do not make active `.sql` files safe; the lifecycle/banner or rewrite action is required.

## Own verifier sweep: additional findings missed by all four reports

### F-verifier-1: No explicit authoritative-document precedence rule
- Severity: major
- Location: plan root documentation; decisions.md/CONVENTIONS.md/backend.md/frontend.md relationship
- Problem: reports repeatedly find stale contradictory artifacts, but the corpus does not state which file wins when requirements, ADRs, implementation plan, SQL, and skills disagree. This is why unsafe drafts remain actionable.
- Fix: add a short precedence rule to CONVENTIONS or decisions summary: binding ADRs and current implementation plan govern; requirements are product intent; active SQL and skills must conform; any superseded artifact carries a banner/path outside active migrations. Add CI grep/check for the banner and active-path status.
- Affects: decisions.md, CONVENTIONS.md, SQL lifecycle, backend.md/frontend.md.

### F-verifier-2: No end-to-end migration gate proves the rewritten schema is the one used by functions and generated types
- Severity: major
- Location: IMPLEMENTATION_PLAN Phase 0/1 migration workflow, Phase 5/6 RPCs, SQL rewrite handling
- Problem: the plan requires SQL rewrites, Edge Functions, generated types, RLS tests, and skills, but no acceptance gate applies a clean migration set to an empty database, generates types, builds all functions, and runs pgTAP plus negative tenant/branch/money/booking tests. Without this gate, individually “fixed” documents can still produce a non-buildable schema/function mismatch.
- Fix: add a CI acceptance job: clean `supabase db reset`/migration apply on pinned CLI, `supabase gen types`, function typecheck/build, `supabase test db`, lint, and adversarial fixture suite. The job must fail if any draft-v1 SQL path is applied.
- Affects: Phase 0 CI, Phase 7 hardening, SQL lifecycle.

### F-verifier-3: Report and export privacy boundary is not specified for tenant-wide client data
- Severity: major
- Location: requirements §2.4/US-SEC-3, report RPCs/views, export design ADR-43
- Problem: the plan intentionally makes client records tenant-visible for safety, while managers' operational exports are branch-limited, but it does not state whether report views, CSV exports, search, and audit viewers may include client contact/allergy fields across branches. A “tenant-wide clients” choice can become a privacy leak through reports or exports.
- Fix: define field-level/export rules: client lookup may be tenant-wide for booking/safety; financial/operational aggregates remain branch-scoped; contact/allergy exports are owner-only unless a documented manager scope is chosen; redact allergy detail from ordinary aggregate reports; add role/branch negative export tests.
- Affects: requirements §2.4, US-SEC-3, report RPCs, ADR-43, Phase 7 tests.

### F-verifier-4: Time-zone boundary semantics for daily sales/no-show reports are not binding
- Severity: major
- Location: requirements dashboard/reports, ADR-45, Phase 7 report acceptance
- Problem: branch-local timezone is defined, but “today,” daily summary, no-show count, and cross-branch sales aggregation do not state whether day boundaries are evaluated in the selected branch timezone, tenant timezone, or UTC. A late-night Kuwait booking can otherwise land in the wrong day and mismatch dashboard, register, and report totals.
- Fix: define every daily metric as `[local date at the selected branch IANA timezone)` converted to UTC for predicates; cross-branch reports require an explicit branch or documented tenant-wide aggregation rule. Add DST and midnight-boundary fixtures.
- Affects: ADR-45, US-RPT-1/3, dashboard, Phase 7 reconciliation tests.

### F-verifier-5: Money/tax rounding and discount ordering are not fully deterministic
- Severity: major
- Location: ADR-17, Phase 6 checkout, tax/discount requirements
- Problem: integer minor units and KWD 3 decimals are correct, but the plan does not bind the order and rounding mode for line discounts, percentage discounts, tips, tax-inclusive pricing, service charges, and refunds. Two valid implementations can produce different totals or violate reconciliation.
- Fix: add a checkout calculation ADR/spec: calculation order, precision scale, half-up/even rule, per-line versus invoice-level rounding, tax-inclusive extraction, discount allocation, and refund allocation. Provide golden fixtures with expected fils totals and negative tests for tampered totals.
- Affects: ADR-17/34, US-CO-1..6, Phase 6 RPC/tests, reports.

## Ordered fix list for the chair

### Blockers first

1. F-PLAN-1/F-cov-1: decide and implement or explicitly remove MVP home/today screen.
2. F-PLAN-2: bind positive refund-ledger semantics and remove contradictory refunds SQL/enum/status.
3. F-PLAN-3/F-3: canonicalize phase numbering and sweep all references.
4. F-DB-1: replace sentinel/composite-FK contradiction with one coherent all-branches representation.
5. F-perm-1: split manager-only refunds/voids from receptionist checkout rights.

### Majors

6. F-DB-2/F-DB-3: make branch helpers explicit and all tenant-owned FKs composite; add attack-path tests.
7. F-DB-4/F-perm-4: remove platform_admin membership role and define audited grant/impersonation rules.
8. F-DB-5/F-perm-2: settle staff client/sales visibility and implement secured views/RPCs.
9. F-DB-6/F-PLAN-18: settle blocked-time roles and route writes through locked RPC.
10. F-DB-7: generate and uniquely constrain appointment references or remove them.
11. F-DB-8: repair report SQL and add reconciliation fixtures.
12. F-PLAN-4/F-PLAN-5: fix currency-lock phase and dependency diagrams/gantt.
13. F-PLAN-6/F-PLAN-7: build imports and finish client-profile history/no-show/sales surfaces.
14. F-PLAN-8/F-fe-2 and F-PLAN-9: reconcile query keys/realtime signatures and Stylelint rule.
15. F-PLAN-10/F-PLAN-11: add risk owners and legal/privacy/Arabic go-live gates.
16. F-cov-2: give rich analytics a real phase or remove/defer its promises.
17. F-walk-1: re-resolve target branch pricing on cross-branch reschedule.
18. F-1/F-2/F-4: rewrite or quarantine unsafe SQL and reconcile stale backend/frontend references; carve protected client columns from direct writes.
19. G-1: add rate-limit decision and implementation owner.
20. F-verifier-1 through F-verifier-5: add precedence, clean-migration, privacy-boundary, timezone, and deterministic-money gates.

### Minors

21. F-DB-9/F-DB-10/F-DB-11/F-DB-13: identity uniqueness, pg_cron form, pinned CLI command, and SECURITY DEFINER search_path.
22. F-cov-3 through F-cov-8 and F-perm-3: tax report, service-charge disposition, dangling phase features, branch calendar preferences, client source, and import permission row.
23. F-fe-1/F-fe-3/F-i18n-1/F-i18n-2/F-term-1/F-skill-1/F-walk-2/F-walk-3: multi-tenant context, degraded network, bidi, icon mirroring, status terminology, glossary, refund session behavior, and client-visibility caveat.
24. F-5/F-6/F-7: snapshot naming exception, security-invoker grants/tests, and plan_features table list.
25. G-2/G-3/G-4/G-6: residency, backup/RPO, offboarding, and environment topology decisions; G-5 only needs an MVP convention.
26. F-PLAN-12 through F-PLAN-17: slot step, schedule arithmetic, drafting prose, Arabic plural example, Storage design task, and post-MVP backlog exception.

## Gate decision

The swarm is NOT yet evidence-sufficient for a pass. The reports expose four blocker-class implementation/authorization contradictions and five additional verifier-sweep major gaps. The chair may pass only after the blocker fixes are applied and the ordered major fixes have explicit dispositions in the revised plan and REVISION_LOG.md.

Summary metadata: {"gate":"fail","reviewer_files":4,"accepted_findings":60,"rejected_or_superseded":3,"new_verifier_findings":5,"blockers":5,"majors":20,"minors":26,"web_sources_checked":5}
