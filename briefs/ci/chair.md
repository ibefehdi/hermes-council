# Chair: write the CI merge-gates report

Inputs:

- `{{CI_DIR}}/adjudication.md` (authoritative).
- `baseline/BASELINE.md`, `traceability.md`, `pipeline.md` and the three `tests-*.md` files.
- The final draft in `{{CI_DIR}}/draft/`.

Output: `{{CI_DIR}}/CI_REPORT.md`. Do not change the draft, and leave the repository at `{{REPO}}` read-only.

Write for the product owner first and the coding agent second: full sentences, no internal shorthand, every claim traceable to evidence. Structure:

1. **Verdict.** `READY`, `READY AFTER FIXES` or `NOT READY`, exactly as the verifier decided. Then one paragraph in plain language: what will now stop a bad change from reaching `main`, how long a pull request will wait for CI, and what defects the new tests found.
2. **What was analysed.** Repository path, branch, commit, the built phases and subphases that are gated, and the date.
3. **What blocks a merge into main.** The required check, and a table of the jobs behind it: job | what it proves | plan items and CONVENTIONS rules | duration measured in the replay. Add the job graph as Mermaid.
4. **Traceability.** For each built subphase: the acceptance criteria and Tests bullets, with how many were already proven, how many are proven by new tests, and how many remain open and why. Then the guard tests that protect every future PR: RLS on every table, safe definer functions, route auth, catalog parity and the others.
5. **New tests.** The accepted tests grouped by area (database, Edge Functions, frontend). For each: file, what it proves, the gap it closes, and the mutation that proved it can fail.
6. **Defects found.** Each `KNOWN-FAILING` test: the defect, the plan item or ADR it violates, the reproduction, and the fix. CI will be red until these are fixed.
7. **Rejected tests.** One line each, with the reason, so nobody re-adds them.
8. **Future gates.** Gaps deferred and work not yet built, and the tests each will need when it lands.
9. **Plan amendments.** Changes the plan or CONVENTIONS should take, at least E2E as a required check on PRs into `main`. Phrase each as the exact text to change.
10. **Install.** The exact steps:
    1. `{{COUNCIL_DIR}}/install-ci.sh {{REPO}}` copies the draft into the repository.
    2. Create a branch (CONVENTIONS §8 naming), commit with a Conventional Commit, push, and open a PR into `main`.
    3. Wait for the aggregator check to go green on that PR. This also meets the Phase 0 exit criterion of CI going green on a PR, when the PR touches a function and a component.
    4. Merge it.
    5. Only then apply the ruleset: `gh api --method POST repos/<owner>/<repo>/rulesets --input .github/rulesets/main.json`, with `<owner>/<repo>` filled in from the `origin` URL.
    6. Confirm the ruleset with `gh api repos/<owner>/<repo>/rulesets`.

    Note the plan requirement for private repositories, from `pipeline.md`.
11. **Fix prompt.** A ready-to-paste prompt for the coding agent (Cursor) that installs the gates and fixes every confirmed defect in the same PR. Use this shape and fill it in:

    ```text
    Install the CI merge gates and fix the defects they found in {{REPO}}.
    The gate files are already copied in by install-ci.sh: <list of files>.
    Context: @plan/parts/11-delivery-plan.md @plan/decisions.md @plan/CONVENTIONS.md
    Skills: /feature-delivery /spa-domain-glossary /spa-platform-architecture <area skills these fixes touch>

    1. <defect / test id>: <file> - <exact change>
    ...

    Rules: never edit an applied migration (add a new one); do not weaken or delete any new test to
    make it pass; keep both skill copies identical; Conventional Commits. Done = every job of
    .github/workflows passes locally the way pipeline.md describes, and the PR's ci check is green.
    ```

    If the verdict is `READY`, the prompt only covers committing the files and opening the PR.

Keep the report under about 600 lines; link to the worker files for detail rather than copying them.
