# Verifier: adjudicate round 2 findings

Output: `{{COUNCIL_DIR}}/output/plan/review2/adjudication.md`

Read the four reviewer files in `{{COUNCIL_DIR}}/output/plan/review2/` (`coverage.md`, `data-backend.md`, `decisions-audit.md`, `plan-skills-audit.md`) and the round 1 files they refer to.

1. For every finding, rule: accept, accept with changes (state the changed fix), or reject (state why, with evidence). Re-check factual claims on the web where a ruling depends on them and cite the URL. Reviewers can be wrong; do not accept a finding just because it sounds serious.
2. Merge duplicates and resolve conflicts between reviewers' fixes so the chair receives one consistent instruction per issue.
3. Do your own sweep for anything all four reviewers missed, especially tenant isolation, double booking, money, RTL, and contradictions between documents. Add these as `F-verifier-<n>` findings with fixes.
4. If a reviewer file is missing or clearly incomplete, block the task with a note naming it instead of passing.
5. End with the ordered fix list for the chair: blockers first, then majors, then minors, each with the finding id, the files to change, and the exact change.
