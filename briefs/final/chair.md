# Chair: assemble PLAN.md

Inputs: the four drafts in `{{COUNCIL_DIR}}/output/plan/final/drafts/` and `{{COUNCIL_DIR}}/output/plan/final/verification.md` (authoritative for fixes).

## Build PLAN.md in parts

PLAN.md will be long. Write each top-level section as its own file in `{{COUNCIL_DIR}}/output/plan/final/parts/` named `NN-<slug>.md` (01, 02, ...), applying the verifier's fixes as you go, then assemble with the terminal: `cat {{COUNCIL_DIR}}/output/plan/final/parts/*.md > {{COUNCIL_DIR}}/output/plan/PLAN.md`. Reuse the drafts' text and diagrams wherever they are correct; do not summarise them away.

Sections, in order:

1. Title, one-page executive summary, how to read this document, and a table of contents.
2. Product: vision, tenants and branches, roles, MVP scope, what is out of scope and why.
3. Fresha parity matrix and coverage numbers.
4. Beyond Fresha: the extra features, with the problem each solves and its phase.subphase.
5. User journeys per role.
6. Architecture: context, containers, deployment, environments, Edge Function isolation.
7. Domain model: class and ER diagrams per area, matching the corrected migrations in `sql/v2/` (list them with what each does, and the checker result).
8. Key flows: sequence and state diagrams.
9. Security and multi-tenancy: roles x actions x enforcement, isolation attack paths and how each is closed, data access map.
10. Decisions and reasoning: every ADR in plain language with why, alternatives, and the Fresha comparison.
11. Delivery plan: every phase with its subphases (`<phase>.<n>`), each with goal, features, DB, functions, screens, i18n/RTL, acceptance criteria, tests, backlog tasks and dependencies; then the dependency diagrams and the gantt chart.
12. Go-live checklist for SpaCorner, and the risk register.
13. What the council found: the narrative and the findings table across rounds, including this round's residual issues and how they were resolved.
14. Open questions for the owner, with recommended answers.
15. Appendix: conventions summary, skills index (name, what it covers, when it triggers), glossary, and the list of source documents.

## Keep the rest consistent

If an accepted fix changes a decision, a convention, or what a skill teaches, also update `decisions.md` (add `Revised in final round: <ids>`), `CONVENTIONS.md`, and the skills (edit one copy, then copy it over the other so `.cursor` and `.claude` stay identical). Append a "Final round" section to `REVISION_LOG.md` listing every change.

## Validate

Run `node {{COUNCIL_DIR}}/check-mermaid.mjs {{COUNCIL_DIR}}/output/plan/PLAN.md` and on every other file you changed, `node {{COUNCIL_DIR}}/check-skills.mjs {{COUNCIL_DIR}}/output/plan/skills`, and, if you changed any SQL, `node {{COUNCIL_DIR}}/check-sql.mjs {{COUNCIL_DIR}}/output/plan/sql/v2/migrations {{COUNCIL_DIR}}/output/plan/sql/v2/tests`. Fix until both pass. Check that PLAN.md contains every section above and that no phase is missing subphases.

Never modify the Fresha reports (`output/*.md`, `output/*.json`, `output/technical/`), the round 1 member files, `round1/`, `review2/`, or the drafts.
