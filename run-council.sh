#!/usr/bin/env zsh
# Usage:
#   ./run-council.sh ["optional focus"]        survey: map pages/features/links -> output/FINAL_REPORT.md
#   ./run-council.sh deep ["optional focus"]   deep technical pass on top of the survey -> output/TECHNICAL_REPORT.md
#   ./run-council.sh plan ["optional focus"]   design council: phase plan, decisions, conventions, Cursor/Claude skills -> output/plan/
#   ./run-council.sh review ["optional focus"] adversarial cross-review of the plan, then the chair applies accepted fixes
#   ./run-council.sh final ["optional focus"]  last pass: one self-contained output/plan/PLAN.md (phases and subphases, UML,
#                                               reasoning, Fresha parity, extra features)
#                                               (review and final wait for an unfinished plan chair automatically)
#   ./run-council.sh audit <phase> <repo> ["optional focus"]
#                                               audit whether a full plan phase (e.g. 0 or 5, every subphase plus the exit
#                                               criteria) is properly implemented in a local app repo
#                                               -> output/audit/phase-<phase>/AUDIT_REPORT.md
[ -n "${ZSH_VERSION:-}" ] || exec zsh "$0" "$@"
set -euo pipefail

DIR="${0:A:h}"
cd "$DIR"

MODE=survey
if [[ ${1:-} == (deep|plan|review|final|audit) ]]; then
  MODE=$1
  shift
fi
if [[ $MODE == audit ]]; then
  AUDIT_USAGE='Usage: ./run-council.sh audit <phase> <repo-path> ["optional focus"]   e.g. ./run-council.sh audit 0 ~/glowdesk'
  PHASE="${1:?$AUDIT_USAGE}"
  REPO="${2:?$AUDIT_USAGE}"
  shift 2
  REPO="${REPO:A}"
  PHASE=${PHASE#[Pp]hase}
  [[ $PHASE =~ '^[0-9]+(\.[0-9]+)?$' ]] || { print "Phase must be a number like 0 or 5, got: $PHASE"; exit 1; }
  if [[ $PHASE == *.* ]]; then
    print "Audits always cover a full phase: auditing phase ${PHASE%%.*} (all its subphases), not just $PHASE."
    PHASE=${PHASE%%.*}
  fi
  [[ -d $REPO/.git ]] || { print "Not a git repository: $REPO"; exit 1; }
  SPEC="$REPO/plan/parts/11-delivery-plan.md"
  [[ -f $SPEC ]] || { print "Missing $SPEC. Copy the plan into the repo first."; exit 1; }
  grep -Eq "^### Phase $PHASE:" "$SPEC" || { print "Phase $PHASE not found in $SPEC (expected a heading '### Phase $PHASE:')."; exit 1; }
  print "Auditing phase $PHASE: $(grep -E "^#### Subphase $PHASE\." "$SPEC" | sed -E 's/^#### Subphase ([0-9.]+):.*/\1/' | paste -sd ' ' -)"
fi
FOCUS="${1:-Cover the entire dashboard.}"
[[ $MODE == plan && -z ${1:-} ]] && FOCUS="Plan the full product, MVP first."
[[ $MODE == review && -z ${1:-} ]] && FOCUS="Leave nothing missed and no wrong decision standing."
[[ $MODE == final && -z ${1:-} ]] && FOCUS="One document a team can build the whole product from."
[[ $MODE == audit && -z ${1:-} ]] && FOCUS="Decide whether the phase is complete, correct and safe."
OUT="$DIR/output"
TS=$(date +%Y%m%d-%H%M%S)

DASHBOARD_URL=$(grep '^DASHBOARD_URL=' "$DIR/.env" 2>/dev/null | tail -1 | cut -d= -f2- | tr -d "\"'")
[[ $MODE == (survey|deep) ]] && : "${DASHBOARD_URL:?Set DASHBOARD_URL in $DIR/.env}"

OR_KEY=$(grep '^OPENROUTER_API_KEY=' "$DIR/.env" | tail -1 | cut -d= -f2- | tr -d "\"'")
: "${OR_KEY:?Set OPENROUTER_API_KEY in $DIR/.env}"
PROFILES=(cartographer linker verifier chair)
VERIFIER=verifier
SYNTHESIZER=chair
if [[ $MODE == audit ]]; then
  PROFILES=(auditor audit-lead)
  VERIFIER=audit-lead
  SYNTHESIZER=audit-lead
  for r in $PROFILES; do
    hermes profile show $r >/dev/null 2>&1 || { print "Profile $r is missing. Run ./setup.sh to create the audit profiles."; exit 1; }
  done
fi
for f in ${$(hermes config path):h}/.env ${^${(f)"$(for r in $PROFILES; do print -r -- "${$(hermes -p $r config path):h}"; done)"}}/.env; do
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

if [[ $MODE == plan && ! -f "$OUT/TECHNICAL_REPORT.md" ]]; then
  print "Plan mode builds on the deep pass. Run ./run-council.sh deep first to produce $OUT/TECHNICAL_REPORT.md."
  exit 1
fi

PARENTS=()
if [[ $MODE == (review|final) ]]; then
  [[ -f "$OUT/plan/briefs/chair.md" ]] || { print "$MODE mode needs a plan run. Run ./run-council.sh plan first."; exit 1; }
  # A plan chair that is still working becomes a dependency, so the review starts once it finishes.
  PARENTS=(${=$(hermes kanban list --assignee chair --json | python3 -c "
import json, sys
print(' '.join(t['id'] for t in json.load(sys.stdin)
               if t['status'] not in ('done', 'archived') and '/output/plan/' in t.get('body', '')))")})
  if (( ! ${#PARENTS} )) && [[ ! -f "$OUT/plan/IMPLEMENTATION_PLAN.md" ]]; then
    print "No plan chair is running and $OUT/plan/IMPLEMENTATION_PLAN.md is missing. Re-run ./run-council.sh plan."
    exit 1
  fi
fi

if [[ $MODE != (plan|review|final|audit) ]] && ! node "$DIR/login.mjs" --check; then
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
elif [[ $MODE == plan ]]; then
  mkdir -p "runs/$TS-before-plan"
  if [[ -d output/plan ]]; then
    chmod -R u+w output/plan
    mv output/plan "runs/$TS-before-plan/plan-previous"
  fi
  chmod -R a-w output/*.md output/*.json output/technical 2>/dev/null || true

  P="$OUT/plan"
  B="$P/briefs"
  mkdir -p "$B" "$P/skill-drafts" "$P/sql" "$P/skills/.cursor/skills" "$P/skills/.claude/skills"
  for f in briefs/plan/*.md; do
    sed "s|{{COUNCIL_DIR}}|$DIR|g" "$f" > "$B/${f:t}"
  done

  REPORT="$P/IMPLEMENTATION_PLAN.md"
  GOAL="Design council for a new multi-tenant spa/salon SaaS (first tenant SpaCorner, multiple branches with their own staff and services) on Supabase + Edge Functions (Deno) + React/TypeScript, using the reverse-engineering reports in $OUT as read-only input. Every member reads $B/common.md and $B/skill-format.md first, then its own brief. Verifier follows $B/verifier.md. Chair follows $B/chair.md. $FOCUS Final deliverables: $P/decisions.md, $REPORT, $P/CONVENTIONS.md, and the skills in $P/skills/."
  WORKERS=(
    --worker "cartographer:Product requirements, scope and roles - follow briefs $B/common.md and $B/requirements.md"
    --worker "linker:Data model, multi-tenancy and database conventions - follow briefs $B/common.md and $B/data-model.md"
    --worker "linker:Edge Functions backend architecture and conventions - follow briefs $B/common.md and $B/backend.md"
    --worker "cartographer:Frontend architecture, i18n and RTL conventions - follow briefs $B/common.md and $B/frontend.md"
  )
elif [[ $MODE == review ]]; then
  P="$OUT/plan"
  R="$P/review2"
  if [[ -d "$R" ]]; then
    mkdir -p "runs/$TS-before-review"
    cp -R "$P/." "runs/$TS-before-review/"
    mv "$R" "runs/$TS-before-review/review2-previous"
  fi
  B="$R/briefs"
  mkdir -p "$B"
  for f in briefs/plan-review/*.md; do
    sed "s|{{COUNCIL_DIR}}|$DIR|g" "$f" > "$B/${f:t}"
  done

  REPORT="$P/REVISION_LOG.md"
  GOAL="Round 2 adversarial review of the multi-tenant spa/salon SaaS plan in $P. Reviewers audit work they did not write and only write to $R. Every member reads $B/common.md first, then its own brief. Verifier follows $B/verifier.md. Chair follows $B/chair.md and applies the accepted fixes to decisions.md, IMPLEMENTATION_PLAN.md, CONVENTIONS.md, the SQL drafts and the skills. $FOCUS Final deliverables: the revised plan files and $REPORT."
  WORKERS=(
    --worker "linker:Coverage, requirements and frontend audit - follow briefs $B/common.md and $B/coverage.md"
    --worker "cartographer:Data model, SQL, security and Edge Functions audit - follow briefs $B/common.md and $B/data-backend.md"
    --worker "linker:Decisions and conventions audit - follow briefs $B/common.md and $B/decisions-audit.md"
    --worker "cartographer:Implementation plan and skills audit - follow briefs $B/common.md and $B/plan-skills-audit.md"
  )
elif [[ $MODE == final ]]; then
  P="$OUT/plan"
  F="$P/final"
  if [[ -d "$F" ]]; then
    mkdir -p "runs/$TS-before-final"
    cp -R "$P/." "runs/$TS-before-final/"
    mv "$F" "runs/$TS-before-final/final-previous"
  fi
  B="$F/briefs"
  mkdir -p "$B" "$F/drafts" "$F/parts"
  for f in briefs/final/*.md; do
    sed "s|{{COUNCIL_DIR}}|$DIR|g" "$f" > "$B/${f:t}"
  done

  REPORT="$P/PLAN.md"
  GOAL="Final round for the multi-tenant spa/salon SaaS plan in $P: go over the revised plan once more and produce one self-contained PLAN.md with phases and subphases, UML diagrams, the reasoning behind every decision, the council's findings, the Fresha parity matrix, and extra features beyond Fresha. Every member reads $B/common.md first, then its own brief. Verifier follows $B/verifier.md. Chair follows $B/chair.md. $FOCUS Final deliverable: $REPORT."
  WORKERS=(
    --worker "cartographer:Fresha parity, extra features and user journeys - follow briefs $B/common.md and $B/parity.md"
    --worker "linker:Architecture and UML diagrams - follow briefs $B/common.md and $B/architecture-uml.md"
    --worker "cartographer:Decisions reasoning, council findings and a final independent pass - follow briefs $B/common.md and $B/reasoning.md"
    --worker "linker:Phases and subphases with backlog, dependencies and timeline - follow briefs $B/common.md and $B/phases.md"
    --worker "linker:Corrected SQL migrations and RLS tests - follow briefs $B/common.md and $B/sql.md"
  )
elif [[ $MODE == audit ]]; then
  A="$OUT/audit/phase-$PHASE"
  if [[ -d "$A" ]]; then
    mkdir -p "runs/$TS-audit"
    mv "$A" "runs/$TS-audit/phase-$PHASE-previous"
  fi
  B="$A/briefs"
  mkdir -p "$B" "$A/gates" "$A/screenshots"
  for f in briefs/audit/*.md; do
    sed -e "s|{{COUNCIL_DIR}}|$DIR|g" -e "s|{{REPO}}|$REPO|g" -e "s|{{PHASE}}|$PHASE|g" -e "s|{{AUDIT_DIR}}|$A|g" \
      "$f" > "$B/${f:t}"
  done

  REPORT="$A/AUDIT_REPORT.md"
  GOAL="Audit whether plan phase $PHASE is properly implemented in the git repository at $REPO. The repository is read-only: never edit, commit, stash or switch branches there. A gates task runs every stateful check first and shares its logs in $A/gates. Every member reads $B/common.md first, then its own brief. Verifier follows $B/verifier.md. Chair follows $B/chair.md. $FOCUS Final deliverable: $REPORT."
  WORKERS=(
    --worker "auditor:Database and security audit of phase $PHASE - follow briefs $B/common.md and $B/database.md"
    --worker "auditor:Edge Functions and backend audit of phase $PHASE - follow briefs $B/common.md and $B/backend.md"
    --worker "auditor:Frontend, i18n and RTL audit of phase $PHASE - follow briefs $B/common.md and $B/frontend.md"
    --worker "auditor:Plan conformance audit of phase $PHASE - follow briefs $B/common.md and $B/conformance.md"
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
if [[ $MODE != (deep|review|final|audit) ]] || [[ $MODE == (review|final) && ${#PARENTS} -eq 0 ]]; then
  hermes kanban swarm "$GOAL" "${WORKERS[@]}" --verifier $VERIFIER --synthesizer $SYNTHESIZER
else
  # Workers depend on PARENTS (deep: a seed-data task; audit: the gates task; review/final: the unfinished plan chair).
  # Dispatch is paused while dependencies are wired so nothing starts early.
  hermes pause --reason "wiring council dependencies" >/dev/null
  trap 'hermes resume >/dev/null 2>&1' EXIT
  json_field() { python3 -c "import json,sys; d=json.load(sys.stdin); v=d$1; print(' '.join(v) if isinstance(v, list) else v)"; }
  if [[ $MODE == deep ]]; then
    PARENTS=($(hermes kanban create "Seed realistic COUNCIL-TEST data - follow briefs $B/common.md and $B/seed.md" \
      --assignee linker --body-file "$B/seed.md" --json | json_field '["id"]'))
  elif [[ $MODE == audit ]]; then
    PARENTS=($(hermes kanban create "Run the phase $PHASE gates and capture logs - follow briefs $B/common.md and $B/gates.md" \
      --assignee auditor --body-file "$B/gates.md" --json | json_field '["id"]'))
  fi
  SWARM=$(hermes kanban swarm "$GOAL" "${WORKERS[@]}" --verifier $VERIFIER --synthesizer $SYNTHESIZER --json)
  for w in ${=$(print -r -- "$SWARM" | json_field '["worker_ids"]')}; do
    for p in $PARENTS; do hermes kanban link "$p" "$w" >/dev/null; done
  done
  print "Waits on: $PARENTS  Workers: $(print -r -- "$SWARM" | json_field '["worker_ids"]')  Verifier: $(print -r -- "$SWARM" | json_field '["verifier_id"]')  Chair: $(print -r -- "$SWARM" | json_field '["synthesizer_id"]')"
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

[[ ${AUTOPUSH:-1} == 1 ]] && "$DIR/autopush.sh" start
echo "Council started ($MODE). Report will be at: $REPORT (Ctrl-C stops watching, not the council)"
hermes kanban watch
