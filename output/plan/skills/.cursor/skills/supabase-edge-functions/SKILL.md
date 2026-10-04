---
name: supabase-edge-functions
description: Use when creating, editing, or deploying Supabase Edge Functions (Deno) for the spa/salon SaaS. Covers bounded-context function layout, the _shared server wrapper and auth modes, live-membership tenant context (never JWT claims), the response envelope and error codes, Zod validation shared with the frontend, idempotency for money mutations, pg_cron/pgmq async work, testing with deno test, and deploy commands.
---

# Supabase Edge Functions

Rules follow ADR-19/24/27/28/29/30/31/32/33/35. One function per bounded context; MVP functions: `bookings`, `checkout`, `catalogue`, `clients`, `staff`, `reports`, `onboarding` (plan Phase 9 adds `notifications`, `webhooks`, `online-booking`). There is no `auth-hook` function (ADR-19).

## Layout

```
supabase/functions/
  _shared/
    server.ts        # our thin wrapper: auth modes, ctx assembly, envelope, error mapping
    auth.ts          # live membership/scope resolution (NOT JWT claims)
    db.ts            # user-scoped + service-role client factories
    errors.ts        # AppError + code catalogue (mirrors packages/validation)
    idempotency.ts   # Idempotency-Key handling against idempotency_keys
    logging.ts       # structured JSON logs, request IDs
    cors.ts
  bookings/
    index.ts         # Deno.serve + wrapper
    routes.ts        # action -> handler map
    handlers.ts
    deno.json        # import map, pinned versions
```

Each function folder is independently deployable (NFR-2). Imports: `_shared/` by relative path; shared Zod schemas from `packages/validation` via its Deno-compatible export (never duplicate schemas, never import from `apps/`); third-party via pinned `npm:` specifiers in `deno.json`. `_shared` holds **no mutable module-level state**; a `_shared` change redeploys all functions in one CI run and gets stricter review (ADR-32).

## Entry point and routing (ADR-30, ADR-35)

We use our own `_shared/server.ts` wrapper - not an unpinned third-party snippet. Public shape is `/<function>/<action>`:

```ts
// supabase/functions/bookings/index.ts
import { serve } from '../_shared/server.ts'
import { routes } from './routes.ts'

serve(routes, { auth: 'user' })
// POST /functions/v1/bookings/create | /reschedule | /cancel | /set-status | /slots ...
// GET  /functions/v1/bookings/health   (auth: 'none')
```

Auth modes: `user` (validates the caller's JWT, provides RLS-scoped + admin clients), `secret` (cron/pg_net/inter-function calls, shared secret, admin client only), `none` (health checks, external webhooks that verify signatures themselves). The frontend only ever calls these paths through `packages/api` typed wrappers.

## Tenant context: live lookup, never JWT claims (ADR-19)

The JWT gives you `auth.uid()` - identity, nothing else. Resolve tenant/role/branch scope from `memberships` per request:

```ts
// _shared/auth.ts
export interface CallerContext {
  userId: string
  memberships: { tenantId: string; role: AppRole; branchIds: string[] | 'all' }[]
}
export async function resolveCaller(admin: SupabaseClient, userId: string): Promise<CallerContext>

export function requireScope(caller: CallerContext, tenantId: string, branchId?: string,
  roles?: AppRole[]): void // throws AppError FORBIDDEN
```

Handlers take the target `tenant_id`/`branch_id` from the request, then `requireScope(...)` before any privileged step. Body values are cross-checked against derived scope, never trusted. Multi-tenant users are normal: scope every statement of the transaction to the verified tenant. Do not add tenant claims to tokens; if a Custom Access Token hook is ever adopted it is a non-authoritative cache only (deferred, ADR-19).

## Database access

| Situation | Client | Rule |
|---|---|---|
| Reads on behalf of the user | user-scoped (forwards the caller's JWT) | RLS filters tenant/branch |
| Privileged transactional writes | service role **inside RPCs** | Prefer `supabase.rpc('book_appointment', ...)` etc.: the RPC does scope checks, advisory locks, constraints, audit (ADR-24). Raw service-role table writes are the exception and must filter `tenant_id`/`branch_id` derived from `requireScope` on every statement |
| Cron/webhook | admin only (`auth: 'secret'` / signature-verified) | No user context; idempotent by design |

Money mutations (checkout create-sale/settle/refund/void, register open/close, webhook captures) require the `Idempotency-Key` header and use `_shared/idempotency.ts` against the `idempotency_keys` table (unique `(tenant_id, key)`; replay returns the cached response; `processing` collision → 409) (ADR-31).

## Validation

One Zod schema per operation, imported from `packages/validation` (pure JS so Deno and the browser share it). Parse before anything else; parse failures become `VALIDATION` with `fieldErrors`. Zod is shape-defense only - authorization always comes from `requireScope` + RLS/RPC checks (ADR-39). IDs are UUID strings; money fields are integers (`z.number().int().nonnegative()`) in minor units.

## Envelope and errors (ADR-29)

Success `{ ok: true, data }`; failure `{ ok: false, error: { code, message, fieldErrors?, details? } }`. One catalogue (defined in `packages/validation`, mirrored in `_shared/errors.ts`):

| Code | HTTP |
|---|---|
| `VALIDATION` | 400 |
| `UNAUTHENTICATED` | 401 |
| `FORBIDDEN` | 403 |
| `NOT_FOUND` | 404 |
| `CONFLICT` | 409 (double-booking; include `details.conflicting_appointment_id` and suggested times) |
| `IDEMPOTENCY_MISMATCH` | 422 |
| `RATE_LIMITED` | 429 |
| `INTERNAL` | 500 |
| `UNAVAILABLE` | 503 |

Throw `AppError(code, message, status, details?)`; the wrapper maps to the envelope, logs one structured error line, and reports 5xx to Sentry. `message` is English/developer-facing; the frontend translates by code. Never leak stack traces or SQL to clients.

## Logging, limits, timeouts

- One structured JSON line per request (`event: 'request'|'response'|'error'`, method, path, tenantId, userId, requestId); request IDs threaded through nested calls; ≤10k chars per line; no per-row logging (100 events/10s threshold).
- Platform limits shape the design: 256MB memory, 2s CPU/request (push computation into SQL), 150s/400s wall clock (background work goes to queues), bundle size 20MB CLI-bundled (local) / 5MB server-side bundled (keep `_shared` lean) — round 2, F-BE-1: both documented limits, per https://supabase.com/docs/guides/functions/limits.
- Handler timeouts: 30s user-facing, 120s cron; long jobs (exports, imports) enqueue to pgmq and return immediately (ADR-33). Queue consumers are idempotent - pgmq delivery is at-least-once within the visibility window.

## Async and scheduled work (ADR-33)

pg_cron → pg_net → function with `auth: 'secret'`; queues via Supabase Queues (pgmq): import/export jobs in MVP, notifications/webhooks plan Phase 9+. No Supabase Database Webhooks in MVP. Failed messages land in the archive queue; the ops runbook covers inspection and replay.

## Testing

```bash
supabase start
deno test --allow-all supabase/functions/          # all
deno test --allow-all supabase/functions/bookings/ # one context
```

Per-handler tests against the local stack with seeded fixtures: envelope contract, validation rejection, scope denial (wrong tenant/branch/role → FORBIDDEN), idempotency replay, and the booking concurrency cases (two parallel creates for one staff/slot → exactly one success, one `CONFLICT`). CI also imports `packages/validation` from Deno to prove the shared-schema contract.

## Local run and deploy

```bash
supabase functions serve --env-file supabase/.env.local   # hot reload, http://localhost:54321/functions/v1/<name>
supabase secrets set PROVIDER_API_KEY=***              # naming per CONVENTIONS §3.3
supabase functions deploy --use-api                         # all functions (CI)
supabase functions deploy --slug bookings --use-api         # single-function rollback
```

Deploy order in CI: migrations first, then all functions, then frontend - same commit (ADR-30). Every function exposes `GET /health` (`auth: 'none'`) checked by the external monitor.
