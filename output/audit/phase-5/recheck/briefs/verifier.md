# Verifier: adjudicate the re-check

Output: `/Users/fahad/council/output/audit/phase-5/recheck/adjudication.md`

Read `/Users/fahad/council/output/audit/phase-5/recheck/gates/GATES.md`, `/Users/fahad/council/output/audit/phase-5/recheck/recheck.md`, and the previous `/Users/fahad/council/output/audit/phase-5/adjudication.md` and `/Users/fahad/council/output/audit/phase-5/AUDIT_REPORT.md`.

1. Confirm the checklist in `recheck.md` contains every accepted finding, every failed or missing gate, and every criterion not rated `DONE` in the previous audit. If anything is missing, block the task with a note naming it.
2. Rule on every item: accept the status, or overturn it with evidence. Re-check yourself every item marked `FIXED` that was a blocker or major, every gate, and every new blocker or major. Open the test diffs for any test-related finding: a gate made green by weakening a test is `NOT FIXED` plus a blocker.
3. Rule on every new `F-RC` finding: accept, accept with changes, or reject with evidence. Then do your own sweep of the fix diff for regressions the re-checker missed, especially tenant and branch isolation, edited migrations and tests that cannot fail, and add them as `F-RC-verifier-<n>`.
4. Decide the verdict with the same rule as the audit, so the two are comparable, and state it at the top next to the previous verdict:
   - `FAIL`: any previous blocker not `FIXED`, any accepted new blocker, any failing gate, or any exit or acceptance criterion still not `DONE` (excluding `NOT VERIFIABLE LOCALLY`).
   - `PASS WITH FIXES`: no blockers, but a previous major not `FIXED` or an accepted new major.
   - `PASS`: only minors remain, or nothing.
5. End with the ordered list of what still needs fixing: blockers first, then majors, then minors, each with the id, the files to change and the exact change.

The repository stays read-only for you as well. Complete your task once `adjudication.md` is written, whatever the verdict.
