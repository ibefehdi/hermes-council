# Final plan round: common brief

The council has produced a plan (round 1) and revised it after an adversarial review (round 2). This round goes over the revised plan one last time and produces a single, self-contained `/Users/fahad/council/output/plan/PLAN.md`: the document a team (or an AI agent in the new repo) builds the product from. Someone who reads only PLAN.md must understand what is being built, why each decision was made, how it compares to Fresha, and in what order to build it.

## Product (unchanged)

Multi-tenant spa/salon SaaS. Tenant = company; SpaCorner is the first tenant, with multiple branches that each have their own staff, hours and services (price and duration per branch). Supabase, with all server logic in isolated Edge Functions (Deno), and a React + TypeScript frontend. English + Arabic with full RTL from day one. KWD with 3 decimals, per-branch time zone. MVP = core ops with cash/manual payments; an online gateway in a later phase. Visual design comes from the owner's external design skill, so do not define visuals.

## Inputs

- Revised plan in `/Users/fahad/council/output/plan/`: `decisions.md`, `IMPLEMENTATION_PLAN.md`, `CONVENTIONS.md`, `sql/`, `skills/`, `REVISION_LOG.md`.
- Earlier round material: `requirements.md`, `data-model.md`, `backend.md`, `frontend.md`, `review.md`, `review2/*.md` (including `adjudication.md`), `round1/`.
- Fresha evidence: `/Users/fahad/council/output/TECHNICAL_REPORT.md`, `FINAL_REPORT.md`, `pages.json`, `links.md`, `output/technical/*.md`.
- Product definition: `/Users/fahad/council/output/plan/briefs/common.md`.

Where documents disagree, the precedence is: `decisions.md` (revised) > `REVISION_LOG.md` / `review2/adjudication.md` > `IMPLEMENTATION_PLAN.md` / `CONVENTIONS.md` > round 1 member files. If you find a remaining contradiction or mistake, do not paper over it: record it in a "Residual issues" section of your draft using the round 2 finding format (`### F-final-<area>-<n>` with Severity, Location, Problem, Evidence, Fix, Affects).

## Rules

- Write only your own draft under `/Users/fahad/council/output/plan/final/drafts/`, incrementally (append section by section), in Markdown that can be pasted into PLAN.md as is.
- Clean room: compare with Fresha's behaviour, never copy its UI, text, branding or API shapes.
- Fresha claims must cite the evidence file and section (for example `technical/flows.md § Checkout`). Supabase, Deno, Postgres or provider claims that a decision depends on must be verified with web search and cite the URL.
- Diagrams are Mermaid only. Validate every file you write with `node /Users/fahad/council/check-mermaid.mjs <file>` and fix until it passes. Keep each diagram readable (split large ones by area rather than drawing one giant chart).
- Use the canonical names from `spa-domain-glossary` and the canonical phase numbering from the revised `IMPLEMENTATION_PLAN.md`.
- Write for a reader who was not in the council: plain language first, then the technical detail.
