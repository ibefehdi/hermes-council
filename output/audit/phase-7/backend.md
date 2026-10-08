# Phase 7 Edge Functions and backend audit

Auditor task: t_009c31fd
Date: 2026-10-08
Repo: /Users/fahad/GlowDesk @ 6920a18b639906fa925eb20015c95740916b831c (HEAD, main)
Scope per backend brief: `supabase/functions/`, `packages/validation`, `packages/api`, `supabase/config.toml`; judged against the phase text, ADR-19, ADR-20 rules 3 and 7, ADR-27 to ADR-33, CONVENTIONS.md sections 3.3, 4 and 6, and the `supabase-edge-functions` skill. Gate logs in /Users/fahad/council/output/audit/phase-7/gates/ (all 14 applicable gates PASS; GATES.md lines 29-42).

## What phase 7 added on the backend

The only new Edge Function in phase 7 is `reports` (slug = bounded context, ADR-27), added by commits ec727bc (7.3-T1), f753385 (7.3-T2), 86be3fe (7.3-T3), 6bb3841 (7.3-T4, benchmark fixture). The 7.3 work also added the export-jobs migration `supabase/migrations/20261014100100_export_jobs.sql` (tables `export_jobs`, `export_parts`, `export_download_tokens`, pgmq `report_export` queue, producer/consumer/download RPCs, purge cron) and `20261014100000_report_exports.sql` (R10 matrix `export_kind_allowed`, `record_export` audit), plus `packages/validation/src/reports.ts` (schemas) and `packages/api/src/client.ts` reports wrappers (ADR-30). The 7.1 report RPCs (`report_*`) are database work (database audit's scope) but four of them are called by the function and were exercised here. The 7.4 hardening commits (33b7647, fd1ef37, 1276cdb) include the function config guard, frozen Deno lock pins and the perf benchmark wired into CI (`.github/workflows/perf-volume.yml`), which are backend-relevant.

## Method

Read the phase text (plan/parts/11-delivery-plan.md:1297-1472), the binding ADRs, CONVENTIONS.md, and the repo skill (.cursor/skills/supabase-edge-functions/SKILL.md). Read every module of the reports function, the export migrations, the validation schemas and the api wrappers. Confirmed gate state from GATES.md and the raw logs (06-fntest.log, 11-fn-pins.log, 12-fn-config.log, 14-fn-check.log). Exercised the served function on http://127.0.0.1:54321/functions/v1/reports/* with good and bad input (probe scripts; full request/response captured below). All probe test data (export jobs, parts, tokens, EXPORT audit rows) was removed afterwards; the DB is back to the seeded state.

---

## Subphase 7.1 — Report data (backend-relevant slice)

The phase text says Edge Functions: none (data layer only). The backend-relevant contract is that the reports function calls the `report_*` RPCs as the caller and the RPCs enforce scope server-side. Verified:

- `handleReportCsv` (supabase/functions/reports/handlers.ts:88-134) runs every report RPC through `ctx.userClient` (the caller's JWT, RLS-scoped) — never the service role. Scope denial is raised inside the RPCs via `report_branch_scope` which checks `has_tenant_role(p_tenant_id, p_roles, b.id)` live against `memberships` (supabase/migrations/20261013100000_report_sales_payments.sql:17-56) and raises 42501 → mapped to `FORBIDDEN` with `details.reason = report_scope_denied` (reports/rejection.ts:31-32). Exercised: receptionist → 403 report_scope_denied; another tenant's owner → 403; owner/manager → 200.
- Every report RPC returns `branch_ids` in its JSON so the CSV renderer can resolve branch names through the caller's RLS-scoped client (e.g. report_payments_summary return: 20261013100000_report_sales_payments.sql:297-303). Exercised: Arabic branch name "السالمية" resolves in the AR CSV.
- Client list: `report_client_list` deliberately excludes allergies, alerts, notes and email; phone only for the screen, and the CSV drops it (20261013100200_report_clients_shifts.sql:11-14; reports/csv.ts:173-190 CLIENTS columns; report_csv_test.ts:162-172 asserts no phone/email columns and formula guard). This matches the phase requirement "client-contact export owner-only; allergy detail redacted from aggregate exports". The full contact export (`clients_contacts`) is owner-only via `export_kind_allowed` (20261014100000_report_exports.sql:37-44) — exercised: manager → 403.

Verdict: DONE (backend slice); the view/RPC layers are the database audit's remit.

---

## Subphase 7.2 — Reports UI (backend-relevant slice)

No new Edge Functions in 7.2; the screens call report RPCs directly under the allowlist (CONVENTIONS.md section 6: "report views (security_invoker), report RPCs" are direct reads) and the CSV export button calls the 7.3 function through `packages/api`. The typed wrappers exist: `reports.reportCsv`, `reports.startExport`, `reports.exportLink`, `reports.exportFileUrl` (packages/api/src/client.ts:309-322), and function paths appear nowhere else in frontend code (ADR-30). The export page route guards on `EXPORT_ROLES` (owner/branch_manager) (apps/back-office/src/features/exports/routes.tsx:14). The topbar search and audit viewer are frontend scope.

Verdict: DONE (backend slice: api wrapper layer).

---

## Subphase 7.3 — Exports (the backend core of the phase)

### 7.3.1 Layout and isolation (brief item 1) — DONE

- Slug `reports` = bounded-context name (ADR-27; CONVENTIONS.md 3.3). Folder name = slug.
- `_shared/` imported by relative path everywhere: server.ts:1, handlers.ts:3-8, exports.ts:2-5, csv.ts:6-7. No imports from `apps/` or other packages.
- `packages/validation` imported through its Deno-compatible export: reports/deno.json maps `@repo/validation` → `../../../packages/validation/src/index.ts` (exact pinned versions: @supabase/supabase-js@2.117.2, zod@4.6.5, @sentry/deno@11.4.0, @std/assert@1.0.19). packages/validation/package.json exports `"./src/index.ts"` directly, so Deno and TS share one copy (ADR-32, ADR-39).
- Dependencies pinned: fn:pins gate PASS — "10 function configs, 10 lockfiles, 0 problems" (11-fn-pins.log:2); each function has its own deno.json + committed deno.lock.
- Isolation between functions: each function is served independently; a broken slice/route fails only the reports function (the route guard + 503-in-other-functions scenario in the gate log is an environment boot issue, see GATES.md:23).
- Health endpoint and uptime monitor target present: `reports` entry in supabase/functions/monitors.json (GET /functions/v1/reports/health), matching the skill's layout.

### 7.3.2 Auth modes (brief item 2) — DONE

| Route | Mode | Verification |
|---|---|---|
| `POST /reports/report-csv` | user JWT (default) | 401 missing bearer (probe 2; 06-fntest.log route guard), 403 outsider, 200 owner |
| `POST /reports/export` | user JWT | 401/403 as above; replay returns same job (probe 11-12) |
| `POST /reports/export-consume` | secret (`x-function-secret`) | 401 without / with wrong secret, 200 with the seed secret (probes 3-5) |
| `POST /reports/export-link` | user JWT | 404 for non-requester/non-owner (probe 13), 200 for requester/owner |
| `GET /reports/export-file` | none (one-time token is the credential) | 404 without/malformed/spent token (probes 6, 7, G; report comment routes.ts:11-12) |
| `GET /reports/health` | none (wrapper adds it) | 200 without session (probe 1) |

- JWT verification: user mode calls `admin.auth.getUser(jwt)` (server.ts:126-128) — server-side verify; memberships re-read live on every request (`resolveCaller`, _shared/auth.ts:22-40; ADR-19), never JWT claims.
- Secret comparison is constant-time: `constantTimeEqual` hashes both sides with SHA-256 then XORs equal-length digests (_shared/auth.ts:67-80), used by `verifySecret` (auth.ts:98-104). Covered by _shared tests "constantTimeEqual compares by value" and "verifySecret rejects when the env secret is unset" (06-fntest.log:9-10).
- Platform-admin path (onboarding) unreachable without its secret is unchanged from earlier phases; reports' secret path (`export-consume`) is reachable only with `INTERNAL_FUNCTION_SECRET` — verified 401 without.
- Service role is never used for per-user requests: all report RPCs and the export producer run as `ctx.userClient` (JWT); the service-role client is used only for (a) idempotency protocol writes (`withIdempotency`, server.ts:161-166, itself client-inaccessible per ADR-31), (b) `export-consume` (cron path, secret-authed), (c) `export-file` (token path, the token is the credential), and (d) tenant/currency metadata reads after the caller's scope has already been verified by `export_kind_allowed`. Privileged code re-derives scope from live memberships on every slice: `process_export_slice` re-runs `export_kind_allowed` with the requester's `sub` and fails the job with `scope_revoked` if the membership is gone (20261014100100_export_jobs.sql:693-702) — ADR-20 rule 7, exercised by export_download_test.ts:68-78.

### 7.3.3 Contract (brief item 3) — DONE

- ADR-29 envelope everywhere JSON is returned: `{ok:true,data}` / `{ok:false,error:{code,message,fieldErrors?,details?}}` (server.ts:76-80, errors.ts:23-33). All probe responses conformed. File routes return raw CSV bytes on success and the envelope on failure, which is the documented contract for `invokeFile` (packages/api/src/invoke.ts:126-137).
- Error codes from the one catalogue (packages/validation/src/errors.ts, mirrored in _shared/errors.ts): VALIDATION(400), UNAUTHENTICATED(401), FORBIDDEN(403), NOT_FOUND(404), CONFLICT(409), IDEMPOTENCY_MISMATCH(422), INTERNAL(500). reportRejection maps only catalogue codes (rejection.ts:28-49). Exercised: 400 VALIDATION with fieldErrors.to=validation.range_too_long, 400 validation.invalid_section, 409 CONFLICT too_many_exports (export_job_test.ts:77-110), 404 NOT_FOUND for spent/malformed tokens, 403 report_scope_denied.
- Validation failures return `VALIDATION` with `fieldErrors`: `ctx.body(schema)` maps Zod failures via `toFieldErrors` (server.ts:147-159); the schema-level superRefine rules in reports.ts:46-63,108-128 produce field-mapped keys handled by rejection.ts FIELD_OF.
- Request ids: every response carries `x-request-id`, an inbound well-formed id is echoed (logging.ts:6-12; server.ts:177). Exercised: echo probe "probe-req-123".
- CORS: the function sets allowlist-based headers (cors.ts; _shared tests "CORS headers present for allowed origins", "OPTIONS preflight returns 204", 06-fntest.log:191-192). Note: locally the Kong gateway answers preflight with `Access-Control-Allow-Origin: *` and its own method list before the function sees OPTIONS (probe 15-16), which is the Supabase platform's documented behavior — "Supabase currently handles CORS by using a wildcard for the Access-Control-Allow-Origin" (https://github.com/orgs/supabase/discussions/7038, retrieved 2026-10-08). The function's own headers (allow-headers incl. idempotency-key, x-tenant-id; expose-headers incl. content-disposition) are added to actual responses when the origin is allowed. Bearer-token auth + one-time download tokens mean the `*` preflight does not expose data; this matches the plan's reliance on platform behavior and is not treated as a defect.
- Unhandled errors become `INTERNAL` without leaking: `toAppError` maps unknown errors to a fixed message and reports to Sentry with the full stack server-side (server.ts:82-92, logging.ts:46-50); _shared test "unexpected errors give INTERNAL without leaking details" (06-fntest.log:285-289).

### 7.3.4 Invariants (brief item 4) — DONE

- Money-moving mutations: phase 7 adds no money-moving mutation (exports are reads/jobs). The job-starting mutation `/export` still uses the ADR-31 protocol: `ctx.idempotent(tenant_id, payload, run)` with a mandatory `Idempotency-Key` (server.ts:160-167, idempotency.ts:32-40), replay boundary per function action `reports-export` (F-final-db-3 per-function scope). Exercised: same key twice → same job_id, no second job (probe 11-12; export_job_test.ts:45-57); no key → 400 VALIDATION (export_job_test.ts:85,92).
- Multi-row writes in one transaction: `start_export` inserts the job row, the pgmq batch and the audit row in one RPC/transaction (20261014100100_export_jobs.sql:531-594); `process_export_slice` writes part + next message + job update + audit in one transaction per message (lines 640-753). No client-side sequence of calls that can half-succeed.
- Orphan state: a died consumer's messages return after the 120 s visibility timeout and are redelivered; an interrupted job resumes from the last written part and the result is byte-identical to an uninterrupted run (export_resume_test.ts:23-55 — exercised and passing, 06-fntest.log:588). A message whose part already exists is deleted as a no-op (idempotent consumer, ADR-33) (20261014100100_export_jobs.sql:681-685). After 5 reads the message is archived and the job fails (lines 686-690). The full-tenant export is chunked (10,000-row slices) with a ≤600 s end-to-end / <150 s per-invocation budget benchmark (scripts/perf/export-bench.ts:13-14) — see NOT VERIFIABLE below for the benchmark run itself. Orphan download tokens and parts are purged hourly (purge_expired_exports + cron, lines 875-901, 938-939; verified present in DB).

### 7.3.5 Exercise (brief item 5) — DONE

Served functions exercised on http://127.0.0.1:54321/functions/v1/reports/* with seed users (owner/manager/receptionist @spacorner.test, README.md:34-43, password password123; local dev seed, safe to mention). Summary of the 17 probes + full export flow (all responses conformed; details in sections above):

1. GET /reports/health (no session) → 200 {ok:true,data:{status:"ok"}}.
2. POST /reports/report-csv (no session) → 401 UNAUTHENTICATED "Missing bearer token".
3-5. POST /reports/export-consume no/wrong/right secret → 401 / 401 / 200 with {messages:0}.
6-7. GET /reports/export-file no token / malformed → 404 NOT_FOUND envelope.
8. report-csv daily_sales as receptionist → 403 FORBIDDEN details.reason=report_scope_denied (receptionists may see the daily summary on screen but never export it, per R10).
9. report-csv sales as owner → 200 text/csv; charset=utf-8, body starts with UTF-8 BOM (ef bb bf) and the Date,Branch,Sales header; CRLF rows.
10. export clients_contacts as manager → 403 (owner-only kind, ADR-43/R10).
11-12. export appointments as owner → 202 with job; replay with same Idempotency-Key → same job_id (idempotent, no duplicate job).
13. export-link for owner's job as manager (not requester/owner) → 404 NOT_FOUND.
14. unknown route → 404 envelope.
15-16. OPTIONS preflight: allowed origin gets 204 + allow-origin; disallowed origin answered by gateway (see CORS note above).
17. x-request-id echo verified.

Full flow (full_tenant export, drained through export-consume as the cron does): job completed with 147 rows across 18 files; export-link as owner → one-time token; download returned BOM-prefixed CSV with correct headers; token reuse → 404 (one-time); receptionist link → 404; revoked manager → 403; audit rows EXPORT_REQUESTED / EXPORT_COMPLETED / EXPORT_DOWNLOADED written per branch and visible in audit_log (probe H). Cron jobs `report-export-consumer` (every 10 s) and `purge-expired-exports` (hourly) present in cron.job (probe I). All probe data (3 jobs, 22 parts, tokens, 13 audit rows) was deleted afterwards; export_jobs/parts/tokens counts are 0 and the DB matches the seeded state.

### 7.3.6 Tests (brief item 6) — DONE

The phase's Tests bullet for 7.3 is the benchmark suite (export volume, report latency, NFR-4/5 re-run). The Deno suite covers the acceptance criteria with real HTTP against the served function (no mocks of the thing under test):

- report_csv_test.ts (13 total report tests, 06-fntest.log:577-596): BOM/CRLF/UTF-8/Arabic headers (113-129); numbers equal the report RPC at the currency exponent (131-160); client list CSV has no phone/email and guards formulas (162-172); refusals: receptionist/other-tenant/no-session/bad-section/over-long range (174-189); exactly one EXPORT audit row per branch per call (191-210).
- export_job_test.ts: 202 + idempotent replay same job (45-64); manager branch rows exactly match source tables (66-75); refusals incl. R10 roles, dates, no key, and the too-many-open-jobs CONFLICT (77-110).
- export_resume_test.ts: interrupted jobs resume and match uninterrupted output byte-for-byte (23-55) — covers ADR-33 idempotent consumer + the "killing the job mid-run resumes" acceptance criterion.
- export_download_test.ts: volume ordering behind one BOM/header (20-49); token single-use + no forged tokens (51-58); requester/owner-only linking (60-66); revoked membership 403, expired/not-ready job CONFLICT (68-102).
- Shared contract tests (_shared route_guard_test/server_test/validation_contract_test, 06-fntest.log:39-321) cover envelope, CORS, request-id, VALIDATION field errors, constant-time secrets, and the ADR-29 catalogue across every function including reports.

Concurrency-relevant coverage: the resume test exercises redelivery timing; the too-many-exports test exercises the job quota. The full-tenant 100k-row benchmark is NOT VERIFIABLE LOCALLY (requires seeding >100k clients; writes into plan/evidence); the gate SKIPPED it for exactly that reason (GATES.md:43), and it is wired as a scheduled CI job (.github/workflows/perf-volume.yml, nightly + on-demand) with budgets (600 s end-to-end, 150 s/invocation, 150 s download) enforced by scripts/perf/export-bench.ts:13-14. The 7.3 acceptance criterion "≤10 min end-to-end" is therefore marked NOT VERIFIABLE LOCALLY in summary, not failed.

### 7.3.7 Secrets and config (brief item 7) — DONE

- Local secrets live in gitignored files with a committed example: supabase/functions/.env is gitignored (git check-ignore passes) and supabase/functions/.env.example is committed with placeholders only (local-platform-admin-secret, local-internal-function-secret, empty SENTRY_DSN). apps/back-office/.env.example likewise (VITE_* placeholders).
- Nothing secret committed: full-history scans for service-role/JWT-like values (eyJ… patterns, SUPABASE_SERVICE_ROLE_KEY=…) found only the demo anon JWT (`iss: supabase-demo, role: anon`) in examples/test seeds/Dockerfile, which is the harmless local demo key. No CLIs, no real keys in git log.
- Required secrets documented: PLATFORM_ADMIN_SECRET, INTERNAL_FUNCTION_SECRET, SENTRY_DSN in .env.example and docs/runbooks/production-project.md:35; vault secrets functions_base_url + internal_function_secret seeded locally (seed.sql:203-206) and documented for staging/production (docs/runbooks/staging-deploy.md:34-39). The cron kicker reads them from vault (20261014100100_export_jobs.sql:922-924).
- One hygiene gap, minor: an untracked `.seed-pw` file sits at the repo root and is NOT covered by .gitignore (it has never been committed — `git log --all -- .seed-pw` is empty — but `git add .` would pick it up). It predates this phase (it existed before the gate run per GATES.md:6) but is worth fixing now. See F-backend-1.
- ALLOWED_ORIGINS (read by cors.ts; defaults to the two localhost dev origins) is not listed in .env.example or the runbooks.

---

## Subphase 7.4 — Hardening (backend-relevant slice)

- Rate-limit review (7.4-T6, fd1ef37): confirmed no fictional per-function config keys appear anywhere; config.toml has no `[functions.*.rate_limit]` block, consistent with ADR-47 (decisions.md:395-399) and the Supabase CLI config docs (https://supabase.com/docs/guides/cli/config — keys are verify_jwt, import_map, entrypoint, static_files; retrieved 2026-10-08). Function config guard gate PASS (12-fn-config.log: "8 functions, 0 problems") enforces this in CI (script scripts/check-functions-config.ts).
- Dependency audit in CI: pnpm audit:prod gate PASS, 0 advisories (GATES.md:35); covered by ci.yml.
- Backup/restore drill: out of backend scope except that the vault-secret/kick wiring the drill must restore is documented (docs/runbooks/backup-restore.md:39-40); drill itself is ops/DB scope and NOT VERIFIABLE LOCALLY (staging snapshot required); ADR-49 config for the production project is a Phase 8 item by the phase text itself (11-delivery-plan.md:1449).
- Function config: `[functions.reports] verify_jwt = false` in config.toml:453, with the wrapper enforcing auth per route (skill documents why the gateway check must be off in this wrapper design).

## Findings

### F-backend-1: untracked password-looking `.seed-pw` file at repo root is not gitignored
- Severity: minor
- Location: /Users/fahad/GlowDesk/.seed-pw (untracked; `.gitignore` only covers `.env`, `.env.local`, `.env.*.local` — git lines 5-7)
- Problem: a 16-byte ASCII value that looks like a generated password sits in the working tree uncovered by gitignore. It has never been committed (`git log --all -- .seed-pw` empty; `git ls-files` contains no `.seed-pw` — the four tracked files matching "seed" are `scripts/perf/seed-*.ts/.sql` and `supabase/seed.sql`, all legitimate), so nothing secret is in history, and it predates this phase (GATES.md:6 lists it as pre-existing). The risk is future `git add .` / `git add -A` committing it.
- Evidence: `git check-ignore .seed-pw` → not ignored; `git status --short` → `?? .seed-pw`; file is ASCII text, 16 bytes, no line terminator.
- Fix: append `.seed-pw` to `/Users/fahad/GlowDesk/.gitignore` (and, if the value is still needed by scripts, document what creates it — nothing in the repo references it today).
- Plan item: backend brief item 7 (nothing secret committed; hygiene).

### F-backend-2: ALLOWED_ORIGINS is undocumented and unlisted in .env.example / runbooks
- Severity: minor
- Location: supabase/functions/_shared/cors.ts:14-17 (reads `ALLOWED_ORIGINS`); default origins are only `http://127.0.0.1:5173` and `http://localhost:5173` (cors.ts:1)
- Problem: the only knob for the function-level CORS allowlist is never mentioned in supabase/functions/.env.example, README.md or docs/runbooks/*. A deploy to a hosted project where the SPA origin is e.g. https://glowdesk.ibefehdi.com would serve every function with an empty-or-with-localhost-only allowlist unless someone happens to set the variable; no documentation or example leads them to it. (Impact is bounded today because the platform gateway answers preflight with `*`, but the function's own allow-list headers — which ARE what the browser sees on the actual response for non-gateway paths and for the exposed `content-disposition` header — would be wrong for real origins.)
- Evidence: `grep -rn ALLOWED_ORIGINS` matches only cors.ts:14; .env.example has 0 occurrences; runbooks/staging-deploy.md and production-project.md list function secrets but not this variable.
- Fix: add `ALLOWED_ORIGINS=` with a comment to supabase/functions/.env.example and list it alongside the other function secrets in docs/runbooks/staging-deploy.md:44-46 and production-project.md:35.
- Plan item: backend brief item 7 (required config documented); ADR-30/ADR-35 wrapper contract.

## Summary table

| id | severity | title |
|---|---|---|
| F-backend-1 | minor | untracked .seed-pw at repo root is not gitignored |
| F-backend-2 | minor | ALLOWED_ORIGINS undocumented / absent from .env.example and runbooks |

Counts: blocker 0, major 0, minor 2.

## Verdict

DONE — all seven backend checklist areas pass with evidence. The phase's backend deliverables (reports Edge Function, ADR-43 export jobs with chunked/resumable slices and one-time downloads, R10 role matrix enforced in the database on every slice, ADR-29 envelope, ADR-31 idempotent job starts, ADR-33 idempotent consumer, BOM-prefixed Arabic-safe CSV with formula guard) are implemented as planned and exercised end-to-end against the running stack. The two findings are minor hygiene/documentation items with exact fixes. The only acceptance item not locally verifiable is the 100k-row export benchmark (requires prod-like fixture data; wired into scheduled CI with explicit budgets), marked NOT VERIFIABLE LOCALLY per the common brief.