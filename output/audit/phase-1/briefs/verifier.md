# Verifier: adjudicate the phase audit

Output: `/Users/fahadasad/hermes-council/output/audit/phase-1/adjudication.md`

Read `/Users/fahadasad/hermes-council/output/audit/phase-1/gates/GATES.md` and the four auditor files: `database.md`, `backend.md`, `frontend.md`, `conformance.md`.

1. For every finding, rule: accept, accept with changes (state the changed severity or fix), or reject (state why, with evidence). Re-check each blocker and major yourself in the repository or against the local stack; re-check factual claims on the web where a ruling depends on them and cite the URL. Auditors can be wrong in both directions: reject findings that misread the plan or ignore an ADR that allows the behaviour, and raise severity where an auditor underrated a tenant-isolation or money issue.
2. Check the checklist in `conformance.md` covers every subphase of phase 1 in `/Users/fahadasad/glowdesk/plan/parts/11-delivery-plan.md` and the phase exit criteria; a missing subphase means the audit is incomplete (block, as in item 4 below). Spot-check at least every `DONE` acceptance criterion and a sample of at least 30% of the other `DONE` rows by opening the evidence. Overturn any status that does not hold.
3. Merge duplicate findings across auditors and resolve conflicting fixes so each issue has one instruction.
4. Do your own sweep for what all four missed, especially cross-tenant and cross-branch leaks, privileged paths, tests that cannot fail, and gates that were skipped. Add these as `F-verifier-<n>`.
5. Decide the verdict using this rule, and state it at the top:
   - `FAIL`: any accepted blocker, any acceptance criterion of any subphase or any phase exit criterion not `DONE` (excluding `NOT VERIFIABLE LOCALLY`), or any failing gate.
   - `PASS WITH FIXES`: no blockers, but at least one accepted major.
   - `PASS`: only minors or nothing.
6. End with the ordered fix list: blockers first, then majors, then minors, each with the finding id, the files to change and the exact change.

The repository stays read-only for you as well. If an auditor file is missing or clearly incomplete, block the task with a note naming it. Otherwise complete your task once `adjudication.md` is written, whatever the verdict.
