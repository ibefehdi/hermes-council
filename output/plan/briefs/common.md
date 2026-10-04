# Planning pass: rules for every council member

The council has already reverse-engineered the Fresha partner dashboard. Now it designs a new product built on that understanding, and writes the phase-based implementation plan plus the coding conventions (as Cursor and Claude skills) the build team will follow.

## Inputs (read-only)

- /Users/fahad/council/output/FINAL_REPORT.md: product-level map (modules, pages, features, journeys)
- /Users/fahad/council/output/TECHNICAL_REPORT.md: technical reference (data model, flows, lifecycles, settings, reports, API catalogue)
- /Users/fahad/council/output/technical/*.md: detailed worker files behind the technical report

Never edit these. Use them for functional understanding only. This is a clean-room design: do not copy Fresha's UI, copy text, branding, or API shapes. Design our own domain model and API from the requirements.

## The product

- Multi-tenant SaaS for spas and salons, sellable to many companies. Tenant = company. First tenant: SpaCorner (Kuwait).
- A tenant has multiple branches. Each branch has its own staff, opening hours, services (and per-branch price/duration), resources/rooms, and schedule. Staff may work at more than one branch. Clients belong to the tenant and can visit any branch.
- Roles at least: platform admin (us), tenant owner, branch manager, receptionist/front desk, staff/therapist. Data must never leak between tenants, and branch-scoped roles see only their branches.
- MVP (first release for SpaCorner) = core operations: tenant and branch setup, staff and shifts, service catalogue with branch overrides, clients, calendar and booking, checkout with cash/manual payments, sales records, basic reports. Online payments, client-facing online booking, marketing, inventory, loyalty, memberships come in later phases.
- Languages: English and Arabic with full RTL from day one. Currency KWD (3 decimal places) by default, but tenants may use other currencies. Time zone per branch (default Asia/Kuwait).
- Payments: cash/manual in MVP. Choose and justify the online gateway for a later phase (consider KNET support in Kuwait: e.g. Tap, MyFatoorah, others).

## The stack (fixed)

- Supabase: Postgres, Auth, Row Level Security, Storage, Realtime, Supabase CLI migrations.
- All server-side logic runs as Supabase Edge Functions (Deno, TypeScript). Requirement from the owner: functions must be isolated so that a failing or redeploying function never takes down the rest of the product. Decide function granularity, shared code, and when the frontend may use the Supabase client (PostgREST/RPC under RLS) directly versus calling an Edge Function, and justify it.
- Frontend: React with TypeScript. The visual design language comes from the owner's separate "Airbnb" design skill, so do NOT define colours, typography, or visual style. Do define frontend architecture, structure, data access, state, forms, i18n/RTL, accessibility, testing, and how components consume the design skill.

Check current capabilities and limits of Supabase Edge Functions, Auth hooks, RLS, pg_cron/queues, and Realtime with web search and official docs instead of relying on memory, and cite the source URL for anything that drives a decision.

## Decisions

Record every significant choice in your own output file under a "Proposed decisions" section, one entry per decision:

```
### PD-<area>-<n>: <title>
- Context: why this needs deciding
- Options considered: at least two, with trade-offs
- Proposal: the choice
- Consequences: what it implies for the other areas (DB, backend, frontend, ops)
```

The verifier challenges these and the chair rules on each one in decisions.md.

## Skill drafts

Each worker drafts one or more convention skills into /Users/fahad/council/output/plan/skill-drafts/<skill-name>.md, following the format in /Users/fahad/council/output/plan/briefs/skill-format.md. The chair finalises them.

## Output discipline

Write to the file your brief names in /Users/fahad/council/output/plan/. Write incrementally (section by section) so work survives a crash; on restart, read your file and continue. Use Mermaid for diagrams and validate with `node /Users/fahad/council/check-mermaid.mjs <file>`.
