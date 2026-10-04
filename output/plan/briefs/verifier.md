# Brief: Challenge the design (verifier)

Output: /Users/fahad/council/output/plan/review.md

Inputs: requirements.md, data-model.md, sql/*.sql, backend.md, frontend.md, skill-drafts/*.md in /Users/fahad/council/output/plan/.

Act as the council's sceptic. For every "Proposed decision" (PD-...):

1. Check it against the requirements (multi-tenant, multi-branch, Arabic/RTL, MVP scope, function isolation) and against the other areas' decisions. Flag conflicts explicitly (e.g. frontend assumes direct table writes that the backend routes through a function; RLS claims the data model does not define).
2. Verify factual claims about Supabase, Deno, libraries, and payment gateways against current official docs (web search; cite URLs). Flag anything outdated or wrong.
3. Give a verdict per decision: AGREE / AGREE WITH CHANGES (say what) / DISAGREE (give the alternative and why).

Also review:

- Tenant isolation: try to find a path where one tenant could read or write another tenant's data, or a branch-scoped user could reach another branch (RLS gaps, service-role misuse, Realtime channel leaks, Storage paths).
- Booking integrity: double booking, time zone and DST mistakes, concurrent edits.
- SQL drafts: obvious errors, missing indexes on tenant_id/branch_id, missing RLS on any table.
- Skill drafts: conflicts with each other or with the decisions; vague rules; missing "how to add X" steps.
- MVP scope: anything essential missing for SpaCorner to run its branches day to day; anything that should move later.

Sections of review.md: Summary, Decision verdicts table, Conflicts between areas, Security and tenancy findings, Booking/time findings, SQL review, Skill review, Scope review, Open questions for the owner.
