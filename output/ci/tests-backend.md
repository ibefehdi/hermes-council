# Tests-backend: Edge Function tests and contract guards

**Generated:** 2026-10-05T14:15:00+0300
**Repository:** /Users/fahad/GlowDesk (read-only, commit 07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb)
**Sandbox:** /Users/fahad/council/.ci-sandbox/GlowDesk/backend
**Draft:** /Users/fahad/council/output/ci/draft/
**Worker:** auditor (Hermes Agent)

---

## 1. New test: route_guard_test.ts — contract guard for all built routes

### T-backend-1: Route-level contract guards (auth, envelope, CORS, request-id)

- **File:** `draft/supabase/functions/_shared/route_guard_test.ts` (new)
- **Proves:** CONVENTIONS §4.2 (error code catalogue), ADR-29 (envelope), ADR-30 (route naming), CONVENTIONS §8 PR checklist (envelope + error codes used)
- **Closes gap:** G-15 (partial — mutation check documented below), G-16 (partial — mutation check documented below). Additionally provides structural contract guard coverage across all routes.
- **Result at 07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb:** PASSES (9 tests all passing)
- **Runtime:** 19ms (in-process, no network calls)
- **Coverage:**
  - Every route in every built function enumerated from routing tables (`_template`, `catalogue`, `clients`, `onboarding`, `staff`)
  - Auth rejection: each route verifies unauthenticated calls → 401 UNAUTHENTICATED (unless auth: "none" which applies to health only)
  - Health endpoint: each function's auto-added GET /health works without auth and returns `{ ok: true, data: { status: "ok" } }`
  - Envelope contract: each function returns envelope JSON for garbage input (never raw stack trace or SQL text)
  - Unknown routes: 404 NOT_FOUND with envelope
  - Request-ID: inbound x-request-id echoed; auto-generated when absent
  - CORS: allowed origins get CORS headers; denied origins don't; OPTIONS preflight returns 204
  - Error envelope: every error response has `ok=false`, `error.code`, and valid JSON

**How the routes are discovered:**
```typescript
import { routes as templateRoutes } from "../_template/routes.ts";
import { routes as catalogueRoutes } from "../catalogue/routes.ts";
import { routes as clientsRoutes } from "../clients/routes.ts";
import { routes as onboardingRoutes } from "../onboarding/routes.ts";
import { routes as staffRoutes } from "../staff/routes.ts";
```

Each routes.ts file contains the actual route table for its function. When a new route is added to any function's routes.ts, the next test run automatically picks it up — no manual list update needed. When a new function is added, it must be added to the `functions` array in the test.

**Mutation check (G-15 — idempotency replay):** N/A — this is an in-process test of the server framework, not a route-specific test. Mutation check for idempotency replay is documented separately below.

---

## 2. Mutation checks for existing tests

### G-15: Mutation test for idempotency replay

- **Requirement:** ADR-31 — idempotency replay returns cached response on idempotency key reuse
- **Existing test:** `_shared/idempotency_test.ts` — "a completed key replays the cached response without re-running" (line 33), "ctx.idempotent threads the header through the wrapper" (line 104)
- **Mutation:** Commented out the `if (existing.status === "completed")` replay branch in `_shared/idempotency.ts` (lines 93-95)
- **Result:** **2 tests failed:**
  - "a completed key replays the cached response without re-running" — `AppError: A request with this Idempotency-Key is still processing` (CONFLICT instead of replay)
  - "ctx.idempotent threads the header through the wrapper" — second call returns 409 instead of 201 with `idempotent-replayed: true`
- **Status at 07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb:** ALL PASS (after restore)
- **Verdict:** MUTATION PASSES — the existing tests DO fail when the replay guarantee breaks

### G-16: Mutation test for server envelope

- **Requirement:** ADR-29 — envelope contract (`{ ok: true/false, data/error }`)
- **Existing test:** `_shared/server_test.ts` — 16 tests covering envelope, CORS, auth modes, error codes
- **Mutation:** Changed `json()` function in `_shared/server.ts` to wrap responses with `{ success: true, data: body }` instead of the canonical envelope format
- **Result:** **12 of 16 tests failed** — all assertions on envelope shape (`body.ok`, `body.data`, `body.error.code`) broke
- **Status at 07e2a10526bfb5d9f17ebac82bb47d4a5376c4bb:** ALL PASS (after restore)
- **Verdict:** MUTATION PASSES — the envelope contract tests fail when the envelope format changes

### G-15 runtime measurement
From the sandbox, running idempotency_test.ts alone: ~225ms (8 tests). The 2 replay tests combined: ~30ms.

### G-16 runtime measurement
From the sandbox, running server_test.ts alone: ~88ms (16 tests).

---

## 3. Gaps I cannot close

### G-18 (P1): Sentry is not integrated

- **Requirement:** Plan Phase 0.1 — Sentry captures a deliberate error (plan/parts/11-delivery-plan.md:215,230,314-319)
- **Today:** Sentry SDK is imported (`@sentry/deno` in deno.json) but not wired. `_shared/sentry.ts` contains a stub (`defaultReporter`) and `_shared/logging.ts` captureException only logs locally when no SENTRY_DSN is set.
- **Cannot close because:** This is a code gap (missing Sentry transport wiring), not a missing test gap. The Deno tests (`_shared/logging_test.ts`) already test the logger creation and format. Writing a test that verifies Sentry is called would require a mock or a real Sentry DSN, which cannot be provided in the local stack.
- **Action needed:** Wire Sentry SDK in `supabase/functions/_shared/sentry.ts` (set up Sentry.init, make `defaultReporter` actually construct a SentryReporter), then add a Deno test that calls `captureException` with a fake error and verifies the Sentry event was queued.
- **Deferred to:** Future phase (Sentry integration must be wired before tests can be written)

### G-12 (P2): No Deno test for Sentry integration

- **Requirement:** After Sentry integration is wired, add Deno test that forces an error, triggers captureException, and verifies Sentry API was called
- **Cannot close because:** Blocked on G-18 — Sentry must be wired first. The existing `_shared/logging_test.ts` (6 tests, rated WEAK) tests logging format but not Sentry delivery.
- **Action needed:** Once G-18 is resolved, add a Deno test that:
  - Creates a test handler with a custom fake reporter (pattern: `fakeReporter()` in `testing.ts`)
  - Triggers a situation that would call captureException (e.g., an INTERNAL error)
  - Verifies the reporter received the event

---

## 4. Summary table

| ID | File | Proves/Closes | Result at 07e2a105 | Runtime | Notes |
|----|------|---------------|-------------------|---------|-------|
| T-backend-1 | `draft/.../route_guard_test.ts` | CONVENTIONS §4.2, ADR-29, ADR-30, §8 | PASSES (9 tests) | 19ms | New contract guard test for all built routes |
| G-15 mutation | `_shared/idempotency.ts` + `_shared/idempotency_test.ts` | ADR-31 | 2 tests fail on mutation | ~30ms | Mutation verified: replay tests guard the guarantee |
| G-16 mutation | `_shared/server.ts` + `_shared/server_test.ts` | ADR-29 | 12/16 tests fail on mutation | ~88ms | Mutation verified: envelope tests guard the contract |
| G-18 | — | Plan Phase 0.1 exit | NOT CLOSED | — | Sentry not wired; code gap, not test gap |
| G-12 | — | Plan Phase 0.3 | NOT CLOSED | — | Blocked on G-18 (Sentry integration) |

## 5. Gaps assigned to tests-backend that remain open

| Gap | Priority | Reason still open |
|-----|----------|-------------------|
| G-18 | P1 | Sentry SDK not wired — this is a product code gap, not a test gap. No SENTRY_DSN configured, no Sentry.init() call, stub reporter. |
| G-12 | P2 | Blocked on G-18 — cannot write Sentry integration test until Sentry is wired in the codebase. |

---

## 6. Verification

- All existing suites pass with the new test file: `pnpm fn:test` = 7 suites, 0 failed
- Draft validated: `node /Users/fahad/council/check-ci.mjs /Users/fahad/council/output/ci/draft /Users/fahad/GlowDesk` — only pre-existing shellcheck warnings in `.github/workflows/` (not in this worker's scope)
- Mutation checks completed and restored for G-15 and G-16