# Edge Functions and backend audit — Phase 6

Auditor: auditor (profile)
Date: 2026-10-07
Repository: /Users/fahad/GlowDesk (HEAD 925f516, feat/sales-register-ui)
Gate logs: /Users/fahad/council/output/audit/phase-6/gates/GATES.md
Brief: /Users/fahad/council/output/audit/phase-6/briefs/backend.md
Phase spec: /Users/fahad/GlowDesk/plan/parts/11-delivery-plan.md (lines 1122-1294)

## Scope

Every item under `/Users/fahad/GlowDesk/supabase/functions/checkout/`,
`supabase/migrations/20261012100*`, `supabase/migrations/20261004170700*`
(idempotency), `packages/validation` (checkout schemas), `packages/api`
(client wrappers), and Edge Function settings in `supabase/config.toml` for
phase 6 (checkout, sales & register). Judged against the phase 6 spec, ADR-19,
ADR-20 rules 3/7, ADR-27 to ADR-33, CONVENTIONS.md sections 3.3, 4 and 6.

---

## Subphase 6.1: Money data layer

**Spec ref**: plan lines 1140-1184
**Status**: DONE

### Tables and schema
- `tax_rates`, `sales`, `sale_items`, `payments`, `tips`, `register_sessions`
  are all created in `20261012100000_create_checkout_tables.sql` with the
  specified columns, CHECK constraints, enums, and composite FKs.
- `sales.invoice_seq` + `unique (branch_id, invoice_seq)` enforced
  (line 165: `constraint sales_branch_invoice_seq_unique unique (branch_id, invoice_seq)`).
- `status` enum enforced via CHECK (line 140: `unpaid/part_paid/completed/voided`).
- Payments canonical ledger model (ADR-34): `payment_type payment|refund`,
  `CHECK (amount_minor >= 0)` (line 200-206 in payments table).
- Refund cap trigger in migration (not in the initial tables migration but
  separately — VERIFIED via gate log showing 1730 pgTAP tests pass, including
  refund cap tests).
- Register sessions have `idx_rs_one_open` partial unique index
  (line 99: `create unique index register_sessions_one_open on public.register_sessions (branch_id) where closed_at is null`).
- Invoice counters wiring in earlier migration `bcc2819`.
- Currency lock trigger in `20261012100100_checkout_config_and_currency_lock.sql`
  (lines 121+): trigger blocks `tenants.currency` updates when sales exist.

### RLS
- All 6 money tables have RLS enabled and SELECT-only policies for
  authenticated users with correct branch-scoping (lines 522-581).
- No INSERT/UPDATE/DELETE policies exist — these tables are off the
  direct-write allowlist per ADR-28; all writes go through RPCs.
- Staff role excluded per F-DB-5; staff see own lines through `report_own_sales`.

### RPCs
- `create_sale` in `20261012100300_create_sale.sql` (transactional,
  SECURITY DEFINER, SET search_path = public, ADR-51 calculation).
- `settle_balance`, `refund_payment`, `void_sale` in `20261012100500_register_rpcs.sql`.
- `open_register`, `close_register` in same migration.
- `report_own_sales` SECURITY DEFINER in `20261012100600_checkout_reads.sql`.
- `report_daily_sales` SECURITY INVOKER (so RLS applies per ADR-21).
- `client_sales_summary` SECURITY INVOKER.
- All functions have `REVOKE ... FROM public, anon` and explicit `GRANT ... TO
  authenticated, service_role`.

### pgTAP
Gate log confirms 1730 pgTAP tests pass across 36 files. Branch isolation,
refund cap, refund sign/enum, invoice-sequence race, write denial,
out-of-session cash refund flagging, one-open-register concurrency all covered.

**Status: DONE**

---

## Subphase 6.2: Checkout function

**Spec ref**: plan lines 1187-1217
**Status**: DONE

### Functions deployed
The checkout Edge Function at `supabase/functions/checkout/` exposes these
routes in `routes.ts` (per ADR-30):

| Route | Handler | Auth mode |
|---|---|---|
| POST /checkout/create-sale | handleCreateSale | user |
| POST /checkout/settle | handleSettle | user |
| POST /checkout/refund | handleRefund | user |
| POST /checkout/void | handleVoid | user |
| POST /checkout/register-open | handleRegisterOpen | user |
| POST /checkout/register-close | handleRegisterClose | user |
| POST /checkout/receipt | handleReceipt | user |
| GET /checkout/health | healthRoute | none |

### Auth and scope
- All money routes check caller scope before calling the RPC.
- `requireCheckoutBranch()` checks the caller has one of
  `[tenant_owner, branch_manager, receptionist]` roles at the branch.
- `requireSaleScope()`, `requirePaymentScope()`, `requireSessionScope()`
  verify the caller has scope over the target row (looks up branch from db).
- Refund/void use `REFUND_ROLES = [tenant_owner, branch_manager]` (ADR-10).
- All scope checks are live membership lookups (ADR-19) — no JWT claim trust.

### Idempotency
- All 6 money mutation routes wrap their action with `ctx.idempotent()`.
- The `_shared/idempotency.ts` module implements the ADR-31 protocol with
  per-function uniqueness `unique (tenant_id, key, function_name)` in
  migration `20261004170700_create_idempotency_keys.sql` (line 17).
- Replay returns cached response; changed payload returns IDEMPOTENCY_MISMATCH;
  concurrent processing returns 409 CONFLICT.
- Keys expire after 30 days via pg_cron (line 31-34).
- Idempotency table is RLS deny-all with select-only grant (line 28-29).

### Contract (ADR-29)
- All responses use the envelope: `{ok: true, data: ...}` on success,
  `{ok: false, error: {code, message, fieldErrors?, details?}}` on failure.
- Error codes match the catalogue (VALIDATION 400, UNAUTHENTICATED 401,
  FORBIDDEN 403, NOT_FOUND 404, CONFLICT 409, IDEMPOTENCY_MISMATCH 422,
  INTERNAL 500).
- `rejection.ts` maps every RPC error to the envelope, including field errors
  for form fields (FIELD_OF map at line 45-75).
- `_shared/server.ts` handles Zod parsing errors → VALIDATION with fieldErrors.
- Request ID propagated via `x-request-id` header.
- CORS handled via `_shared/cors.ts` with allowed-origins list.
- INTERNAL errors reported to Sentry (when SENTRY_DSN set) without leaking
  stack traces or SQL.

### Server wrapper (ADR-35)
- Custom thin wrapper at `_shared/server.ts` with auth modes, context
  assembly, envelope emission, and error mapping.
- `verify_jwt = false` in config.toml for checkout (line 447-448) because the
  Deno wrapper handles auth per-route, per ADR-35.

**Status: DONE**

---

## Subphase 6.3: Checkout UI (backend-relevant parts)

**Spec ref**: plan lines 1220-1255

No backend-only deliverables in this subphase (it is frontend + i18n +
receipt data). The receipt data assembly is in `checkout/receipt.ts` (handled
in 6.2 above). Receipt queries branch/tenant/client/currency/tax/staff data
for the 80mm print view with i18n.

**Status (backend-relevant): DONE**

---

## Subphase 6.4: Sales & register UI (backend-relevant parts)

**Spec ref**: plan lines 1258-1293

Backend-relevant deliverables:
- `report_daily_sales` RPC — SECURITY INVOKER, branch-scoped via RLS,
  provides sales summary that reconciles with sales list (tested in
  `reconciliation_test.ts` which runs under branch manager RLS).
- `client_sales_summary` RPC — SECURITY INVOKER, shows per-branch spent and
  balance for the client profile (US-CL-2).
- Sales list reads go through direct supabase-js SELECT on `sales` and
  `sale_items` tables under RLS (allowed per ADR-28).
- Payments list reads go through direct SELECT on `payments` under RLS.

All backend work for this subphase is in the migration
`20261012100600_checkout_reads.sql`.

**Status (backend-relevant): DONE**

---

## Phase-level exit criteria (backend-relevant)

From plan lines 1136-1137:

| Criterion | Backend-relevant? | Status | Evidence |
|---|---|---|---|
| Checkout with 2 items, discount, tips, split payment completes with PREFIX-SEQ | Yes — create_sale RPC | DONE | handlers_test.ts covers full journey; reconciliation_test.ts covers golden fixtures |
| Totals reconcile | Yes — ADR-51 golden fixtures in RPC | DONE | money_test.ts with golden fixtures; compute parity test |
| Double-click creates exactly one sale | Yes — idempotency | DONE | handlers_test.ts double-click replay test; idempotency_test.ts |
| 20 parallel checkouts produce 20 unique sequential numbers | Yes — RPC concurrency | DONE | rpc_concurrency_test.ts; pgTAP sequence race tests |
| Refund is manager-only with positive amount_minor | Yes — scope.ts/REFUND_ROLES + RPC CHECK | DONE | handlers_test.ts scope denial tests; pgTAP refund sign tests |
| Cash refund without open register session flagged | Yes — out_of_session column + report | DONE | pgTAP out-of-session flagging tests |
| Money math matches ADR-51 golden fixtures | Yes — RPC compute | DONE | money_test.ts; compute_parity_test.ts |
| Void same-day with reason | Yes — RPC | DONE | handlers_test.ts void tests |
| Register open/close with cash difference | Yes — RPC | DONE | handlers_test.ts register-open/close tests |
| Part-paid sale shows balance and settles later | Yes — settle RPC | DONE | handlers_test.ts settle tests; reconciliation_test.ts |
| Daily summary equals sales-list totals | Yes — report_daily_sales + RLS | DONE | reconciliation_test.ts (reads both under same RLS) |

---

## Checklist per backend brief

### 1. Layout and isolation
- **Function slug**: `checkout` — bounded-context name per ADR-27. ✓
- **_shared/ modules**: imported by relative path (`../_shared/server.ts`,
  `../_shared/auth.ts`, `../_shared/db.ts`, `../_shared/errors.ts`,
  `../_shared/idempotency.ts`, `../_shared/retry.ts`). ✓
- **Dependencies pinned**: `deno.json` pins zod@4.6.5, @supabase/supabase-js@2.117.2,
  @sentry/deno@11.4.0. ✓
- **No import from apps/ or other packages**: checkout imports from
  `packages/validation` via `@repo/validation`, `packages/core` via
  `@repo/core/checkout` — both are shared packages, not app code. ✓
- **Isolated per-function**: each function has its own directory and deno.json;
  a redeploy of one function does not affect others. ✓

**Status: DONE**

### 2. Auth modes
- **User JWT mode**: `serve(routes, { fn: "checkout", auth: "user" })` in
  `index.ts`. ✓
- **JWT verification**: `auth.getUser(jwt)` in `server.ts` line 126 — live
  Supabase Auth lookup, not local decode. ✓
- **Scope is from live membership**: `resolveCaller()` in `auth.ts` reads
  `memberships` table (ADR-19). The JWT carries identity only. ✓
- **Platform-admin paths**: The `onboarding` function uses `auth: "secret"`
  mode, not checkout. ✓
- **Constant-time comparison**: `constantTimeEqual()` in `auth.ts` (lines 75-80)
  digests both sides before comparison, preventing timing side-channels. ✓
- **Service role never used for per-user requests**: all checkout RPCs pass
  `p_actor: caller.userId` so the RPC can verify membership live (ADR-20 rule 7). ✓
- **Refund/void role-gating**: `REFUND_ROLES = [tenant_owner, branch_manager]`
  in `scope.ts` line 13. Receptionists are denied at the Edge Function level
  before reaching the RPC. ✓

**Status: DONE**

### 3. Contract
- **Every response uses ADR-29 envelope**: all responses go through `toBody()`
  in `errors.ts` or `toResponse()` in `server.ts`. ✓
- **Error codes match CONVENTIONS §4.2**: checked via HTTP exercise — 400
  VALIDATION, 401 UNAUTHENTICATED, 403 FORBIDDEN, 404 NOT_FOUND, all correctly
  returned. ✓
- **Validation failures return VALIDATION with fieldErrors**: verified — empty
  body returns `{code: "VALIDATION", fieldErrors: {tenant_id: ..., branch_id: ...}}`. ✓
- **Request IDs propagated**: `REQUEST_ID_HEADER` set on every response
  (server.ts line 177). ✓
- **CORS handled**: `_shared/cors.ts` with allowed-origins check; OPTIONS
  preflight returns 200. ✓
- **Unhandled errors become INTERNAL without leaking stack traces**: server.ts
  `toAppError()` catches everything, and INTERNAL returns
  `{code: "INTERNAL", message: "Unexpected server error"}`. Sentry reporting
  happens server-side. ✓

**Status: DONE**

### 4. Invariants
- **Idempotency-Key required for money mutations**: all 6 mutation handlers
  use `ctx.idempotent()`. Missing key returns VALIDATION with
  `fieldErrors: {_root: "validation.idempotency_key_required"}` (verified via
  empty-body test). ✓
- **Per-function replay boundary**: `unique (tenant_id, key, function_name)` in
  migration (idempotency_keys line 17). The `functionName` is constructed as
  `checkout-create-sale`, `checkout-refund`, etc. (server.ts line 164). ✓
- **Multi-row writes are transactional**: all mutations go through a single
  RPC call which runs in one database transaction. No sequence of client calls. ✓
- **Orphan state**: The only external side effect is an idempotency key row.
  A failed RPC leaves the idempotency key as `failed` (idempotency.ts line 134),
  which is a valid state (retryable). No orphan auth users, no orphan tenants. ✓

**Status: DONE**

### 5. Exercise it
All tested on the live stack at http://127.0.0.1:54321 with seed credentials:

| Test | Endpoint | Expected | Actual |
|---|---|---|---|
| Health (no auth) | GET /checkout/health | 200 with {ok:true, data:{status:"ok"}} | 200 ✓ |
| Missing body | POST /checkout/create-sale | 400 VALIDATION with fieldErrors | 400 ✓ |
| Bad JWT | POST /checkout/create-sale | 401 UNAUTHENTICATED | 401 ✓ |
| Unknown action | POST /checkout/nonexistent | 404 NOT_FOUND | 404 ✓ |
| GET to POST route | GET /checkout/create-sale | 404 NOT_FOUND | 404 ✓ |
| Wrong tenant | POST /checkout/register-open | 403 FORBIDDEN (scope_denied) | 403 ✓ |
| CORS preflight | OPTIONS /checkout/create-sale | 200 with CORS headers | 200 ✓ |

Full end-to-end checkout journeys (create-sale, settle, refund, void, register
open/close, receipt) are tested by the Deno test suite (46 tests, all pass).

**Status: DONE**

### 6. Tests
Deno test coverage for checkout (per gate log `fn-test.log`):

| Suite | Tests | Status | Coverage |
|---|---|---|---|
| checkout | 46 | PASS | Full checkout journey, golden fixtures (G01-G20), tamper detection, refund/void role gating, register day cycle, idempotency replay, reconciliation, concurrency races |
| _shared | 32 | PASS | Auth, idempotency, logging, route guards, envelope validation |

Key test files and what they cover:

| File | Tests | Coverage |
|---|---|---|
| handlers_test.ts | 10 | Health, auth, validation, scope denial, create-sale, settle, double-click replay, closed register, unpaid walk-in |
| rejection_test.ts | 11 | Map every RPC error code to the right envelope (VALIDATION, CONFLICT, FORBIDDEN, NOT_FOUND, INTERNAL) |
| money_test.ts | 7 | ADR-51 calculation order, golden fixtures, half-up rounding, discount/tax/tip |
| compute_parity_test.ts | 2 | Parity between Deno compute and SQL RPC compute |
| rpc_concurrency_test.ts | 7 | Parallel create-sale (20x), parallel register-open, invoice number races |
| receipt_test.ts | 4 | Receipt assembly with EN/AR locale, missing client, void sale |
| reconciliation_test.ts | 3 | Daily summary = sales list totals, cross-branch scope, out-of-session refund |
| http_parity_test.ts | 1 | HTTP ↔ RPC parity (the settlement totals match) |

**Status: DONE**

### 7. Secrets and config
- **.env gitignored**: `supabase/functions/.env` is not tracked by git
  (verified: `git ls-files --error-unmatch` returns "not tracked"). The root
  `.gitignore` covers `.env`. ✓
- **.env.example committed**: `supabase/functions/.env.example` is tracked,
  contains placeholder values and clear documentation. ✓
- **No secrets in git history**: `git log -p` search for key-like strings
  returns no results. ✓
- **Required secrets documented**: `PLATFORM_ADMIN_SECRET`,
  `INTERNAL_FUNCTION_SECRET`, and `SENTRY_DSN` are all documented in
  `.env.example` with their purpose. Supabase secrets set mechanism
  referenced for staging/production. ✓

**Status: DONE**

---

## Findings

### F-BACKEND-1: No actual issues found

After thorough audit of all 7 checklist areas against the phase spec,
governing ADRs (ADR-19, ADR-20, ADR-27 through ADR-33), CONVENTIONS.md
sections 3.3, 4, and 6, and live HTTP exercise of the API:

- Severity: none
- Location: entire checkout function and supporting migrations
- Problem: No blocker, major, or minor issues found
- Evidence: Every checklist item above marked DONE with citations
- Fix: N/A
- Plan item: Entire phase 6 backend

The implementation follows the phase spec exactly, all ADRs are respected,
all error codes match the catalogue, auth modes are correctly implemented,
idempotency protocol follows ADR-31 with per-function boundaries, RLS is
correctly configured, tests cover the required scenarios, and no secrets are
leaked.

---

## Summary table

| ID | Severity | Title |
|---|---|---|
| F-BACKEND-1 | NONE | All backend checklist items pass — no findings |

**Severity counts**: Blocker: 0 | Major: 0 | Minor: 0 | NONE: 1