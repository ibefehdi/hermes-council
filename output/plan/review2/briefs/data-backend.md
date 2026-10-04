# Data, security and backend audit

Output: `/Users/fahad/council/output/plan/review2/data-backend.md`

Audit `data-model.md`, every file in `sql/`, `backend.md`, the database and backend parts of `CONVENTIONS.md`, and the `supabase-database`, `supabase-edge-functions` and `spa-platform-architecture` skills.

1. Tenant isolation. For every table: is `tenant_id` present where needed, is RLS enabled, do the policies cover select/insert/update/delete, can a user of tenant A read or write tenant B rows through any path (direct supabase-js, RPC, views, storage, realtime, Edge Functions using the service role, foreign keys pointing across tenants)? Views must not bypass RLS (check `security_invoker`). Write each attack path you tried and its result.
2. Branch scoping. Can a branch manager or receptionist act on another branch? Can staff assigned to two branches see the right data in each?
3. Booking integrity. Check the exclusion constraints actually prevent staff and resource double booking (including buffers, cancelled appointments, multi-service appointments, and staff working at two branches at once), and that availability uses the branch time zone correctly across DST and midnight.
4. Money. KWD with 3 decimals everywhere (column types, rounding, sums in views), discounts, tips, refunds, partial payments, and that sale totals cannot be tampered with from the client.
5. SQL correctness. Read every migration as if running it on a fresh Supabase project: order of creation, missing indexes on foreign keys and RLS predicates, syntax errors, functions without `search_path` set, `security definer` misuse, missing `updated_at` triggers, and anything the round 1 review flagged that is still unfixed.
6. Edge Functions. Check function granularity and isolation (one failing or redeploying function must not take others down), auth handling (JWT verification, claims, service role use), idempotency for writes, timeouts and limits (verify current limits on the web), cold starts, shared code layout, local dev, CI/CD, secrets, logging and error format. Check that every MVP write path is assigned either to direct supabase-js under RLS, an RPC, or a function, and that the choice is consistent across documents.
7. Async and integrations. pg_cron, queues, notifications (SMS/WhatsApp/email in Kuwait), and the payment gateway decision: is the comparison accurate and current (verify on the web), and is the chosen gateway's integration shape (webhooks, refunds, KNET support) reflected in the later phase?
8. Skills. For the three skills above: would they teach correct, secure conventions? Flag anything that contradicts the SQL, `decisions.md` or `CONVENTIONS.md`.
