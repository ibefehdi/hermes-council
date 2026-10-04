# Implementation plan and skills audit (round 2, cartographer)

Audited: `IMPLEMENTATION_PLAN.md` (669 lines), `decisions.md` (ADR-1..46), `CONVENTIONS.md`, `requirements.md`, the 7 finalized skills in `skills/.cursor/skills/` (identical to `.claude` per `check-skills.mjs`, which passes), the SQL drafts where they intersect plan rulings, the dependency diagram and gantt (both parse under `check-mermaid.mjs`), the go-live checklist, and the risk register, against the round-1 chair brief (`output/plan/briefs/chair.md`).

Tooling results: `node check-skills.mjs plan/skills` → OK (7 skills, .cursor/.claude identical). `node check-mermaid.mjs` on IMPLEMENTATION_PLAN.md (2 diagrams) and CONVENTIONS.md (1) → OK. These are NOT findings; the findings below are semantic.

---

## Blockers

### F-PLAN-1: The MVP "today at a glance" home screen exists in requirements but nowhere in the plan
- Severity: blocker
- Location: `requirements.md` §1.1 row 1 ("Dashboard / home ... MVP (reduced) ... Only today-at-a-glance: today's appointments, today's sales, no-show count"); `IMPLEMENTATION_PLAN.md` phases 0–8 (absent)
- Problem: requirements places a reduced home screen in MVP. `grep -i "dashboard|at a glance|today's sales|no-show count"` over IMPLEMENTATION_PLAN.md returns zero matches. No phase goal, scope, screen, acceptance criterion, or backlog task in any MVP phase delivers it. The login shell (Phase 0) and the setup checklist (Phase 1) are the only landing surfaces, and after go-live SpaCorner's default screen is undefined.
- Evidence: requirements.md line 23; IMPLEMENTATION_PLAN.md has no matching item (grep result above, 0 hits).
- Fix: add to Phase 7 (reports/hardening — it only reads Phase 5/6 data) scope and backlog:
  - Scope bullet: "- Home/today screen (requirements §1.1, reduced): today's appointments (branch-scoped, links into calendar), today's sales total and count, no-show count; role-scoped (receptionist sees own-branch operational numbers only, per §3 matrix)."
  - Backlog Epic 7.2: "- [Frontend] Home/today screen (today's appointments, sales totals, no-show count; role-scoped, EN/AR)".
  - Acceptance: "- Home screen shows correct today's numbers for the seeded branch fixture in both locales and scopes by role (receptionist: operational only)."
  - Alternative ruling if the chair intends to drop it: record an explicit ADR rejecting the reduced dashboard for MVP — silence is the only invalid state.
- Affects: requirements.md §1.1 (needs a ruling either way), Phase 7 scope/backlog/acceptance; default route of `apps/back-office` after login.

### F-PLAN-2: Refund representation is contradictory across the document set (negative vs positive rows), and the draft SQL still carries the rejected model
- Severity: blocker
- Location: `requirements.md` US-CO-4 ("A refund creates a linked negative payment record"); `decisions.md` ADR-34 ("a refund row ... carries a positive `amount_minor`") and ADR-17 ("`CHECK (>= 0)` except where a signed ledger row is explicitly allowed"); `sql/000010_create_sales.sql` lines 88–119; `spa-domain-glossary` Refund row
- Problem: three incompatible statements: requirements says refunds are NEGATIVE payment records; ADR-34 rules they are POSITIVE amounts on type-discriminated rows (`payment_type ∈ {payment, refund}`); the draft SQL (line 88) uses `payment_type IN ('sale', 'refund', 'prepayment')` — enum value `sale`, not the ruled `payment` — and creates a separate `refunds` table (lines 106–119) that ADR-34 explicitly rejected. An implementer following US-CO-4 writes negative rows that violate `CHECK (amount_minor >= 0)`; one following the SQL draft builds two ledgers for one concept. The draft sale status also includes `'refunded'` (line 27), which is outside ADR-7's fixed enum (`unpaid, part_paid, completed, voided`).
- Evidence: quoted lines above; ADR-34 "Decision (MVP ledger model)"; ADR-7 sale status enum; draft SQL lines 27, 88–89, 106–119.
- Fix (chair applies where it can — decisions/CONVENTIONS/SQL/skills; requirements keeps the stale wording, so the ADR must explicitly supersede it):
  1. Append to ADR-34 Consequences: "**Binding clarification superseding requirements US-CO-4's 'negative payment record' phrasing**: a refund is a `payments` row with `payment_type = 'refund'` and a **positive** `amount_minor` referencing `refunds_payment_id`; every `payments` column keeps `CHECK (amount_minor >= 0)`; no signed ledger columns exist. Reports and the daily summary net refunds by subtracting refund sums."
  2. Glossary Refund row: append "positive `amount_minor`" so the sign is stated where implementers look.
  3. Phase 1 SQL rewrite list (ADR-15 consequences): delete the `refunds` table; `payment_type` check becomes `('payment','refund')` (not `'sale'`); drop `'refunded'` from the sale status check; add `register_session_id` (already ruled).
- Affects: ADR-34, ADR-17 consequences text, `spa-domain-glossary`, Phase 6 DB work wording (already says "canonical ledger" — make the sign explicit there too), `sql/000010_create_sales.sql` rewrite inventory.

### F-PLAN-3: Two conflicting phase-numbering schemes, and ADR-41's go/no-go gate references a phase that does not exist in either
- Severity: blocker
- Location: `decisions.md` ADR-1/2/3/4/8/9/10/18/34/41/43 and summary table; `CONVENTIONS.md` §2 line 56; skills `spa-platform-architecture` (lines 13, 28), `supabase-edge-functions` (line 8), `react-frontend` (line 3 / §Quick start context); `spa-domain-glossary` line 67; `IMPLEMENTATION_PLAN.md` phases 0–17
- Problem: decisions.md, CONVENTIONS.md and three skills use the old release numbering ("Phase 2" = online booking/notifications/Storage; "Phase 3" = growth: inventory, packages, resources), while IMPLEMENTATION_PLAN.md numbers phases 0–17 (online booking = Phase 9; Storage = Phase 9; inventory = Phase 13; packages = Phase 14; resources = Phase 15). The glossary's banned-words line uses PLAN numbering in the same corpus ("`membership` as a product feature before Phase 14"). Worst case: ADR-41's binding fallback deadline — "the fallback must still meet the same acceptance criteria before Phase 3 (calendar) exits" — matches neither scheme: the calendar is plan Phase 5 and part of the MVP in the release scheme. As written the spike-fallback gate is unanswerable. Additional concrete mismatches: ADR-18 says self-serve signup is "a post-MVP phase (Phase 11)" — plan Phase 17; ADR-1 summary "Online booking is Phase 2" — plan Phase 9.
- Evidence: decisions.md lines 82 ("Phase 2 adds the public booking page"), 222 ("Phase 11"), 465 ("before Phase 3 (calendar) exits"), 481 ("Phase 2 introduces Storage"); CONVENTIONS.md line 56 ("Phase 2 client-facing booking app ... scaffold only in MVP" — the plan scaffolds it in Phase 0); supabase-edge-functions SKILL.md line 8 ("Phase 2 adds `notifications`, `webhooks`, `online-booking`" — plan Phase 9); spa-platform-architecture line 12 ("Storage (Phase 2+, ADR-43)").
- Fix: declare one scheme in decisions.md's conventions block: "Phase numbers refer to IMPLEMENTATION_PLAN.md phases 0–17. The former 'Phase 2' release is 'plan Phase 9–11'; the former 'Phase 3' is 'plan Phase 12–16'." Then sweep every occurrence:
  - ADR-41: "before Phase 3 (calendar) exits" → "before plan Phase 5 (calendar) exits".
  - ADR-1 "Phase 2" → "plan Phase 9"; ADR-2 "Phase 3" → "plan Phase 13"; ADR-3 "Phase 3" → "plan Phase 14"; ADR-4 "Phase 3" → "plan Phase 15"; ADR-8/9 "Phase 2" (merge tool) → "plan Phase 11"; ADR-10 "Phase 2" (partial refunds) → "plan Phase 10"; ADR-18 "Phase 11" → "plan Phase 17"; ADR-34 "Phase 2" → "plan Phase 10"; ADR-43 "Phase 2 introduces Storage" → "plan Phase 9".
  - CONVENTIONS.md §2 `apps/booking` comment → "plan Phase 9 client-facing booking app (scaffold only)".
  - Skills: spa-platform-architecture "Storage (Phase 2+ ...)" → "(plan Phase 9+ ...)" and "apps/booking ... Phase 2" → "plan Phase 9"; supabase-edge-functions line 8 → "plan Phase 9 adds `notifications`, `webhooks`, `online-booking`"; react-frontend any "Phase 2" booking-app references → "plan Phase 9". Glossary "before Phase 14" already matches plan numbering — keep.
  - Re-run `check-skills.mjs` after the skill edits (chair's validation step).
- Affects: decisions.md (≈12 ADRs + summary table + open-question answers 9/10), CONVENTIONS.md §2, three skills, glossary consistency note.

---

## Majors

### F-PLAN-4: Phase 1 acceptance criterion "test with seeded sale" is untestable — the sales table does not exist until Phase 6
- Severity: major
- Location: `IMPLEMENTATION_PLAN.md` Phase 1, Acceptance criteria ("Changing currency is blocked once any sale exists (test with seeded sale in staging)"); Phase 6 DB work (sales lands here)
- Problem: Phase 1 must prove the currency lock against a sale row, but `sales` is created in Phase 6. No implementation of the lock can be tested as specified in Phase 1; conversely nothing in Phase 6's backlog adds the lock or its test.
- Evidence: Phase 1 scope/DB list contains no sales migration; Phase 6 Epic 6.1 has no currency-lock task.
- Fix: Phase 1 criterion → "Currency change is blocked in the UI once any sale exists (predicate unit-tested); the DB enforcement trigger ships with `sales` in Phase 6." Add to Phase 6 Epic 6.1: "- [DB] Trigger blocking `tenants.currency` updates when any sale exists for the tenant + pgTAP test (US-ON-2)".
- Affects: Phase 1 acceptance criteria, Phase 6 Epic 6.1, Phase 1 test plan wording.

### F-PLAN-5: Dependency diagram and gantt disagree with each other and with the phase-text dependencies
- Severity: major
- Location: `IMPLEMENTATION_PLAN.md` "Phase dependency diagram" + "Timeline" gantt + Phase 12/13/16 "Key deps" lines
- Problem:
  1. Phase 12 text: "Key deps: Phase 8 (data), **Phase 9 (messaging)**" — but diagram has only `P8 --> P12` and the gantt runs `p12, after p8`, in parallel with p9. Campaigns cannot send before the notifications function exists; the text dependency is missing from both charts.
  2. Gantt `p16, after p15` — Phase 16 (timesheets/payroll) text deps are "Phases 2, 6" and the diagram shows `P2 --> P16`, `P8 --> P16`. There is no P15→P16 edge anywhere; the gantt invents a dependency that pushes payroll behind resources/groups for no stated reason.
  3. Gantt `p13, after p12` contradicts the diagram, which shows `P8 --> P13` only (retail parallelizable with marketing). Not fatal (still ordered), but the two artifacts must agree.
- Evidence: diagram edges (lines 46–56) vs gantt lines 82–87 vs phase-text "Key deps" lines 629, 633, 645.
- Fix (keep diagrams authoritative and re-run `check-mermaid.mjs`):
  - Diagram: add `P9 --> P12["Phase 12 Marketing & loyalty"]`.
  - Gantt: `Phase 12 Marketing & loyalty :p12, after p9, 4w`; `Phase 13 Retail & inventory :p13, after p8, 4w`; `Phase 16 Timesheets & payroll :p16, after p8, 3w`.
  - Alternatively keep p16 late with an explicit note in the §Timeline paragraph, but then add the edge `P15 --> P16` to the diagram too — the two artifacts may not disagree silently.
- Affects: both Mermaid blocks, Timeline note (line 90), Phase 12/13/16 "Key deps" cross-check.

### F-PLAN-6: SpaCorner's data migration is unbuildable as planned: only the clients import exists as software
- Severity: major
- Location: `requirements.md` §6 (branches.csv, staff.csv incl. role per branch, services.csv + overrides, shift grid); `IMPLEMENTATION_PLAN.md` Phase 2 scope ("staff import **stub** (CSV via queue, reused in Phase 4 pattern)"), Phase 4 (only `clients/import` is built), Phase 8 Epic 8.1 (Ops + runbook tasks only)
- Problem: Phase 8 step 1 imports branches → staff → services+overrides → clients → shift grid, and the backlog's only build items are documentation ("Production import runbook"). The branch/staff/service/override/shift import path has no implementation task anywhere: Phase 2 explicitly stubs it, Phase 3 has no import action, Phase 8 assumes working software nobody built. US-ON-1's provisioning path covers tenant creation, not bulk CSV import with dry-run validation reports (§6 requires per-row validation reports for every file).
- Evidence: Phase 2 scope line 235 ("staff import stub"); Phase 8 Epic 8.1 task list (runbook, no code); requirements §6 import mechanics ("validation report per file ... dry-run mode; all imports audit-logged").
- Fix: add Epic 8.0 (or extend Phase 2/3) with build tasks, e.g.:
  - "[Edge Function] `onboarding/import-branches|import-staff|import-services|import-shifts` (service-role, ops path): template validation, dry-run report (row + reason), idempotent batches keyed per ADR-31, audit-logged, role memberships created for staff.csv roles (ADR-20 rule 3 discipline)".
  - "[DB] Import staging/validation RPCs shared with the clients-import pattern (ADR-33 queue)."
  - Keep the Phase 8 runbook tasks as the execution of this software.
- Affects: Phase 8 scope step 1 + Epic 8.1, Phase 2 staff-import stub note (either implement there or reference Epic 8.0), Phase 3 (service/override import action), requirements §6.

### F-PLAN-7: US-CL-2 and US-CAL-6 fall between phases: client-profile history is stubbed in Phase 4 and never finished
- Severity: major
- Location: `IMPLEMENTATION_PLAN.md` Phase 4 (screens: "profile page (history sections **stubbed** with real client data)"; scope: "cross-branch visit history placeholder wired to real data in Phases 5–7"), Phase 5 Epic 5.3/5.4, Phase 6 Epic 6.4
- Problem: US-CL-2 acceptance ("the profile shows each appointment/sale with its branch clearly labelled") and US-CAL-6 ("a client's no-show count shows on their profile") have no completion task: Phase 5's backlog never wires appointment history onto the client profile; Phase 6 adds only the balance section ("Client profile balance section"). "Wired to real data in Phases 5–7" is a promise with no owning task — the profile ships with stubs at go-live.
- Evidence: grep "profile" hits lines 334, 365 (stubs), 464, 502 (balance only); no appointment/sales history or no-show-count task exists in any epic.
- Fix: Phase 5 Epic 5.3 add "- [Frontend] Client profile: cross-branch appointment history (branch-labelled) + client no-show count (US-CL-2, US-CAL-6)". Phase 6 Epic 6.4 add "- [Frontend] Client profile: sales history section (branch-labelled, US-CL-2)". Phase 4 scope: change "wired to real data in Phases 5–7" to name the exact epics (5.3, 6.4).
- Affects: Phase 4 scope/screens, Phase 5 Epic 5.3, Phase 6 Epic 6.4, go-live coverage of US-CL-2/US-CAL-6.

### F-PLAN-8: react-frontend skill teaches a query-key factory that violates ADR-38
- Severity: major
- Location: `skills/.cursor/skills/react-frontend/SKILL.md` §Quick start rule 3 (key example, line ~26); ADR-38 ("every key that can vary by scope includes `[tenantId, branchId]` segments"); `IMPLEMENTATION_PLAN.md` Epic 5.4 line 433
- Problem: the skill's own example key `detail: (id: string) => ['clients', 'detail', id] as const,` omits the tenant segment, directly contradicting the ADR-38 binding correction the same rule 3 cites ("Query keys ... always include tenant and branch scope"). A skill that teaches the wrong convention in its canonical example will reproduce the exact stale-cache bug the ADR was written to prevent. Related drift: the plan's Epic 5.4 calls `useRealtime('appointments', branchId)` while the skill defines `useRealtime('appointments', tenantId, branchId)`.
- Evidence: skill lines 14–27 (rule 3 text vs the `detail` line inside the same code block); ADR-38 consequences; plan line 433.
- Fix: in the skill, replace `detail: (id: string) => ['clients', 'detail', id] as const,` with `detail: (tenantId: string, id: string) => ['clients', 'detail', tenantId, id] as const,`. In IMPLEMENTATION_PLAN.md Epic 5.4, replace `[Frontend] useRealtime('appointments', branchId) cache patching` with `[Frontend] useRealtime('appointments', tenantId, branchId) cache patching`. Re-run `check-skills.mjs`.
- Affects: react-frontend skill (both trees), plan Epic 5.4.

### F-PLAN-9: i18n-rtl reference names a stylelint rule that cannot do what the skill says
- Severity: major
- Location: `skills/.cursor/skills/i18n-rtl/reference.md` §Stylelint enforcement (line 54)
- Problem: the reference says "`declaration-property-value-disallowed-list` blocks `margin-left|margin-right|padding-left|padding-right|left|right`". That rule bans property–**value** pairs (option shape: `{ "property": ["values"] }`); it cannot ban properties outright. Physical properties would sail through CI as the skill is written, silently dropping the RTL release gate's enforcement.
- Evidence: stylelint official rule docs — https://stylelint.io/user-guide/rules/declaration-property-value-disallowed-list (object of property → disallowed values; e.g. `{ "position": ["fixed"] }`).
- Fix: replace the sentence with: "`property-disallowed-list` blocks `margin-left`, `margin-right`, `padding-left`, `padding-right`, `left`, `right` (an alternative is the `stylelint-use-logical` plugin, which enforces logical equivalents and autofixes); exceptions only inside reviewed physical-position cases documented in the PR." Re-run `check-skills.mjs`.
- Affects: i18n-rtl reference (both trees), CONVENTIONS.md if the rule name is repeated there (it is not — only the skill names it).

### F-PLAN-10: The risk register has no owners
- Severity: major
- Location: `IMPLEMENTATION_PLAN.md` "Risk register (program-level)" — column "Owner signal"
- Problem: "Owner signal" is a monitoring signal (pgTAP report, CI suite, deploy logs), not an owner. R1–R12 have mitigations but no accountable party; the audit brief requires owners, and a risk register nobody owns is a list.
- Fix: add an "Owner" column (role, not person): R1 DB lead; R2 DB lead; R3 checkout owner (full-stack lead); R4 frontend lead; R5 frontend lead; R6 payments lead (full-stack); R7 Ops/owner liaison; R8 DB lead; R9 Ops; R10 product owner (chair); R11 engineering manager; R12 Ops. Keep "Owner signal" as a separate monitoring column.
- Affects: risk register table only.

### F-PLAN-11: Go-live checklist misses legal/privacy and Arabic content review
- Severity: major
- Location: `IMPLEMENTATION_PLAN.md` Phase 8 "Go-live checklist"
- Problem: the checklist covers migrations, restore drill, monitoring, import sign-off, test transactions, training, rollback, and portability — but has no legal/privacy item (client data notice/consent basis under Kuwait PDPL, NFR-11; data-processing terms with SpaCorner) and no Arabic content review (migrated client/service names in Arabic, receipt header/footer AR text, UI copy) before branches cut over. Rollback, backups, monitoring, and support (on-call) ARE covered — those are fine.
- Evidence: checklist lines 575–585; NFR-11 (Decree-Law No. 42 of 2023) and Phase 4's anonymize groundwork exist but never surface at go-live.
- Fix: add two items: "- [ ] Legal/privacy: client-data privacy notice published (AR+EN) and data-processing terms agreed with SpaCorner (NFR-11); audit-log access and export paths demonstrated to the owner." and "- [ ] Arabic content review: migrated names/receipt text/UI copy reviewed by an Arabic-speaking reviewer for every cutover branch (NFR-7)."
- Affects: Phase 8 checklist, Epic 8.1 (add an Ops task for the legal/privacy sign-off).

### F-PLAN-18: Phase 2 silently contradicts the requirements role matrix on who may create blocked time
- Severity: major
- Location: `IMPLEMENTATION_PLAN.md` Phase 2 scope ("Blocked time: ... manager-created in MVP (requirements §3)"); `requirements.md` §3 matrix ("Booked-time / blocked time ... Receptionist **B (create)**; Staff S (request → manager approves in MVP: manager creates it)") and US-T-3 ("As front desk I block a therapist's time"); ADR-28 allowlist (`blocked_times` direct-write, own-branch)
- Problem: requirements gives receptionists create rights on blocked time (US-T-3 is written from the front desk); Phase 2 claims "manager-created in MVP" and cites requirements §3 as its source — the citation says the opposite. The RLS policy and pgTAP rows for `blocked_times` will be written to whichever reading the implementer picks.
- Evidence: requirements line 182 and §4.2 US-T-3; plan line 230.
- Fix: either (a) restore the matrix: Phase 2 scope → "blocked time is created by front desk (receptionist and above) for their own branch via the ADR-28 allowlist direct write; staff members request and a manager creates it; all-branches time off is manager+ (sentinel branch)". Update Phase 2 DB work/pgTAP rows (receptionist insert allowed own-branch, staff insert denied) accordingly. Or (b) if the team truly wants manager-only in MVP, record it as an explicit deviation ADR in decisions.md amending the matrix row — a silent contradiction is the only invalid outcome.
- Affects: Phase 2 scope/DB work/pgTAP, ADR-28 allowlist note (already permits direct write either way), requirements §3 matrix (if (b), needs a recorded ruling).

---

## Minors

### F-PLAN-12: Branch slot-step configuration (US-CAL-3) has no field or task
- Severity: minor
- Location: requirements US-CAL-3 ("Slots in 15-minute steps (configurable per branch 5/10/15/30)"); IMPLEMENTATION_PLAN Phase 5 line 375 ("per branch config"); Phase 1 branch editor tabs (details/hours/closures/invoicing/receipt/tips & methods)
- Problem: the slot engine consumes a per-branch step setting that no phase creates — not in Phase 1 settings, not in any backlog task.
- Fix: Phase 1 branch editor scope + Epic 1.2: add "calendar defaults (slot step 5/10/15/30, default 15)" as a `settings` key or branch column; Phase 5 slot engine reads it. One backlog line: "- [DB/Frontend] Branch calendar defaults: slot step setting + editor field (US-CAL-3)".
- Affects: Phase 1 scope/Epic 1.2, Phase 5 slot engine input.

### F-PLAN-13: MVP calendar estimate says 24 weeks; the gantt critical path is 22 and the buffer note implies ~26
- Severity: minor
- Location: IMPLEMENTATION_PLAN line 5 ("72 ew ≈ 24 calendar weeks (~6 months) ... add ~20% calendar buffer"), gantt (p0 2w + p1 3w + max(p2,p3,p4) 3w + p5 5w + p6 4w + p7 3w + p8 2w = 22w), line 90
- Problem: 72/3 = 24 is the naive full-parallelism number; the gantt's critical path is 22w; with the stated +20% buffer it is ~26w. Three numbers, one commitment unclear.
- Fix: state one: "critical path 22 weeks; with the 20% calendar buffer, plan on ~27 weeks (~6.5 months)". Or annotate the header line with "(gantt critical path 22w; buffer → ~27w)".
- Affects: header paragraph only.

### F-PLAN-14: Phase 1 Edge Functions paragraph contains leftover drafting prose
- Severity: minor
- Location: IMPLEMENTATION_PLAN line 182: "`settings` actions live in `catalogue`/`staff`? No — settings mutations that are single-table and role-gated go direct (ADR-28 allowlist); ..."
- Problem: a rhetorical question and self-answer read as an unresolved edit, not a decision; a worker could plausibly parse "actions live in catalogue/staff" as the ruling.
- Fix: replace with: "Settings mutations stay single-table and role-gated and go direct per the ADR-28 allowlist; provisioning and transactional multi-table changes (branch + hours + counter + seeds, invites) go through `onboarding`."
- Affects: Phase 1 only.

### F-PLAN-15: i18n-rtl quick-start Plural example omits the Arabic categories its own reference calls the most common bug
- Severity: minor
- Location: `skills/.cursor/skills/i18n-rtl/SKILL.md` rule 1 example (`<Plural value={count} one="1 client" other="# clients" />`); reference.md §Arabic plural categories
- Problem: the canonical example demonstrates exactly the pattern the reference bans for Arabic (missing `zero/two/few/many`), and the comment "provide every Arabic category the message needs" does not save an example that doesn't.
- Fix: replace with `<Plural value={count} zero="No clients" one="1 client" two="# clients" few="# clients" many="# clients" other="# clients" />` (the reference already has the full six-category example; the quick start should match it).
- Affects: i18n-rtl skill (both trees); re-run check-skills.

### F-PLAN-16: ADR-43 makes the post-MVP Storage design "a named task"; Phase 9 makes it conditional
- Severity: minor
- Location: decisions.md ADR-43 Consequences ("the Phase 2 Storage design is a named task in the plan"); IMPLEMENTATION_PLAN Phase 9 ("Storage introduced here **if** avatars/assets are needed — with the tenant/branch path + bucket policy design from ADR-43 first")
- Problem: the ADR promises an unconditional design task; the plan conditions it on a feature nobody has scheduled, so the design may never happen and the first upload feature would design Storage under pressure.
- Fix: make it unconditional in Phase 9's backlog: "- [DB/Edge Function] Storage design task per ADR-43 (tenant/branch-prefixed paths, bucket policies mirroring RLS, private buckets) — delivered before any upload feature" and change "if avatars/assets are needed" to "when the first upload feature is scheduled; the design task below ships first either way". (Numbering also fixed by F-PLAN-3.)
- Affects: Phase 9 scope/backlog, ADR-43 cross-reference.

### F-PLAN-17: Post-MVP phases (9–17) have no backlog epics, though the chair brief required a backlog per phase
- Severity: minor
- Location: chair brief §2 ("A backlog per phase broken into epics and tasks"); IMPLEMENTATION_PLAN "# Post-MVP phases" intro ("specified to decision level here; each gets its own detailed plan when scheduled")
- Problem: defensible as a scoping decision (stated explicitly, same template promised later), but strictly the round-1 chair requirement is unmet for 9 of 18 phases, and the deviation is asserted rather than ruled.
- Fix: add one sentence to decisions.md (new mini-ADR or a line in ADR-1's consequences): "Post-MVP phases are specified to decision level; their per-task backlogs are produced at scheduling time, per the IMPLEMENTATION_PLAN note — an explicit exception to the chair brief's per-phase backlog requirement." Cheap, and it converts a silent gap into a ruling.
- Affects: decisions.md, plan intro note.

---

## Coverage summary of brief items

1. **Phases** — present and specific for 0–8 (goal/scope/DB/functions/screens/acceptance/tests/deps/risks/size/exit all present); ordering is sound (RLS+auth+i18n in Phase 0; tenant/branch context before calendar; nothing depends on later-phase work — verified per phase against table lists). Defects: F-PLAN-1 (missing MVP module), F-PLAN-4 (untestable criterion), F-PLAN-18 (role contradiction), F-PLAN-12.
2. **Backlog** — every US-ON/T/CAT/CL/CAL/CO/SAL/RPT/SEC story maps to at least one task (checked one by one) EXCEPT the reduced dashboard (F-PLAN-1), client-profile history/no-show count (F-PLAN-7), slot-step config (F-PLAN-12), and branch/staff/service/shift import tooling (F-PLAN-6). ADR-implies-work coverage is complete otherwise (ADR-18 plan row, ADR-31 idempotency, ADR-33 queues, ADR-40 normalization, ADR-43 exports — except F-PLAN-16). No orphan backlog tasks found (all tasks trace to a story or ADR). Task sizes are PR-sized; the largest defensible items (booking RPC, checkout RPC, import wizard) are multi-day but scoped with their own test gates — acceptable, flagged in phase risks.
3. **Diagrams** — both validate (`check-mermaid.mjs` OK) but disagree with text and each other: F-PLAN-5.
4. **Go-live and risks** — rollback, backups, monitoring, support covered; legal/privacy, Arabic content review, and risk owners missing: F-PLAN-10, F-PLAN-11.
5. **Skills** — `check-skills.mjs` OK; descriptions are specific with trigger terms; feature-delivery includes RLS tests and Arabic strings (nothing missing); skills stay out of visual design (Airbnb design skill boundary stated in all three relevant skills). Defects: F-PLAN-8 (wrong key convention), F-PLAN-9 (wrong stylelint rule), F-PLAN-15 (plural example), F-PLAN-3 (phase numbering).
6. **Missing deliverables vs chair brief** — all four artifacts and all seven skills exist and validate; gaps are F-PLAN-17 (post-MVP backlogs) and the items above.

## Finding table

| ID | Severity | Title |
|---|---|---|
| F-PLAN-1 | blocker | MVP "today at a glance" home screen missing from the plan |
| F-PLAN-2 | blocker | Refund representation contradictory (negative vs positive) + draft SQL still has rejected refunds table/enum |
| F-PLAN-3 | blocker | Dual phase-numbering schemes; ADR-41 fallback gate references a nonexistent phase |
| F-PLAN-4 | major | Phase 1 currency-lock criterion untestable (sales table arrives Phase 6) |
| F-PLAN-5 | major | Diagram/gantt disagree with each other and phase-text deps (P12/P13/P16) |
| F-PLAN-6 | major | Migration import tooling for branches/staff/services/shifts unbuilt |
| F-PLAN-7 | major | Client-profile history + no-show count never finished after Phase 4 stubs |
| F-PLAN-8 | major | react-frontend skill key factory violates ADR-38; useRealtime signature drift |
| F-PLAN-9 | major | i18n-rtl names a stylelint rule that cannot ban physical properties |
| F-PLAN-10 | major | Risk register lacks owners |
| F-PLAN-11 | major | Go-live checklist missing legal/privacy and Arabic content review |
| F-PLAN-18 | major | Phase 2 contradicts role matrix on blocked-time creation rights |
| F-PLAN-12 | minor | Branch slot-step config has no field or task |
| F-PLAN-13 | minor | 24-week claim vs 22-week gantt path vs ~26-week buffered figure |
| F-PLAN-14 | minor | Phase 1 leftover drafting prose ("? No —") |
| F-PLAN-15 | minor | i18n plural example omits Arabic categories its own reference requires |
| F-PLAN-16 | minor | Storage design task conditional vs ADR-43's unconditional promise |
| F-PLAN-17 | minor | Post-MVP phases lack backlogs (unruled exception to chair brief) |

Counts: 3 blocker, 10 major, 6 minor (19 total).
