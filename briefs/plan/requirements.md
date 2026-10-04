# Brief: Product requirements and scope (cartographer)

Output: {{COUNCIL_DIR}}/output/plan/requirements.md

1. Module catalogue: from the two reports, list every module and feature Fresha offers. For each feature: one-line description, and the release it belongs to in our product: MVP (core operations, see common.md), a later phase, or out of scope. Justify non-obvious placements.
2. Multi-tenant and multi-branch requirements: what changes per tenant vs per branch (catalogue, prices, durations, staff, hours, resources, taxes, receipts, numbering of invoices, settings). Specify how a staff member working at two branches behaves, how clients are shared across branches, and what the tenant owner vs branch manager can see and do.
3. Roles and permissions matrix: roles x capabilities (table), with branch scoping.
4. MVP user stories with acceptance criteria, grouped by module: tenant onboarding and branch setup, staff and shifts, service catalogue with branch overrides, clients, calendar and booking (incl. conflicts, buffers, rescheduling, cancellations with reasons, no-shows), checkout with cash/manual payments (discounts, tips if any, refunds/voids), sales and invoices, basic reports (which ones, with metric definitions, informed by the 59 reports catalogued).
5. Non-functional requirements: tenant isolation, audit trail, performance targets (e.g. calendar load for a busy branch), availability (function isolation), Arabic/RTL, time zones, money precision, data export, privacy.
6. SpaCorner onboarding: what data we need from SpaCorner (branches, staff, services, hours, clients import) and in what format.

Draft the skill `spa-domain-glossary`: domain terms (tenant, branch, staff member, service, service variant/branch override, appointment, booking, sale, invoice, payment, ...), their exact meaning, naming in code (table names, TypeScript types), English and Arabic labels, and invariants (e.g. an appointment always belongs to exactly one branch).

Add your "Proposed decisions" section (scope and release placement decisions).
