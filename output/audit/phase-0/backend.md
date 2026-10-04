# Phase 0 Edge Functions and Backend Audit

Auditor: auditor (profile)
Repository: /Users/fahadasad/glowdesk (read-only, HEAD 2e22eff, branch main)
Gates logs: /Users/fahadasad/hermes-council/output/audit/phase-0/gates/
Date: 2026-10-04

---

## Subphase 0.1: Repository & environments

### Edge Functions: none specified (skeleton in 0.3)
As specified, phase 0.1 requires no Edge Functions. No action needed.

### Repository scaffold
- **DONE**: pnpm monorepo scaffold exists with `apps/back-office`, `apps/booking` (empty scaffold),
  six packages (`api`, `core`, `db`, `i18n`, `ui`, `validation`) under `packages/`, and
  `supabase/` with migrations, functions, and config.toml. Root `package.json` with workspaces.
  Evidence: `/Users/fahadasad/glowdesk/package.json` (pnpm workspaces), 
  `/Users/fahadasad/glowdesk/packages/` (6 packages present).

### CI/CD
- **MISSING**: No `.github/workflows/` directory exists. The plan requires `ci.yml` and `deploy.yml`.
  - The gates task (t_5ee7c800) flagged this as a missing gate.
  - Git status: `git -C /Users/fahadasad/glowdesk ls-files .github/` returns nothing.
  - Every subphase dependency (typecheck Deno + TS, lint, pgTAP, Deno tests, Vitest, build,
    size-limit, generated-types drift check, deploy) depends on these files existing.

### Clean-migration acceptance gate
- **MISSING**: No CI to host it. The migration-set gate (`supabase db reset` → `supabase gen types`
  drift → functions typecheck/build → `supabase test db` → adversarial fixture suite) is described
  in the plan but has no workflow to run it in CI. The gate tests themselves exist
  (`supabase/tests/`) but cannot execute as a CI gate without `.github/workflows/ci.yml`.

### Sentry
- **PARTIAL**: `captureException` in `supabase/functions/_shared/logging.ts:42-44` logs to
  `console.error` with structured fields (`name`, `message`, `stack`). There is no Sentry transport
  wired. The comment on line 40-41 says "the Sentry transport is wired in Phase 0.1 behind this
  same signature" — so the phase acknowledges Sentry is not yet wired. However, the phase's
  acceptance criteria require "Sentry captures an error from a deliberately-broken function,"
  which is not verifiable locally without a Sentry DSN. Marked NOT VERIFIABLE LOCALLY for
  the acceptance criterion, but the absence of any Sentry SDK or call to a Sentry endpoint
  means the wiring is incomplete.

### Uptime monitor
- **PARTIAL**: `supabase/functions/monitors.json` defines two monitors (health, onboarding) with
  expected status 200, x-request-id header, and response body shape. The monitors target
  `GET /functions/v1/health` and `GET /functions/v1/onboarding/health`. This is a config-only
  artifact; no actual external uptime monitor service is wired (no URL, API key, or integration
  endpoint). Marked as NOT VERIFIABLE LOCALLY for the external monitor part.

### Secrets bootstrap
- **DONE**: `supabase/functions/.env.example` documents `PLATFORM_ADMIN_SECRET`.
- `supabase/functions/.env` exists (gitignored via root `.gitignore` which lists `.env`).
- The naming convention for secrets per CONVENTIONS §3.3 ("PROVIDER_API_KEY,
  PROVIDER_WEBHOOK_SECRET, grouped PROVIDER_*") is not fully followed - the single secret
  is named `PLATFORM_ADMIN_SECRET` which is appropriate for its use case rather than
  following the PROVIDER_* pattern (it's an internal secret, not a provider key). Minor.

### Acceptance criteria status for 0.1
- CI green on trivial PR: NOT VERIFIABLE LOCALLY (no CI configured)
- Deploy pipeline: MISSING (no workflows)
- Clean-migration gate: MISSING (no CI)
- Sentry captures error: NOT VERIFIABLE LOCALLY (no Sentry DSN)

---

## Subphase 0.2: Tenancy & security skeleton

### Extension migration
- **DONE**: `20261004170000_enable_extensions.sql` creates all required extensions:
  `btree_gist`, `pgcrypto`, `citext`, `uuid-ossp`, `pg_trgm`, plus hosted-form `pg_cron`
  (with schema grants), `pgmq`, and `pg_net`. Matches the plan spec and final-round
  ADR-33 (F-final-db-1) requiring `pg_net`.

### Tables
- **DONE**: All required skeleton tables created:
  - `tenants` (with slug unique, bilingual name_en/name_ar, currency_code, is_active)
  - `currencies` (ISO-4217 code + minor_exponent, KWD seeded)
  - `profiles` (extends auth.users, locale check, self-read/write policies, auto-create trigger)
  - `memberships` (role CHECK excludes platform_admin, branch_id NULL + all_branches flag,
    partial unique index for all-branches, composite FK to branches)
  - `branches` (timezone with IANA validation, invoice_prefix, calendar preferences per ADR-52)
  - `settings` (partial unique index for tenant-wide rows WHERE branch_id IS NULL, composite FK)
  - `audit_log` (append-only, SECURITY DEFINER trigger, DML revoked from anon/authenticated)
  - `idempotency_keys` (unique on tenant_id, key, function_name per final-round F-final-db-3,
    cron purge at 30 days)

### Composite foreign keys (ADR-20 rule 5)
- **DONE (for Phase 0 scope)**: Branches has `UNIQUE (id, tenant_id)` for composite FK targets.
  Settings has `foreign key (branch_id, tenant_id) references public.branches(id, tenant_id)`.
  Memberships has `foreign key (branch_id, tenant_id) references public.branches(id, tenant_id)`.
  Audit log has `foreign key (branch_id, tenant_id) references public.branches(id, tenant_id)`.
  The tables in the ADR-20 rule 5 enumeration that don't exist yet (appointments, sales,
  payments, etc.) will get their composite FKs when created in later phases.

### Authorization helpers (ADR-19, ADR-20 rule 4)
- **DONE**: All four helpers created in `20261004170400_create_memberships.sql:51-114`:
  - `current_tenant_ids()` — returns tenant IDs for the current user's active memberships
  - `current_branch_scope(p_tenant_id uuid)` — returns branch IDs (all-branches excluded)
  - `has_tenant_role(p_tenant_id uuid, p_roles text[], p_branch_id uuid)` — no default on
    p_branch_id per F-DB-2, checks explicit branch or all-branches
  - `has_tenant_role_any_branch(p_tenant_id uuid, p_roles text[])` — checks all-branches flag
  - All declare `SET search_path = public` per ADR-20 rule 10 (F-DB-13)
  - All revoked from anon, granted to authenticated and service_role

### All-branches representation (ADR-20 rule 6)
- **DONE**: Uses `branch_id NULL` + `all_branches boolean NOT NULL DEFAULT false` with
  `CHECK (all_branches = (branch_id IS NULL))`. Partial unique indexes `WHERE branch_id IS NULL`
  for tenant-wide uniqueness. The sentinel UUID (`00000000-0000-0000-0000-000000000000`)
  is absent from all migrations — confirmed by grep. This is correctly implemented.

### RLS policies
- **DONE**: 
  - `tenants_select`: scoped to `current_tenant_ids()`
  - `branches_select`: scoped via tenant + has_tenant_role_any_branch or current_branch_scope
  - `profiles_select_self/profiles_update_self`: self read/write only (id = auth.uid())
  - `memberships_select`: own + owner sees all + manager sees branch memberships
  - `settings_select/insert/update/delete`: branch-scoped, owner tenant-wide
  - `audit_log_select`: owner tenant-wide, manager branch-scoped
  - `currencies_select`: all authenticated, active currencies only

### Profiles colleague read (ADR-20 rule 2)
- **DONE**: `20261004171000_profiles_colleague_read.sql` creates `colleague_profiles(p_tenant_id)`
  RPC returning id, full_name, avatar_url for same-tenant colleagues. Narrow scope avoids
  exposing phone, locale, or other private columns. Security definer, SET search_path.

### Audit trigger machinery (ADR-22)
- **DONE**: `audit_trigger()` SECURITY DEFINER function in 
  `20261004170300_create_audit_log.sql:28-68`. Attached to memberships and settings via
  `audit_<table>` triggers. Records old/new changed fields, actor via auth.uid(),
  entity type and ID. Skips no-op updates. DML revoked from anon and authenticated.

### pgTAP harness
- **DONE**: Five test files in `supabase/tests/`:
  - `000_harness.sql` — role switching, fixture matrix (two tenants, 3 branches, 7 users,
    6 memberships, settings fixtures, idempotency key fixture)
  - `001_tenancy_schema.test.sql` — schema validation
  - `002_tenancy_rls.test.sql` — per-role, per-operation, cross-tenant RLS verification (51 tests)
  - `003_tenancy_matrix.test.sql` — role matrix verification
  - `004_provisioning.test.sql` — provisioning RPC grants and execution (17 tests)
- Gates task confirmed 149 pgTAP tests pass.

### Edge Functions: onboarding skeleton
- **DONE**: `supabase/functions/onboarding/` exists with:
  - `index.ts` — `serve(routes, { fn: "onboarding", auth: "secret", secret: { env: "PLATFORM_ADMIN_SECRET", ... } })`
  - `routes.ts` — single route `POST /provision-tenant`
  - `handlers.ts` — `provisionTenant()` function that checks slug uniqueness, resolves/invites
    owner, calls `provision_tenant` RPC, returns 201 with tenant/branch/membership IDs
  - `onboarding_test.ts` — 7 tests covering missing/wrong secret (401), bad body (400),
    health (200), unknown action (404), new owner invite (201), existing user (201, no invite),
    duplicate slug (409)

### Acceptance criteria status for 0.2
- User with membership logs in and sees shell in EN/AR: PARTIAL (frontend code exists but
  the full login flow verification is frontend-scoped)
- pgTAP suite proves cross-tenant reads empty: DONE (confirmed by tests and gates)
- Revoking membership cuts access immediately: DONE (live membership lookup per ADR-19)

---

## Subphase 0.3: Edge Function platform

### _shared/server.ts wrapper (ADR-35)
- **DONE**: `supabase/functions/_shared/server.ts` — 185 lines implementing:
  - `createHandler(routes, options)` with auth modes `user`, `secret`, `none`
  - Route matching by `<METHOD> /<action>` per ADR-30
  - Automatic `GET /<fn>/health` route (auth: none) for every function
  - Bearer token extraction + Supabase Auth session validation
  - `ctx.caller` with live memberships from `resolveCaller()` (ADR-19)
  - `ctx.idempotent()` threading idempotency key through the protocol (ADR-31)
  - `ctx.body(schema)` parsing Zod schemas with ADR-29 field errors
  - ADR-29 envelope: `{ ok: true, data }` / `{ ok: false, error: { code, message, fieldErrors, details } }`
  - CORS headers on every response via `corsHeaders()`
  - Request ID propagation (echo inbound, mint new)
  - Structured logging with duration tracking
  - Unhandled errors → `INTERNAL` without leaking stack traces (line 166-168)

### _shared modules
- **DONE**: 
  - `auth.ts` — `resolveCaller()`, `requireScope()`, `constantTimeEqual()`, `verifySecret()`
  - `errors.ts` — mirrors `@repo/validation` catalogue
  - `cors.ts` — configurable allowed origins, preflight handler
  - `logging.ts` — structured JSON logs, request ID, `captureException`
  - `idempotency.ts` — full ADR-31 replay protocol with claim/complete/failed/retry,
    per-function replay boundary, key pattern validation
  - `db.ts` — `createAdminClient()` (service role) and `createUserClient()` (JWT forwarding)
  - `testing.ts` — local-stack helpers, seed credentials, request builder

### packages/validation Deno-compatible export
- **DONE**: 
  - `packages/validation/src/` exports pure-TS Zod schemas
  - `packages/validation/package.json` has `"exports": { ".": "./src/index.ts" }`
  - `index.ts` re-exports from `errors.ts`, `envelope.ts`, `onboarding.ts`
  - `_shared/deno.json` maps `@repo/validation` to `../../../packages/validation/src/index.ts`
  - `_shared/validation_contract_test.ts` proves Deno imports the schemas and the error catalogue
    matches ADR-29 (validates all codes, statuses, NETWORK client-only distinction, schema parsing)
  - `provisionTenantSchema` in `onboarding.ts` validates slug, IANA timezone, email

### Function template
- **DONE**: `supabase/functions/_template/` with:
  - `index.ts` — ready-to-copy skeleton calling `serve(routes, ...)`
  - `routes.ts` — `GET /whoami`, `POST /echo` with comments about ADR-30
  - `handlers.ts` — `whoami` (returns caller context), `echo` (validates via Zod, checks scope)
  - `template_test.ts` — test file

### health function
- **DONE**: `supabase/functions/health/index.ts` — single route `GET /` returning
  `{ status: "ok" }`, auth: none. Config.toml sets `verify_jwt = false`.
  Monitors in `monitors.json` target this endpoint.

### onboarding function — beyond skeleton
- **DONE**: The onboarding function is a full working implementation, not just a skeleton:
  - Platform-secret auth with `x-platform-admin-secret` header
  - Slug uniqueness check before any write
  - Owner invite via `admin.auth.admin.inviteUserByEmail()` for new users
  - Existing user detection via `find_user_id_by_email` RPC
  - `provision_tenant` database RPC that creates tenant + branch + membership + audit row
    atomically in the same transaction (no orphan state)
  - Zod schema validation for all fields
  - 7 Deno tests covering all auth modes, validation, and happy paths

### Contract test
- **DONE**: `_shared/validation_contract_test.ts` tests:
  - Error catalogue matches ADR-29 exactly (9 codes with correct HTTP statuses)
  - `NETWORK` is correctly excluded from server codes
  - `provisionTenantSchema` parses valid input and returns field errors for invalid input
  - Import symmetry: `_shared/errors.ts` re-exports `@repo/validation`'s catalogue

### Acceptance criteria status for 0.3
- Health route returns 200 with request ID header: DONE (verified in code and tests)
- Sentry captures unhandled error: NOT VERIFIABLE LOCALLY (same issue as 0.1)
- packages/validation schemas import from Deno: DONE (contract test proves it)

---

## Subphase 0.4: Frontend platform
Note: This subphase is primarily frontend-scoped, but backend-relevant items are checked.

### packages/db
- **DONE**: `packages/db/src/` has:
  - `client.ts` — `createTypedClient` wrapper
  - `database.types.ts` — generated types from Supabase
  - `index.ts` — exports

### packages/api
- **DONE**: `packages/api/src/` has:
  - `invoke.ts` — typed `invoke<T>()` that builds function URLs, sends JWT/anon key,
    parses ADR-29 envelope into typed data or `ApiError`, handles idempotency key threading,
    AbortSignal, NETWORK error for fetch failures
  - `errors.ts` — `ApiError` class with code, status, fieldErrors, details, requestId
  - `invoke.test.ts` — tests for invoke
  - `client.ts` / `client.test.ts` — typed client wrappers

### packages/core
- **DONE**: `packages/core/src/` has:
  - `money.ts` / `money.test.ts` — minor-unit conversions (integer arithmetic)
  - `scopeKeys.ts` / `scopeKeys.test.ts` — query key factories with tenant+branch scope

### packages/i18n
- **DONE**: `packages/i18n/src/` has:
  - `format.ts` / `format.test.ts` — money formatter (minor units → KWD 12.500), date formatter
    (UTC → branch tz)
  - `I18nProvider.tsx` / `useFormat.tsx` — React providers
  - `locales.ts` / `catalogs.ts` — Lingui catalogs setup

---

## Subphase 0.5: Calendar library spike
- **DONE**: ADR-41 was updated with the spike outcome (fallback GO, premium not evaluated).
  The gate logs from the parent task confirm this. Not backend-scoped beyond noting the
  existence of the verdict.

---

## Cross-cutting concerns

### Auth mode configuration in config.toml
- **DONE**: Config.toml correctly sets `verify_jwt = false` for both functions:
  - `[functions.health]` (auth: none — handled in code)
  - `[functions.onboarding]` (auth: secret — handled in code)
  This is correct per ADR-27/ADR-35: the wrapper enforces auth per route, and `verify_jwt`
  is set to false so the Supabase gateway doesn't reject requests without a user JWT.

### Secret comparison
- **DONE**: `constantTimeEqual()` in `auth.ts:75-80` hashes both sides with SHA-256 before
  comparing, preventing timing attacks based on string length or character position.

### No committed secrets
- **DONE**: Root `.gitignore` covers `.env`, `.env.local`, `.env.*.local`.
  "supabase functions/.env" files are gitignored. `git log -p` for secret-like strings
  shows only documented references (env var names, not values). No API keys or passwords
  are hardcoded in committed files.

### Pinned dependencies
- **DONE**: `_shared/deno.json` pins versions:
  - `@supabase/supabase-js@2.117.2`
  - `zod@4.6.5`
  - `@std/assert@1.0.19`
  - `deno.lock` file present for integrity verification

### Request ID propagation
- **DONE**: `REQUEST_ID_HEADER = "x-request-id"`. Inbound IDs are echoed if well-formed;
  malformed ones are replaced (server_test.ts:38-42). The header is set on every response.

### CORS handling
- **DONE**: `cors.ts` implements:
  - Default allowed origins: `http://127.0.0.1:5173`, `http://localhost:5173`
  - Configurable via `ALLOWED_ORIGINS` env var
  - Preflight handler returns 204
  - Allowed headers include `authorization, apikey, content-type, x-client-info,
    idempotency-key, x-tenant-id, x-request-id`
  - Exposed header: `x-request-id`
  - Origin not in list → empty headers (no CORS leak)

---

## Findings

### F-BE-1: CI/CD workflows missing
- Severity: **blocker**
- Location: `/Users/fahadasad/glowdesk/.github/` — directory does not exist
- Problem: Phase 0 exit criterion requires "CI is green on a trivial PR touching both
  a function and a component" and "Deploy pipeline promotes staging→production with
  functions and migrations". Without `.github/workflows/ci.yml` and `deploy.yml`, no
  automated testing or deployment pipeline exists.
- Evidence: `ls /Users/fahadasad/glowdesk/.github/` returns "NO .github/" — directory does not exist.
  Confirmed by git: `git -C /Users/fahadasad/glowdesk ls-files .github/` returns nothing.
- Fix: Create `.github/workflows/ci.yml` with the following steps: pnpm install --frozen-lockfile,
  typecheck (Deno + TS), lint (ESLint + stylelint), `supabase db lint`, pgTAP via
  `supabase test db`, Deno tests (`deno test --allow-all`), Vitest, build,
  size-limit, generated-types drift check (`supabase gen types`), clean-migration gate
  (supabase db reset → gen types → function typecheck → test db). Create
  `.github/workflows/deploy.yml` for migrations then functions (`--use-api`) then
  frontend build/deploy from the same commit.
- Plan item: Subphase 0.1 backlog items (3rd and 4th bullet: ci.yml, deploy.yml)

### F-BE-2: Deno test for idempotency replay across functions incorrectly uses the same tenant_id for inter-function boundary test
- Severity: **minor**
- Location: `supabase/functions/_shared/idempotency_test.ts:81-88`
- Problem: The "same key under another function is independent" test uses the same
  `SEED.tenantId` for both calls but different function names. This is technically correct
  because the uniqueness constraint is `(tenant_id, key, function_name)`, so different
  function names with the same key are independent. However, the test comment says
  "the same key under another function" which could mislead a reader into thinking
  the key granularity spans functions (it doesn't — the key+function pair is what's unique).
- Evidence: 
  - Schema: `unique (tenant_id, key, function_name)` in `idempotency_keys` migration
  - Test at line 81-88: same key, different function names → independent (correct behavior)
  - The per-function replay boundary per F-final-db-3 is correctly implemented; the concern
    is only test naming clarity.
- Fix: Update the test comment to clarify: "the replay boundary is per function: the same
  key under a different function_name is a new attempt, not a replay"
- Plan item: ADR-31, final round F-final-db-3

### F-BE-3: No Sentry SDK or transport imported in any function
- Severity: **major**
- Location: `supabase/functions/_shared/logging.ts:42-44`
- Problem: Phase 0.1 acceptance criteria require "Sentry captures an error from a
  deliberately-broken function". The `captureException` function only logs to `console.error`
  and has no Sentry SDK import, no DSN configuration, and no call to any Sentry endpoint.
- Evidence: `supabase/functions/_shared/logging.ts:42-44` — the function body is:
  ```
  const err = error instanceof Error ? error : new Error(String(error));
  logger.error("exception", { ...fields, name: err.name, message: err.message, stack: err.stack });
  ```
  There is no `import * as Sentry from "npm:@sentry/deno"` or similar anywhere in the
  `_shared/` directory. The comment on lines 40-41 says "the Sentry transport is wired in
  Phase 0.1 behind this same signature" — acknowledging it's incomplete.
- Fix: Add Sentry initialization in each function's entry point (or a shared init in `_shared/`):
  ```
  import * as Sentry from "npm:@sentry/deno@8.x";
  Sentry.init({ dsn: Deno.env.get("SENTRY_DSN") ?? "", environment: Deno.env.get("ENV") ?? "local" });
  ```
  Wire `captureException` to call `Sentry.captureException(err)`. Add `SENTRY_DSN` to
  `.env.example`. The Sentry Deno SDK docs are at https://docs.sentry.io/platforms/javascript/guides/deno/.
- Plan item: Subphase 0.1, backlog 6th bullet (Sentry + uptime monitor + log drain wiring)

### F-BE-4: Uptime monitor configuration exists but no monitor service configured
- Severity: **minor**
- Location: `supabase/functions/monitors.json`
- Problem: The monitor config file defines the probes but nothing actually calls them.
  The phase acceptance criterion requires "uptime monitor fires on simulated downtime".
  Without a running monitor service or integration, this is unverified.
- Evidence: `supabase/functions/monitors.json` defines targets for health and onboarding
  endpoints with expected responses. No integration with any uptime service (Better Uptime,
  Pingdom, etc.) is configured anywhere in the repo.
- Fix: Not a code change; requires an ops decision. Options: use `curl --retry` in a cron
  job as a simple heartbeat, or integrate Better Uptime/Pingdom with the documented endpoints.
  The `monitors.json` can serve as the config source for whichever monitor is chosen.
- Plan item: Subphase 0.1, backlog 6th bullet

### F-BE-5: Onboarding owner invite creates orphan auth user if provisioning fails
- Severity: **major**
- Location: `supabase/functions/onboarding/handlers.ts:40-63`
- Problem: The `provisionTenant` function resolves/invites the owner (step 2) BEFORE
  calling the `provision_tenant` database RPC (step 3). If the RPC fails (e.g., due to
  a race condition where another concurrent request inserted the tenant between the
  slug check and the insert), the invited auth user already exists with no tenant,
  no membership, and no way to access the system. This creates an orphan user.
- Evidence:
  - `handlers.ts:40-47`: slug check
  - `handlers.ts:49`: `resolveOwner()` — this creates the auth user via invite
  - `handlers.ts:51-56`: `admin.rpc("provision_tenant", ...)` — this creates the tenant,
    branch, and membership. If this fails, the invited user from step 2 is orphaned.
  - The test `onboarding_test.ts:149-156` only covers the "slug already taken" case
    where the slug check (`existingTenant`) catches it before `resolveOwner()` runs.
    It does not cover the race-condition case where the slug check passes but
    `provision_tenant` fails.
- Fix: Restructure `provisionTenant` to either:
  (a) Move the invite into the database RPC so it's inside the same transaction as
      tenant creation, OR
  (b) Add a "reverse" step: if `provision_tenant` fails after a successful invite,
      call `admin.auth.admin.deleteUser(ownerId)` to clean up the orphan,
      or at minimum log the orphan for manual cleanup.
- Plan item: Subphase 0.2 onboarding function, ADR-20 rule 3 (tenant creation is
  platform-admin only, but must not orphan users)

### F-BE-6: packages/validation has no Deno-compatible import file test from a function's perspective
- Severity: **minor**
- Location: `supabase/functions/_shared/validation_contract_test.ts`
- Problem: The contract test imports `@repo/validation` from `_shared/` and validates schema
  parsing, but the test is in `_shared/` — it relies on `_shared/deno.json`'s import map.
  A function that wants to use a validation schema directly (e.g. `onboarding` importing
  `provisionTenantSchema`) also needs the import map entry. The onboarding function
  correctly uses `@repo/validation` via `ctx.body()` which passes the schema through. 
  This works but is not separately tested from a function subfolder. No evidence of an
  actual problem — the onboarding test works. Minor documentation/coverage gap.
- Evidence: `_shared/deno.json` correctly maps `@repo/validation` to the source. The
  `validation_contract_test.ts` in `_shared/` successfully imports and exercises it.
  `onboarding/handlers.ts` line 1 imports `provisionTenantSchema` from `@repo/validation`
  without issue. All Deno tests pass (gates task: 48 Deno tests).
- Fix: Add a comment or rename the test file to clarify it validates the Deno import path
  from any function context, not just `_shared/`.
- Plan item: Subphase 0.3, backlog: "packages/validation Deno-compatible export + contract test"

### F-BE-6: No rate limiting implementation for MVP
- Severity: **not a blocker per ADR-47**
- Location: All functions
- Problem: The plan notes that MVP relies on Supabase platform rate limits and there is
  no per-function rate limiting. `RATE_LIMITED` (429) is in the error code catalogue
  but no function or middleware implements it. Per ADR-47, this is deliberate: platform
  limits cover auth endpoints; application-level rate limiting is designed in plan Phase 9.
- Evidence: No `rate_limit` middleware, no token bucket, no per-IP counters exist in
  `_shared/` or any function. The error code is available for when rate limiting is added.
  ADR-47 states: "No fictional per-function configuration is referenced anywhere."
- Verdict: DEVIATED-JUSTIFIED — following ADR-47. Not a finding.

### F-BE-7: .env.example only documents PLATFORM_ADMIN_SECRET, missing INTERNAL_FUNCTION_SECRET
- Severity: **major**
- Location: `supabase/functions/.env.example`
- Problem: The `_shared/auth.ts` `DEFAULT_SECRET` references `INTERNAL_FUNCTION_SECRET` as
  the default env var for secret auth mode. However, `.env.example` only documents
  `PLATFORM_ADMIN_SECRET` (for the onboarding function). Any future function using secret
  auth mode with the default setting will fail because `INTERNAL_FUNCTION_SECRET` is not
  documented, not in `.env.example`, and a developer would not know to set it.
- Evidence: 
  - `_shared/auth.ts:91-95`:
    ```
    export const DEFAULT_SECRET: SecretConfig = {
      env: "INTERNAL_FUNCTION_SECRET",
      header: "x-function-secret",
      label: "function secret",
    };
    ```
  - `supabase/functions/.env.example` only has `PLATFORM_ADMIN_SECRET`.
  - The `_template/index.ts` uses `auth: "user"` so it doesn't trigger the issue, but any
    new function using `auth: "secret"` without explicitly passing a secret config will
    look for `INTERNAL_FUNCTION_SECRET`.
- Fix: Add to `supabase/functions/.env.example`:
  ```
  # Default secret for secret-auth-mode functions (cron, pg_net, ops callers).
  # Set per-function via a custom SecretConfig when a different key is needed.
  INTERNAL_FUNCTION_SECRET=local-internal-secret
  ```
- Plan item: CONVENTIONS §3.3 (secrets naming), Phase 0 edge function platform

---

## Summary

| ID | Severity | Title |
|---|---|---|
| F-BE-1 | blocker | CI/CD workflows missing (no .github/workflows/) |
| F-BE-3 | major | No Sentry SDK or transport wired |
| F-BE-5 | major | Onboarding can orphan invited auth user on failure |
| F-BE-7 | major | INTERNAL_FUNCTION_SECRET undocumented in .env.example |
| F-BE-2 | minor | Idempotency per-function test comment clarity |
| F-BE-4 | minor | Uptime monitor config exists but no monitor service wired |
| F-BE-6 | minor | Deno validation contract test naming ambiguity |

Severity counts: 1 blocker, 3 major, 3 minor, 0 partial