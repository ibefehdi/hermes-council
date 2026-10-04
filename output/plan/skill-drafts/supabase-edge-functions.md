---
name: supabase-edge-functions
description: Use when creating, editing, or deploying Supabase Edge Functions for the spa/salon SaaS. Covers file layout, shared modules, request/response conventions, auth and tenant context extraction, input validation with zod, database access rules, idempotency, error model, testing with deno test, local run with supabase functions serve, and deploy commands.
---

# Supabase Edge Functions

## Quick start: creating a new function

```bash
# 1. Create the function directory (slug must match function name)
mkdir -p supabase/functions/my-function

# 2. Create deno.json with imports
cat > supabase/functions/my-function/deno.json << 'EOF'
{
  "imports": {
    "npm:@supabase/server@1": "npm:@supabase/server@1",
    "npm:zod@3": "npm:zod@3"
  }
}
EOF

# 3. Create index.ts
cat > supabase/functions/my-function/index.ts << 'ENDFUNC'
import { withSupabase } from 'npm:@supabase/server@1'
import { handleRequest } from '../_shared/routes.ts'

const routes = {
  '/health': {
    'GET': async (_req, ctx) => {
      return new Response(JSON.stringify({ status: 'healthy' }), {
        headers: { 'Content-Type': 'application/json' },
      })
    },
  },
}

export default {
  fetch: withSupabase({ auth: 'user' }, async (req, ctx) => {
    return handleRequest(req, ctx, routes)
  }),
}
ENDFUNC

# 4. Run locally
supabase functions serve --env-file supabase/.env.local
```

## File layout

Each function is a directory under `supabase/functions/<name>/` containing:
- `index.ts` — entry point with `withSupabase` wrapper
- `routes.ts` — internal route definitions (path + method -> handler map)
- `handlers.ts` — per-route handler logic (thin, delegates to services or DB calls)
- `deno.json` — import map for npm: specifiers

Shared modules live in `supabase/functions/_shared/` and are imported with relative paths:
```typescript
import { getTenantContext } from '../_shared/auth.ts'
import { AppError } from '../_shared/errors.ts'
import { corsResponse } from '../_shared/cors.ts'
import { log } from '../_shared/logging.ts'
```

## Import rules

- Use `npm:` specifiers for third-party packages (zod, @supabase/server, @sentry/deno)
- Use relative imports for `_shared/` modules — do NOT use import maps for them
- Do NOT import from the frontend (`src/`) — functions have their own types; duplicate shared types in `_shared/types.ts` if needed
- Deno standard library when necessary: `https://deno.land/std@0.224.0/...` or `jsr:@std/...`
- Run `deno cache` on deps in CI to speed up cold starts

## Auth modes

The `withSupabase` wrapper from `npm:@supabase/server@1` accepts four auth modes:

| Mode | `verify_jwt` | Use for | ctx provides |
|---|---|---|---|
| `{ auth: 'user' }` | `true` (default) | User-facing endpoints | `ctx.supabase` (RLS-scoped), `ctx.supabaseAdmin` (service role), `ctx.userClaims`, `ctx.jwtClaims` |
| `{ auth: 'secret' }` | `false` | Cron jobs, pg_net, inter-function calls | `ctx.supabaseAdmin` only |
| `{ auth: 'secret:<name>' }` | `false` | Single-key validation | `ctx.supabaseAdmin` only; only that key passes |
| `{ auth: 'none' }` | `false` | Health checks, external webhooks (verify signature manually) | No Supabase clients pre-configured |

## Tenant context extraction

ALWAYS extract tenant info from JWT claims, NEVER from the request body:

```typescript
import { getTenantContext } from '../_shared/auth.ts'

async function handler(req: Request, ctx: SupabaseContext) {
  const tenant = getTenantContext(ctx)
  // tenant = { tenantId: number, branchIds: number[], role: string, userId: string }

  // CORRECT: use tenant.tenantId for all DB queries
  const { data } = await ctx.supabaseAdmin
    .from('clients')
    .select('*')
    .eq('tenant_id', tenant.tenantId)  // <-- from JWT, not body

  // WRONG (never do this):
  // const tenantId = body.tenant_id
  // const { data } = await ctx.supabase.from('clients').select('*').eq('tenant_id', tenantId)
}
```

## Database access

| Operation | Client | Rule |
|---|---|---|
| Simple reads through RLS | `ctx.supabase` | Trust RLS for tenant/branch filtering |
| Single-table writes through RLS | `ctx.supabase` | Use when RLS policy covers the operation |
| Multi-table transaction | `ctx.supabaseAdmin` | ALWAYS include `.eq('tenant_id', tenant.tenantId)` in every query |
| Any write with side effects | `ctx.supabaseAdmin` | Notification, audit, external API |

When using `supabaseAdmin`, you are responsible for tenant isolation. The service role bypasses RLS. Every query MUST filter by `tenant_id` and (for branch-scoped operations) `branch_id`.

## Error conventions

Throw `AppError` from `_shared/errors.ts`, never raw strings:

```typescript
throw new AppError('CONFLICT', 'Time slot unavailable', 409, {
  conflicting_appointment_id: 123,
  suggested_times: ['2026-10-05T11:00:00+03:00'],
})
```

Available error codes and their HTTP status:
- `VALIDATION_ERROR` — 400
- `UNAUTHORIZED` — 401
- `FORBIDDEN` — 403
- `NOT_FOUND` — 404
- `CONFLICT` — 409
- `IDEMPOTENCY_MISMATCH` — 422
- `RATE_LIMITED` — 429
- `INTERNAL_ERROR` — 500
- `SERVICE_UNAVAILABLE` — 503

Every error response follows this shape:
```json
{
  "error": {
    "code": "CONFLICT",
    "message": "The requested time slot is not available",
    "details": { ... }
  }
}
```

## Idempotency

Mutations involving money (checkout capture, refund, payment webhook processing) MUST accept an `Idempotency-Key` header:

```typescript
const idempotencyKey = req.headers.get('Idempotency-Key')
if (idempotencyKey) {
  const { data: cached } = await ctx.supabaseAdmin
    .from('idempotency_keys')
    .select('status, response')
    .eq('key', idempotencyKey)
    .eq('tenant_id', tenant.tenantId)
    .single()

  if (cached?.status === 'completed') {
    return new Response(cached.response.body, {
      status: cached.response.status,
      headers: cached.response.headers,
    })
  }
  if (cached?.status === 'processing') {
    throw new AppError('CONFLICT', 'Request in progress', 409)
  }

  // Insert processing record before proceeding
  await ctx.supabaseAdmin.from('idempotency_keys').insert({
    key: idempotencyKey,
    tenant_id: tenant.tenantId,
    status: 'processing',
  })
}
// ... after success, update to status='completed' with serialized response
```

## Validation with zod

```typescript
import { z } from 'npm:zod@3'

const CreateClientSchema = z.object({
  first_name: z.string().min(1).max(255),
  last_name: z.string().max(255).optional(),
  email: z.string().email().optional(),
  phone: z.string().optional(),
  branch_id: z.number().int().positive(),
})

// In handler:
const body = CreateClientSchema.parse(await req.json())
// On parse failure, zod throws — caught by handleRequest and converted to VALIDATION_ERROR
```

## Testing with deno test

```typescript
// supabase/functions/bookings/conflict-check.test.ts
import { assertEquals, assertRejects } from 'https://deno.land/std@0.224.0/assert/mod.ts'

Deno.test('conflict check rejects overlapping booking', async () => {
  // Arrange: insert an existing appointment via supabaseAdmin
  // Act: call conflict check with overlapping time
  // Assert: CONFLICT error returned
})

Deno.test('conflict check allows non-overlapping booking', async () => {
  // Arrange: insert an existing appointment
  // Act: call conflict check with non-overlapping time
  // Assert: no error
})
```

Run: `deno test --allow-all supabase/functions/`

Run a single file: `deno test --allow-all supabase/functions/bookings/conflict-check.test.ts`

Tests use the local Supabase instance (started via `supabase start`). Seed test data in a `beforeAll` hook or via SQL fixtures in `supabase/tests/fixtures/`.

## Local run

```bash
supabase start                      # Start all services (Postgres, Auth, Storage, etc.)
supabase functions serve            # Start Edge Functions runtime with hot reload
# Functions available at http://localhost:54321/functions/v1/<name>

# With specific env file
supabase functions serve --env-file supabase/.env.local
```

## Deploy

```bash
# Deploy all functions (CI recommended)
supabase functions deploy --use-api

# Deploy one function
supabase functions deploy --slug bookings --use-api

# Set secrets before deploy
supabase secrets set TWILIO_API_KEY=sk_xxx
supabase secrets set --env-file supabase/.env.production

# List secrets (values hidden)
supabase secrets list
```

The `--use-api` flag deploys without Docker, works in CI, and handles concurrent deploys safely. Source: https://github.com/orgs/supabase/discussions/33613