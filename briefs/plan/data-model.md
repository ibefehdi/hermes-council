# Brief: Data model, multi-tenancy, and database conventions (linker)

Output: {{COUNCIL_DIR}}/output/plan/data-model.md plus draft migrations in {{COUNCIL_DIR}}/output/plan/sql/

1. Tenancy model: tenant (company), branches, memberships (user x tenant x role x branch scope). How the user's tenant and branch scope reach Postgres (e.g. Supabase custom access token hook adding claims, or membership lookups in RLS helper functions); trade-offs; what happens when a user belongs to several tenants.
2. Schema for the MVP: every table with columns, types, constraints, indexes, and tenant/branch keys. Cover tenants, branches, branch hours, users/profiles, memberships, staff (and staff-branch assignments, working hours, shifts, time off), service categories, services, branch service overrides (price, duration, availability), resources/rooms, clients, appointments and appointment items (multiple services, staff, resource), cancellations/no-shows, sales, sale items, payments (method, manual types), refunds, invoice numbering per tenant/branch, audit log, settings.
3. Integrity: prevent double booking of staff and resources at the database level (e.g. exclusion constraints on tstzrange with btree_gist), money as numeric with currency, time zones (timestamptz + branch tz), soft delete vs hard delete, ID strategy, created_by/updated_by, optimistic concurrency.
4. RLS: the policy pattern for every table (tenant isolation + branch scoping + role capabilities), helper functions, how service-role access from Edge Functions is constrained, and how RLS is tested (pgTAP or SQL tests in CI).
5. Draft SQL migrations in output/plan/sql/ (one file per area, Supabase CLI naming: <timestamp>_<name>.sql) for the MVP schema and RLS. They must be valid Postgres; keep them reviewable.
6. Diagrams: erDiagram of the MVP schema; a diagram of the tenancy/auth claims flow.
7. Reporting: which basic reports run from SQL views/functions, indexing for them, and when (if ever) materialised views are needed.

Draft the skill `supabase-database`: migration workflow and naming, table/column naming, required columns (tenant_id, branch_id, timestamps, audit), RLS policy templates, helper functions, constraints patterns, how to add a new tenant-scoped table step by step, testing RLS, seed data, generated TypeScript types.

Add your "Proposed decisions" section.
