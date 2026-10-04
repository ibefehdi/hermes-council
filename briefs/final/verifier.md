# Verifier: final round

Output: `{{COUNCIL_DIR}}/output/plan/final/verification.md`

Read the four drafts in `{{COUNCIL_DIR}}/output/plan/final/drafts/` (`parity.md`, `architecture-uml.md`, `reasoning.md`, `phases.md`) against the revised plan files and the Fresha evidence.

1. Consistency: the drafts must agree with each other and with the revised `decisions.md` and `sql/` (names, phase.subphase numbers, roles, enforcement points, money and time-zone rules). List every mismatch with both locations.
2. Fresha claims: spot-check at least 20 parity rows and every "Fresha does X" statement in the reasoning digest against the evidence files. Wrong or unsupported claims are findings.
3. Diagrams: run `check-mermaid.mjs` on every draft, and check the diagrams are correct (for example the ER diagram matches the SQL, sequence diagrams match the data access map).
4. Extra features: are they placed in sensible phases, do they keep the MVP intact, and are their dependencies real?
5. Residual issues: rule on every `F-final-*` finding in the drafts (accept with fix, or reject with reason), and add your own.
6. End with instructions for the chair: the ordered list of fixes to apply while assembling PLAN.md, and any changes that must also go into `decisions.md`, `CONVENTIONS.md` or the skills.

Your gate is the verification itself. Once `verification.md` is complete, complete your task even if it lists problems: fixing them is the chair's job, and the chair cannot start until you complete. Block only if a draft is missing or clearly incomplete, naming it.
