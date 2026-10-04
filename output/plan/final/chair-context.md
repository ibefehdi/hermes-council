# Chair context for PLAN.md part writers (final round)

You are one of four writers assembling `/Users/fahad/council/output/plan/PLAN.md` from the verified final-round drafts. PLAN.md is the single self-contained document a team (or an AI agent in a fresh repo) builds the product from. Someone who reads only PLAN.md must understand what is being built, why each decision was made, how it compares to Fresha, and in what order to build it.

## Product (canonical)

GlowDesk: multi-tenant spa/salon SaaS. Tenant = company; SpaCorner is the first tenant, with multiple branches that each have their own staff, hours and services (price and duration per branch). Supabase backend with all server logic in isolated Edge Functions (Deno); React + TypeScript frontend. English + Arabic with full RTL from day one. KWD money as integer minor units (3 decimals, `_minor bigint` columns). Per-branch IANA time zone. MVP = back-office core operations with cash/manual payments (plan Phases 0-8); online booking is Phase 9, payment gateway Phase 10. Visual design comes from the owner's external design skill, so PLAN.md never defines visuals.

## Canon and precedence

- Canonical phase numbering: plan Phases 0-17, MVP = 0-8. Never use old release-bucket language.
- Membership roles are exactly: tenant_owner, branch_manager, receptionist, staff. Platform operations = audited, time-boxed impersonation path, never a fifth in-app role.
- Canonical entity names come from the spa-domain-glossary skill (`/Users/fahad/council/output/plan/skills/.claude/skills/spa-domain-glossary/SKILL.md`).
- Where documents disagree: `decisions.md` (revised) > `REVISION_LOG.md` / `review2/adjudication.md` > `IMPLEMENTATION_PLAN.md` / `CONVENTIONS.md` > round 1 member files.
- Fresha claims must keep their evidence citations (e.g. `technical/flows.md § Checkout`). Never copy Fresha UI, text, branding or API shapes.

## Chair decisions (final round, binding - apply everywhere relevant)

1. pg_net: added to the v2 extension set (`000001_enable_extensions.sql`, inside the check-sql skip block), to Phase 0 infrastructure work, and to the supabase-database skill extension list. ADR-33's pg_cron -> Edge Function invocation via pg_net stands. (SQL already applied by the chair.)
2. Full-tenant export (Phase 7.3) is a chunked, resumable queued job via pgmq. Each Edge Function invocation stays below the wall-clock limit (150s free / 400s paid). The <=10-minute benchmark measures end-to-end job completion, including final-part assembly and the download mechanism. Link chunking to pgmq visibility timeouts, retry/idempotency.
3. `appointments.during` and `appointment_items.busy_range` are trigger-maintained in v2 (PGlite compatibility). Do not call them generated columns. Cancellation/no-show must clear the busy range via the `status_active` transition, owned by the booking RPC contract; Phase 5 tests the cancellation/reschedule races explicitly.
4. Idempotency uniqueness is now `UNIQUE(tenant_id, key, function_name)` (applied in `000009_create_sales.sql` + test `003_final_round_fixes.sql`). Phase 6 adds an action/function-mismatch replay test. ADR-31 is marked revised in the final round.
5. Opening-hours semantics: `closes_at < opens_at` = overnight; `opens_at = closes_at` is rejected by constraint `boh_nonzero_length` unless `is_closed = true`; a 24-hour day is expressed as 00:00-23:59; a closed day uses `is_closed`. (Applied in `000003_create_branches.sql` + test 003.) Phase 1/5 fixtures include zero-length rejection and overnight cases. ADR-26 marked revised in the final round.
6. MVP staff time-off = manager-created blocked-time blocks using the existing blocked_time model. No request/approval state in MVP. A staff request/approval flow is a post-MVP candidate (Phase 13 scheduling) requiring an ADR revision. New ADR-53 records this choice. Role matrix wording: staff view their own blocked time; managers create/remove blocks.
7. Corporate/house accounts: uncommitted beyond-Fresha candidate, no phase placement; requires a new ADR when scheduled. Never present as delivered scope.
8. Post-MVP (Phases 9-17) expanded subphase backlogs are illustrative scheduling input, not binding commitments (convention F-PLAN-17 stands). MVP Phases 0-8 backlogs ARE binding.
9. `resolve_service`: convert to `RETURNS TABLE` before production (noted as a Phase 1/3 task); the v2 validation set keeps `returns record`.
10. Fresha report count: canonical is 59 per `technical/reports.md`; the 58-vs-59 card discrepancy stays recorded as UNVERIFIED (F-final-parity-5). Do not claim every card was individually verified.
11. F-final-db-2 and F-final-db-4 are closed as stale schema findings (v2 already has `idx_rs_one_open` partial unique index and `UNIQUE(branch_id, kind)` on invoice_counters); retain them as documentation/concurrency-test checks (Phase 6 named concurrency test; ADR/plan mentions the counter constraint).
12. SQL v2 validation status (for citation): 12 migrations apply cleanly on the PGlite checker; 33 public tables, 33 with RLS; tests 001_tenant_isolation, 002_branch_isolation, 003_final_round_fixes all pass; the `public.idempotency_keys` deny-all RLS warning is intentional (client-inaccessible mutation table, select-only grant).

## Writing rules

- Write ONLY your assigned part file(s) under `/Users/fahad/council/output/plan/final/parts/`, named exactly as assigned (`NN-slug.md`). Do not modify drafts, briefs, sql/, decisions.md, or any other file.
- Reuse the drafts' text and diagrams wherever correct; do not summarise them away. Copy full detail (tables, diagrams, acceptance criteria). Adjust heading levels so each part starts with `## ` (only part 01 starts with the `# ` document title).
- PLAN.md must be self-contained: never write "see draft X" or "see verification.md". Reference sibling PLAN sections by name instead, and cite evidence files (Fresha corpus, ADR ids) directly.
- Style: plain language first, then technical detail. Sentence-case headings. No AI-slop vocabulary ("delve", "showcase", "landscape", "testament", "crucial"), no emoji, minimal boldface, no walls of inline-header bullets. Vary sentence rhythm. Write for a reader who was not in the council.
- Diagrams: Mermaid only. After writing a part that contains mermaid blocks, run `node /Users/fahad/council/check-mermaid.mjs <your-part-file>` and fix until it passes. Do not modify the checker.
- Apply the verifier rulings in `/Users/fahad/council/output/plan/final/verification.md` that touch your sections (read it).
- When done, reply with a SHORT summary: files written, line counts, mermaid check result, which chair decisions/fixes you applied, and anything you could not resolve.
