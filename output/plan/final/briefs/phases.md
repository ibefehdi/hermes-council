# Phases and subphases

Output: `/Users/fahad/council/output/plan/final/drafts/phases.md`

Restructure the revised `IMPLEMENTATION_PLAN.md` into phases and subphases, from empty repository to SpaCorner live, then to a sellable multi-tenant product. Keep the canonical phase numbers; subphases are numbered `<phase>.<n>` (for example 5.3).

1. Every phase, including every post-MVP phase (these are currently thin and must be expanded to the same depth as the MVP phases), gets: goal; why it comes at this point; what the business can do at the end; Fresha equivalent (evidence reference) and how ours differs; size; dependencies; risks; exit criteria.
2. Every subphase is a shippable slice of one to three weeks and gets: goal; features delivered; database work (tables, migrations, RLS policies); Edge Functions and RPCs; screens; i18n/RTL work; acceptance criteria (testable, including Arabic/RTL and tenant isolation where relevant); tests; backlog tasks (each small enough for one pull request, tagged DB / Edge Function / Frontend / Ops); dependencies on other subphases.
3. Slot in the extra features the parity worker is likely to propose (online booking site, WhatsApp, KNET, packages, gift cards, loyalty, inventory and transfers, commissions, group and couples bookings, rooms and equipment, waitlists, deposits, corporate accounts, client app, self-serve onboarding and billing, platform admin, audit log) as subphases of the most suitable post-MVP phase, or as new phases where none fits. Coordinate through the swarm root comments if you can see the parity draft.
4. A Mermaid dependency diagram at subphase level for the MVP and at phase level for post-MVP, and a Mermaid gantt chart with subphases as tasks, assuming the team size stated in the revised plan (state it).
5. Go-live checklist for SpaCorner and the risk register (owner, likelihood, impact, mitigation), updated for round 2.
6. Residual issues found while doing the above.
