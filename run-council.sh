#!/usr/bin/env zsh
# Usage:
#   ./run-council.sh ["optional focus"]        survey: map pages/features/links -> output/FINAL_REPORT.md
#   ./run-council.sh deep ["optional focus"]   deep technical pass on top of the survey -> output/TECHNICAL_REPORT.md
[ -n "${ZSH_VERSION:-}" ] || exec zsh "$0" "$@"
set -euo pipefail

DIR="${0:A:h}"
cd "$DIR"

MODE=survey
if [[ ${1:-} == deep ]]; then
  MODE=deep
  shift
fi
FOCUS="${1:-Cover the entire dashboard.}"
OUT="$DIR/output"
TS=$(date +%Y%m%d-%H%M%S)

DASHBOARD_URL=$(grep '^DASHBOARD_URL=' "$DIR/.env" 2>/dev/null | tail -1 | cut -d= -f2- | tr -d "\"'")
: "${DASHBOARD_URL:?Set DASHBOARD_URL in $DIR/.env}"

OR_KEY=$(grep '^OPENROUTER_API_KEY=' "$DIR/.env" | tail -1 | cut -d= -f2- | tr -d "\"'")
: "${OR_KEY:?Set OPENROUTER_API_KEY in $DIR/.env}"
for f in ${$(hermes config path):h}/.env ${^${(f)"$(for r in cartographer linker verifier chair; do print -r -- "${$(hermes -p $r config path):h}"; done)"}}/.env; do
  { grep -v '^OPENROUTER_API_KEY=' "$f" 2>/dev/null || true; print -r -- "OPENROUTER_API_KEY=$OR_KEY"; } > "$f.tmp"
  mv "$f.tmp" "$f" && chmod 600 "$f"
done
# The gateway (default profile) uses this helper to triage stuck tasks; keep it off slow local models.
hermes config set auxiliary.kanban_decomposer.provider openrouter >/dev/null
hermes config set auxiliary.kanban_decomposer.model deepseek/deepseek-v4-flash >/dev/null

if [[ $MODE == deep && ! -f "$OUT/FINAL_REPORT.md" ]]; then
  print "Deep mode builds on a survey. Run ./run-council.sh first to produce $OUT/FINAL_REPORT.md."
  exit 1
fi

if ! node "$DIR/login.mjs" --check; then
  print "A browser window will open: log in (enter your OTP). The session is saved automatically."
  node "$DIR/login.mjs"
fi

mkdir -p runs screenshots

# Worker cards are parsed as PROFILE:TITLE:SKILLS, so titles must not contain ':' (keep URLs in the goal only).
if [[ $MODE == survey ]]; then
  if [[ -d output && -n "$(ls -A output 2>/dev/null)" ]]; then
    chmod -R u+w output
    mv output "runs/$TS"
  fi
  mkdir -p output
  REPORT="$OUT/FINAL_REPORT.md"
  GOAL="Map the dashboard at $DASHBOARD_URL: every page, every feature on each page, and how features link to each other. $FOCUS Final deliverable: $REPORT"
  WORKERS=(
    --worker "cartographer:Inventory every page and feature of the dashboard into $OUT/pages.md and pages.json"
    --worker "linker:Map how features connect (navigation, shared entities, data flows, shared APIs) into $OUT/links.md"
  )
else
  mkdir -p "runs/$TS-before-deep"
  cp -R output/. "runs/$TS-before-deep/"
  if [[ -d output/technical ]]; then
    chmod -R u+w output/technical
    mv output/technical "runs/$TS-before-deep/technical-previous"
  fi
  [[ -f output/TECHNICAL_REPORT.md ]] && mv output/TECHNICAL_REPORT.md "runs/$TS-before-deep/TECHNICAL_REPORT-previous.md"
  chmod a-w output/*.md output/*.json 2>/dev/null || true

  B="$OUT/technical/briefs"
  mkdir -p "$B"
  for f in briefs/deep/*.md; do
    sed "s|{{COUNCIL_DIR}}|$DIR|g" "$f" > "$B/${f:t}"
  done
  : > "$OUT/technical/test-records.md"

  REPORT="$OUT/TECHNICAL_REPORT.md"
  GOAL="Deep technical pass over the dashboard at $DASHBOARD_URL, building on the first survey in $OUT (FINAL_REPORT.md, pages.json, links.md, review.md are read-only baseline). Every member reads $B/common.md first, then its own brief. Verifier follows $B/verifier.md. Chair follows $B/chair.md. $FOCUS Final deliverable: $REPORT (FINAL_REPORT.md must remain unchanged)."
  WORKERS=(
    --worker "cartographer:Deep pass on Setup and all settings pages - follow briefs $B/common.md and $B/settings.md"
    --worker "cartographer:Deep pass on every report - follow briefs $B/common.md and $B/reports.md"
    --worker "cartographer:Resolve everything the first survey missed - follow briefs $B/common.md and $B/gaps.md"
    --worker "linker:Exercise create and edit flows with COUNCIL-TEST data - follow briefs $B/common.md and $B/flows.md"
    --worker "linker:Architecture, API catalogue, data model, page connectivity - follow briefs $B/common.md and $B/architecture.md"
  )
fi

hermes kanban init >/dev/null
if [[ $MODE == survey ]]; then
  hermes kanban swarm "$GOAL" "${WORKERS[@]}" --verifier verifier --synthesizer chair
else
  # Seed data first; workers depend on it. Dispatch is paused while dependencies are wired so nothing starts early.
  hermes pause --reason "wiring council dependencies" >/dev/null
  trap 'hermes resume >/dev/null 2>&1' EXIT
  json_field() { python3 -c "import json,sys; d=json.load(sys.stdin); v=d$1; print(' '.join(v) if isinstance(v, list) else v)"; }
  SEED=$(hermes kanban create "Seed realistic COUNCIL-TEST data - follow briefs $B/common.md and $B/seed.md" \
    --assignee linker --body-file "$B/seed.md" --json | json_field '["id"]')
  SWARM=$(hermes kanban swarm "$GOAL" "${WORKERS[@]}" --verifier verifier --synthesizer chair --json)
  for w in ${=$(print -r -- "$SWARM" | json_field '["worker_ids"]')}; do
    hermes kanban link "$SEED" "$w" >/dev/null
  done
  print "Seed: $SEED  Workers: $(print -r -- "$SWARM" | json_field '["worker_ids"]')  Verifier: $(print -r -- "$SWARM" | json_field '["verifier_id"]')  Chair: $(print -r -- "$SWARM" | json_field '["synthesizer_id"]')"
  hermes resume >/dev/null
  trap - EXIT
fi

hermes config set kanban.dispatch_interval_seconds 15 >/dev/null
hermes config set kanban.failure_limit 4 >/dev/null
hermes config set kanban.max_in_progress 6 >/dev/null
if ! hermes gateway status 2>&1 | grep -q "is running"; then
  nohup hermes gateway run > "$DIR/gateway.log" 2>&1 &
  sleep 10
fi

echo "Council started ($MODE). Report will be at: $REPORT (Ctrl-C stops watching, not the council)"
hermes kanban watch
