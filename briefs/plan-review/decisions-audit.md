# Decisions and conventions audit

Output: `{{COUNCIL_DIR}}/output/plan/review2/decisions-audit.md`

Audit `decisions.md` and `CONVENTIONS.md` against everything else.

1. Go through every ADR one by one. For each, give a verdict: keep, change, or reverse, with a reason. Challenge the decision itself, not just its wording: is it the right call for a multi-tenant spa SaaS in Kuwait that starts with one customer and must scale to many? Is a better option missing from Alternatives? Are the Consequences honest?
2. Coverage of decisions: list decisions the project will need that have no ADR (for example tenant onboarding and data export, backups and restore, audit log, soft delete vs hard delete, ID strategy, time zone storage, currency per tenant, file storage, search, rate limiting, feature flags, environments, data residency, error format, versioning of functions and API).
3. Consistency: every rule in `CONVENTIONS.md` must agree with `decisions.md`, the SQL drafts, `backend.md`, `frontend.md`, `IMPLEMENTATION_PLAN.md`, and the seven skills. List every contradiction with both locations quoted.
4. Round 1 review follow-up: for each issue raised in `review.md`, check whether `decisions.md` actually resolved it. Unresolved issues are findings.
5. Verify any factual claim an ADR relies on (Supabase limits and features, Deno support, provider capabilities) on the web and cite the URL.
