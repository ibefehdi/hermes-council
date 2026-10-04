# Decisions, reasoning and council findings

Output: `{{COUNCIL_DIR}}/output/plan/final/drafts/reasoning.md`

1. Decision digest. For every ADR in the revised `decisions.md`, in plain language: what we decided; why (the problem it solves and the trade-off accepted); the alternatives considered and why they lost; how Fresha appears to handle the same thing (with evidence reference) and why we match or differ; what it means for the people building it. Group by area, and mark decisions revised or superseded in round 2 with what changed.
2. The council's findings. A narrative of what the council found across both rounds: the most important problems caught (tenant isolation, double booking, money and refunds, permissions, time zones, RTL, phase ordering, skills), who found them, how the verifier ruled, and how each was resolved. Include a table of every round 2 finding (id, severity, ruling, resolution, where it now lives in the plan) built from `review2/adjudication.md` and `REVISION_LOG.md`, and flag any accepted finding that the revision did not actually apply.
3. A final independent pass. Re-read the revised `decisions.md`, `CONVENTIONS.md` and `IMPLEMENTATION_PLAN.md` end to end as a fresh reviewer and look for anything still wrong or missing: contradictions, unsafe defaults, missing decisions, unrealistic sizes. Verify facts on the web where needed.
4. Open questions that only the owner can answer, each with the council's recommended answer.
5. Residual issues found while doing the above.
