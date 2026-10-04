---
name: spa-platform-architecture
description: Architecture map of the multi-tenant spa/salon SaaS (Supabase + Edge Functions + React/TypeScript). Use when deciding where new code lives, how tenancy and branch scoping work, which data path (supabase-js vs Edge Function vs RPC) a feature must use, or how the monorepo, environments, and skills fit together. Trigger terms - new feature, where does this go, tenant, branch, RLS, Edge Function, monorepo, data access.
---

# Platform architecture

Entry point for the GlowDesk spa/salon SaaS codebase. Read this first; the other skills carry the per-area rules. Authoritative rulings live in `plan/decisions.md` (ADR references below); conventions in `plan/CONVENTIONS.md`.

## Stack

- **Supabase**: Postgres (RLS is the security boundary), Auth (JWT = identity only, ADR-19), Realtime (postgres_changes), Queues (pgmq) + pg_cron + pg_net (final round, F-final-db-1), Storage (plan Phase 9+, ADR-43), CLI migrations. Production project region per ADR-48 with a legal verification gate before go-live.
- **Edge Functions**: Deno + TypeScript, one function per bounded context (ADR-27). MVP functions: `bookings`, `checkout`, `catalogue`, `clients`, `staff`, `reports`, `onboarding`.
- **Frontend**: React 18 + TypeScript strict, Vite SPAs, TanStack Router/Query, Lingui (en/ar + RTL), schedule-x calendar. Visual design comes from the owner's **Airbnb design skill** - never define colors/typography/spacing in feature code.

## Tenancy model (the part everything depends on)

- Tenant = company (first tenant: SpaCorner, Kuwait). Branch = physical location with its own hours, staff assignments, service overrides, register, invoice sequence, money records.
- `memberships(user_id, tenant_id, role, branch_id, all_branches, is_active)` is the **only** authorization source. All-branches = `all_branches true` with `branch_id NULL` (the sentinel UUID is withdrawn - ADR-20 rule 6 round 2). Roles: `tenant_owner`, `branch_manager`, `receptionist`, `staff` - the enum has **no `platform_admin`**; platform ops use explicit, time-boxed, audit-logged impersonation rendered as a persistent banner (ADR-20 rule 9). A user may hold memberships in multiple tenants and different roles at different branches.
- Authorization is a **live database lookup** per request via `STABLE SECURITY DEFINER` helpers (`current_tenant_ids()`, `current_branch_scope()`, `has_tenant_role(tenant, roles, branch)`). JWT claims never authorize anything (ADR-19). Membership revocation takes effect immediately - there is a pgTAP test proving it.
- Clients are tenant-scoped (shared across branches); appointments/sales/payments are branch-scoped. Client financial aggregates are branch-scoped via secured RPCs (ADR-11). Client records - including allergies and notes - are intentionally tenant-visible for safety while operational/financial data is branch-scoped (round 2, F-walk-3); the staff role reads only basic client fields via a column-restricted secured view and sees sales only through `report_own_sales` (round 2, F-DB-5/F-perm-2).
- Isolation invariants, each CI-tested: no cross-tenant rows ever; branch-scoped roles never touch other branches' operational/financial rows; archiving a branch never deletes history.

## Repository layout and where code lives

```
apps/back-office        staff/manager/owner SPA (MVP)
apps/booking            public booking app (plan Phase 9, scaffold only)
packages/ui             wraps the Airbnb design skill - ONLY layer touching design tokens
packages/db             generated database.types.ts + createTypedClient
packages/api            typed Edge Function wrappers + ApiError + useRealtime
packages/validation     Zod schemas shared with Deno functions (pure JS, no Node APIs)
packages/i18n           Lingui catalogs (en, ar) + useFormat + Arabic search normalization
packages/core           pure domain logic: slot engine, time math, money math (no React)
supabase/migrations     SQL migrations (never edit an applied one)
supabase/functions      <context>/index.ts + routes + handlers; _shared/ common modules
supabase/tests          pgTAP RLS/integrity tests + fixtures
```

Placement rules:
- SQL schema, RLS, constraints, triggers, report views/RPCs -> `supabase/migrations` (skill: `supabase-database`).
- Cross-table transactions, money, conflicts, side effects, secrets -> Edge Function (skill: `supabase-edge-functions`).
- Screen, query, mutation, form -> `apps/back-office` feature folder (skill: `react-frontend`).
- A rule used by both browser and Deno -> `packages/validation` (Zod) or `packages/core` (pure logic).
- Any user-visible string -> Lingui catalog (skill: `i18n-rtl`). Domain words -> `spa-domain-glossary` first.
- End-to-end delivery of one backlog task -> skill: `feature-delivery`.

## Data access decision (ADR-28; the allowlist is binding)

| Situation | Path |
|---|---|
| Reads (lists, details, calendar, report views/RPCs) | supabase-js under RLS, typed via `packages/db` |
| Simple single-table writes fully expressed by RLS+constraints, on the allowlist (`profiles` self, `client_notes` receptionist+, `clients` contact/profile fields only receptionist+ - never `is_blocked`/`is_deleted`/`merged_into`, `settings`, `shifts`) | supabase-js direct |
| Appointments, sales, payments, register, refunds, memberships, tenants/branches, invoice counters, tips, pricing changes, **blocked times** (locked staff RPC only, round 2 F-DB-6) | Edge Function or SECURITY DEFINER RPC only - **never direct** |
| Heavy aggregation | Postgres RPC (`report_*`), SQL does the work (2s CPU/request limit) |
| Scheduled/background (imports, exports, cleanup) | pg_cron -> Edge Function, pgmq queues, idempotent consumers (ADR-33) |

Booking and checkout mutations run inside transactions that take per-staff advisory locks and rely on exclusion constraints as the final guard (ADR-24). Money is `bigint` minor units (fils) end to end - integers in SQL, Deno, and the browser; formatting only at render (ADR-17).

## Environments and delivery

- Local: `supabase start` + `supabase functions serve` + Vite dev. Staging: Supabase preview branch off `staging`. Production: paid-plan Supabase project, deployed from `main`.
- Frontend and backend deploy from the **same commit** (monorepo rule, ADR-30); migrations deploy before functions.
- CI gates every PR: typecheck (Deno + TS), lint (incl. RTL logical-CSS rule and import boundaries), pgTAP full matrix, Deno tests, Vitest, Playwright critical journeys in en+ar, size-limit budgets, generated-types drift check.
- Observability: structured JSON logs with request IDs, Sentry on both sides, `/health` per function + external uptime monitor.

## Non-negotiables (from the ADRs)

1. RLS on every tenant table; branch-scoped policies on every branch table; no `USING (true)`; no insert policy on `tenants`.
2. Every mutation on clients/appointments/sales/payments/settings/roles writes an audit row (trigger-based, append-only).
3. Envelope `{ ok, data }` / `{ ok, error: { code, message, fieldErrors?, details? } }` and the single error-code catalogue (ADR-29) on every function.
4. `Idempotency-Key` on every money mutation (ADR-31).
5. EN + AR with full RTL is a release gate for every user-facing change (ADR-40).
6. Glossary naming; banned synonyms (`location`, `employee`, `customer`, `booking`-as-record) fail review.

## Skills map

- `spa-domain-glossary` - vocabulary and entity names
- `supabase-database` - migrations, schema, RLS, constraints, pgTAP
- `supabase-edge-functions` - function anatomy, envelope, auth modes, deploy
- `react-frontend` - app/feature structure, queries, mutations, forms
- `i18n-rtl` - Lingui, RTL, formatting, Arabic search
- `feature-delivery` - taking one backlog task from migration to merged PR
