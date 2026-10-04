---
name: feature-delivery
description: How to implement one backlog task end to end in the spa/salon SaaS - from SQL migration through RLS and pgTAP tests, generated types, Zod schema, Edge Function or RPC, UI screen, tests, to the merged PR. Use when picking up any task tagged DB, Edge Function, Frontend, or Ops in an implementation-plan backlog, when reviewing such a PR, or when asked about the definition of done, commit message format, or PR checklist.
---

# Feature delivery: backlog task to merged PR

One task = one PR (small enough to review in one sitting). Order of work matters: the database and its security come first, the UI last. Skip the steps a task genuinely does not touch (a pure-frontend fix has no migration), but never skip tests for steps you did do.

## The delivery path

### 1. Understand the task
- Read the task's user story and acceptance criteria in `plan/IMPLEMENTATION_PLAN.md` and the ADRs it cites in `plan/decisions.md`. If the task conflicts with an ADR, stop and raise it - ADRs win; they change only by a chair ruling, not in a PR.
- Check `spa-domain-glossary` for every noun in the task. New concept? Add the glossary entry in the same PR, before using the term.

### 2. Migration (tag: DB)
- `supabase migration new <description>`; follow `supabase-database` skill conventions: glossary names, uuid PKs, `tenant_id`/`branch_id` with composite FKs (every FK to a tenant-owned table is composite — ADR-20 rule 5), `_minor bigint` money, `timestamptz`, bilingual `name_en`/`name_ar` where operator-facing, the all-branches representation (`branch_id NULL` + `all_branches` flag + partial unique indexes — never the withdrawn sentinel UUID), `updated_at` trigger, `SET search_path = public` on every SECURITY DEFINER function.
- Constraints before code: CHECK enums (canonical values only), unique indexes (with soft-delete partials where relevant), exclusion constraints for busy-time tables.
- Never edit an applied migration. `supabase db reset` must pass locally.

### 3. RLS + audit (tag: DB, same or follow-up migration)
- Enable RLS; apply the tenant or branch-scoped policy template; role-gate writes per the requirements matrix.
- Decide the write path per ADR-28: allowlisted direct write, or RPC/Edge-Function-only (money, conflicts, cross-table, side effects → RPC-only, select-only RLS). `blocked_times` is RPC-only (locked staff RPC — round 2, F-DB-6); on `clients`, the columns `is_blocked`, `is_deleted`, `merged_into` are function-only even though contact fields are allowlisted (round 2, F-4). Adding a table to the allowlist requires showing the policies/constraints that make it safe in the PR description.
- Audited entities get the audit trigger; `audit_log` DML stays revoked from clients.
- Report-visible data: views get `WITH (security_invoker = true)`; day grouping uses the branch time zone.

### 4. pgTAP tests (tag: DB)
- Per table, per operation, per role (owner / branch manager of A / branch manager of B / receptionist / staff / anon), plus cross-tenant and cross-branch emptiness.
- Behavior tests for the task's invariants: refund cap, invoice-sequence race, exclusion-constraint overlap, revocation immediacy where memberships are touched.
- `supabase test db` green locally; CI runs it on every migration.

### 5. Types + validation (tag: Edge Function / Frontend)
- Regenerate and commit `packages/db/src/database.types.ts` (`supabase gen types typescript --local > ...`). CI fails on drift - never hand-edit.
- Add/extend the operation's Zod schema in `packages/validation` (pure JS, integer money, uuid strings). One schema serves the form and the function; DTO types are `z.infer`.

### 6. Server logic (tag: Edge Function / DB)
- SQL-heavy invariants: SECURITY DEFINER RPC (scope-checked internally, `SET search_path = public`, advisory locks where busy time is written, reconciliation checks where money is written, audit writes inside the transaction).
- Orchestration/external effects: handler in the owning bounded-context function; `requireScope()` before privileged steps; envelope + error catalogue; `Idempotency-Key` on money mutations; heavy work to pgmq, never a long request.
- Deno tests: happy path, validation rejection, scope denial (wrong tenant/branch/role → FORBIDDEN), idempotent replay, concurrency case where applicable.

### 7. UI (tag: Frontend)
- Follow `react-frontend`: feature folder contract, key factories with tenant+branch scope, `queryOptions`, mutations via `@repo/api` wrappers (or allowlisted direct writes), `<AsyncBoundary>`, design-skill primitives from `@repo/ui` only.
- Follow `i18n-rtl`: every string through Lingui, both catalogs updated in the same PR, logical CSS only, money/time via `useFormat()`, RTL checked visually for the screens you touched.
- Accessibility as you build: labels, focus handling, keyboard paths, announced errors.

### 8. Tests (tag: Frontend)
- Vitest for mappers/pure logic (`packages/core` changes need ≥95% coverage; time/money math needs overnight + DST + rounding cases).
- Playwright only for critical-journey changes; if added, it runs in `en` and `ar`.

### 9. PR
- Branch `feat/<area>-<slug>` (or `db/`, `fix/`, `fn/`, `i18n/`, `chore/`). Commit format: Conventional Commits, scope = bounded context or package: `db(bookings): add exclusion constraint on appointment_items busy_range`.
- API-changing PRs include the frontend side (same monorepo, same commit deploys).
- PR description: linked task, ADRs honored, what was tested, allowlist changes (if any), screenshots for UI (en + ar).
- Run `pnpm verify` (typecheck + lint + unit + build) and the relevant `supabase test db` / `deno test` before requesting review.
- Walk the CONVENTIONS.md §8 PR checklist; reviewers enforce it plus the definition of done below.

## Definition of done (CONVENTIONS.md §9)

1. Merged to `staging`; `pnpm verify` and CI green (pgTAP, Deno, Vitest, builds, size limits, types drift).
2. Every new/changed table has RLS + pgTAP coverage with no uncovered matrix cells; Realtime-affecting tables pass channel-authorization tests.
3. Money is integer minor units end to end; anything financial reconciles to the fils in tests.
4. All strings in both catalogs; screen works in RTL; formatting uses the branch time zone.
5. Audit rows written for the mutations; NFRs the task touches have passing tests.
6. Other functions unaffected (isolation); `_shared` changes flagged in the PR (they redeploy everything).
7. Docs/skills updated if a convention changed; glossary updated before first use of a new term.
8. Acceptance criteria demonstrated (Playwright journey or QA note), in both locales where user-facing.

## Common failure modes (from the council's own review)

- Tenant-only policies on branch-scoped tables - branch managers could read sibling branches. Always use the branch template.
- Views without `security_invoker` silently bypassing RLS.
- Check-then-insert conflict logic in triggers (race). Use the exclusion constraint + advisory lock pattern.
- `numeric` money creeping back in, or decimals crossing the API boundary.
- Client-sent `tenant_id`/`branch_id` trusted without `requireScope`.
- A "quick" direct write to a money/booking/blocked-time table because RLS "mostly covers it". The allowlist is binary.
- The withdrawn sentinel branch UUID (`00000000-...`) reappearing in a migration, policy, or helper — all-branches is the `all_branches` flag (ADR-20 rule 6 round 2).
- Arabic copy added later "once it stabilizes". Both locales ship in the same PR or the PR is incomplete.
