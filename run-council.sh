#!/usr/bin/env zsh
# Usage: ~/council/run-council.sh ["optional extra focus for this run"]
set -euo pipefail

DIR="${0:A:h}"
cd "$DIR"
DASHBOARD_URL=$(grep '^DASHBOARD_URL=' "$DIR/.env" 2>/dev/null | tail -1 | cut -d= -f2- | tr -d "\"'")
: "${DASHBOARD_URL:?Set DASHBOARD_URL in $DIR/.env}"

node "$DIR/login.mjs"

mkdir -p runs
if [[ -d output && -n "$(ls -A output 2>/dev/null)" ]]; then
  mv output "runs/$(date +%Y%m%d-%H%M%S)"
fi
mkdir -p output screenshots

FOCUS="${1:-Cover the entire dashboard.}"
GOAL="Map the dashboard at $DASHBOARD_URL: every page, every feature on each page, and how features link to each other. $FOCUS Final deliverable: $DIR/output/FINAL_REPORT.md"

hermes kanban init >/dev/null
hermes kanban swarm "$GOAL" \
  --worker "cartographer:Inventory every page and feature of $DASHBOARD_URL into $DIR/output/pages.md and pages.json" \
  --worker "linker:Map how features connect (navigation, shared entities, data flows, shared APIs) into $DIR/output/links.md" \
  --verifier verifier \
  --synthesizer chair

hermes config set kanban.dispatch_interval_seconds 15 >/dev/null
if ! hermes gateway status 2>&1 | grep -q "is running"; then
  nohup hermes gateway run > "$DIR/gateway.log" 2>&1 &
  sleep 10
fi

echo "Council started. Report will be at: $DIR/output/FINAL_REPORT.md (Ctrl-C stops watching, not the council)"
hermes kanban watch
