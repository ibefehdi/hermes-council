# Chair: apply round 2 fixes

Inputs: `{{COUNCIL_DIR}}/output/plan/review2/adjudication.md` (authoritative) and the reviewer files it refers to.

1. Before changing anything, snapshot round 1 with the terminal: `mkdir -p {{COUNCIL_DIR}}/output/plan/round1 && cp -R {{COUNCIL_DIR}}/output/plan/decisions.md {{COUNCIL_DIR}}/output/plan/IMPLEMENTATION_PLAN.md {{COUNCIL_DIR}}/output/plan/CONVENTIONS.md {{COUNCIL_DIR}}/output/plan/skills {{COUNCIL_DIR}}/output/plan/sql {{COUNCIL_DIR}}/output/plan/round1/`. Skip this if `round1/` already exists.
2. Apply every accepted fix from the adjudication, in its order, to `decisions.md`, `IMPLEMENTATION_PLAN.md`, `CONVENTIONS.md`, the SQL drafts in `sql/`, and the skills. Edit files in place; keep their structure. Changed ADRs get a `Revised in round 2: <finding ids>` line; reversed ADRs are marked `Superseded by ADR-<n>` and the new ADR is added. Do not apply rejected findings.
3. Skills must stay identical in `skills/.cursor/skills/` and `skills/.claude/skills/`: edit one copy, then copy it over the other.
4. Write `{{COUNCIL_DIR}}/output/plan/REVISION_LOG.md`: one row per finding (id, severity, ruling, what changed, files), plus a short summary of the biggest changes and anything deliberately left open with the reason.
5. Validate: `node {{COUNCIL_DIR}}/check-skills.mjs {{COUNCIL_DIR}}/output/plan/skills` and `node {{COUNCIL_DIR}}/check-mermaid.mjs` on every changed Markdown file. Fix until both pass.
6. Never modify the reverse-engineering reports (`output/*.md`, `output/*.json`, `output/technical/`), the round 1 member files (`requirements.md`, `data-model.md`, `backend.md`, `frontend.md`, `review.md`), or anything in `review2/` and `round1/`.
