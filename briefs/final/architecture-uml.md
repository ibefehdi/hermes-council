# Architecture and UML

Output: `{{COUNCIL_DIR}}/output/plan/final/drafts/architecture-uml.md`

Every diagram must match the revised `decisions.md` and `sql/`. Under each diagram, explain in a short paragraph what it shows and why it is designed that way, referencing the ADRs.

1. System context and containers (C4 level 1 and 2 as Mermaid flowcharts): users, React app, Supabase Auth, Postgres with RLS, each Edge Function group, Storage, Realtime, pg_cron and queues, external services (SMS/WhatsApp/email, payment gateway later).
2. Deployment and environments: local, staging, production; CI/CD path; how one Edge Function is deployed or fails without affecting others.
3. Domain model: a class diagram per area (tenancy and branches, staff and shifts, catalogue, clients, appointments, sales and payments, settings) and one ER diagram per area with keys, tenant_id/branch_id and the main constraints (exclusion constraints, composite foreign keys).
4. Sequence diagrams for: sign-in and tenant/branch selection; creating a booking (including the double-booking guard); rescheduling across branches (price re-resolution); check-in and checkout with cash; refund by a manager; end-of-day cash-up; tenant onboarding; an Edge Function call showing JWT verification, tenant checks, idempotency and error format.
5. State diagrams for: appointment, sale, payment, refund, staff shift, tenant (trial/active/suspended) where applicable.
6. Security model: a diagram and table of roles x actions x enforcement point (RLS policy, RPC, Edge Function), and the tenant isolation attack paths from round 2 with how each is closed.
7. Data access map: for every MVP write path, whether it goes through supabase-js under RLS, an RPC, or an Edge Function, and why.
8. Residual issues found while doing the above.
