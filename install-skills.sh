#!/usr/bin/env zsh
# Copy the council's Cursor and Claude skills into an app repository.
# Usage: ./install-skills.sh /path/to/app-repo
[ -n "${ZSH_VERSION:-}" ] || exec zsh "$0" "$@"
set -euo pipefail

DIR="${0:A:h}"
SRC="$DIR/output/plan/skills"
DEST="${1:?Usage: ./install-skills.sh /path/to/app-repo}"
[[ -d $DEST ]] || { print "No such directory: $DEST"; exit 1; }

node "$DIR/check-skills.mjs" "$SRC"
for tool in .cursor .claude; do
  mkdir -p "$DEST/$tool/skills"
  cp -R "$SRC/$tool/skills/." "$DEST/$tool/skills/"
done
print "Installed $(ls "$SRC/.cursor/skills" | wc -l | tr -d ' ') skills into $DEST/.cursor/skills and $DEST/.claude/skills"
