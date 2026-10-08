#!/usr/bin/env zsh
# Copy the council's CI merge gates (workflows, the main ruleset, new tests) into an app repository.
# Usage: ./install-ci.sh /path/to/app-repo
[ -n "${ZSH_VERSION:-}" ] || exec zsh "$0" "$@"
set -euo pipefail

DIR="${0:A:h}"
SRC="$DIR/output/ci/draft"
DEST="${1:?Usage: ./install-ci.sh /path/to/app-repo}"
DEST="${DEST:A}"
[[ -d $DEST/.git ]] || { print "Not a git repository: $DEST"; exit 1; }
[[ -d $SRC/.github ]] || { print "No draft in $SRC. Run ./run-council.sh ci $DEST first."; exit 1; }

node "$DIR/check-ci.mjs" "$SRC" "$DEST"
[[ -n $(git -C "$DEST" status --porcelain) ]] && print "Note: $DEST has uncommitted changes; the CI files will be mixed in with them."
cp -R "$SRC/." "$DEST/"

REMOTE=$(git -C "$DEST" remote get-url origin 2>/dev/null | sed -nE 's#^(git@github\.com:|https://github\.com/)([^/]+/[^/]+)$#\2#p' | sed 's#\.git$##')
print "
Copied $(cd "$SRC" && find . -type f | wc -l | tr -d ' ') file(s) into $DEST. Next:
  1. Commit them on a branch, push, and open a pull request into main (see output/ci/CI_REPORT.md, Install).
  2. Merge once the required check is green.
  3. Then make the checks required for main:
       gh api --method POST repos/${REMOTE:-<owner>/<repo>}/rulesets --input .github/rulesets/main.json"
