# Brief: Edge Functions backend architecture and conventions (linker)

Output: /Users/fahad/council/output/plan/backend.md

1. Function granularity and isolation: one function per bounded context (e.g. bookings, checkout, staff, catalogue, reports, notifications, webhooks) vs per action vs one router. The owner's requirement: a failing or redeploying function must not take down the rest. Weigh cold starts, deploy blast radius, shared code duplication, limits (check current Supabase limits: memory, CPU time, wall clock, payload). Propose the function list for the MVP and later phases.
2. Read/write paths: which operations the frontend does directly through supabase-js under RLS (simple reads, simple CRUD) and which must go through Edge Functions (multi-step transactions like booking with conflict checks, checkout, refunds, anything with side effects or secrets). Where Postgres functions (RPC) are the right tool for atomicity.
3. Function anatomy: folder layout (supabase/functions/<name>/, _shared/), request handling, routing inside a function, input validation (e.g. zod), auth (verify JWT, derive tenant/branch context from claims, never trust client-sent tenant ids), using the user's JWT client vs service role, error model (stable error codes, HTTP status mapping, i18n-ready messages), idempotency keys for mutations, logging and tracing, CORS.
4. Async and scheduled work: notifications (email/SMS/WhatsApp; suggest providers that work in Kuwait), reminders, pg_cron, queues (e.g. pgmq) vs database webhooks; retries and dead letters.
5. Payments: MVP manual payments; choose the online gateway for a later phase (compare Tap, MyFatoorah, and at least one more, with KNET support and webhook model), and define the webhook handling pattern.
6. Environments and delivery: local dev with Supabase CLI, branches/preview environments, secrets management, CI/CD (type check, lint, deno test, migration check, deploy per function), versioning of function APIs, backward compatibility with the frontend.
7. Observability and reliability: logs, error tracking, health checks, rate limiting/abuse protection, timeouts.
8. Diagrams: component diagram (frontend, Supabase services, functions, third parties) and sequence diagrams for "book appointment" and "checkout with cash".

Draft the skill `supabase-edge-functions`: how to create a new function, file layout, shared modules, request/response and error conventions, auth and tenant context, validation, DB access rules, idempotency, testing with deno test, local run and deploy commands.

Add your "Proposed decisions" section.
