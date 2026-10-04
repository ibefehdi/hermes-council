#!/usr/bin/env zsh
# Idempotent: safe to re-run after pulling changes or editing council.conf.
[ -n "${ZSH_VERSION:-}" ] || exec zsh "$0" "$@"
set -euo pipefail

DIR="${0:A:h}"
cd "$DIR"
source "$DIR/council.conf"

ROLES=(cartographer linker verifier chair auditor audit-lead)
typeset -A DESC=(
  cartographer "Crawls every dashboard page with Playwright and inventories each page's features, controls, and data shown"
  linker       "Maps how dashboard features connect: navigation paths, shared entities, shared API endpoints, cross-page data flows"
  verifier     "Council reviewer: cross-checks other members' findings against the live dashboard and flags errors, gaps, and disagreements"
  chair        "Council chair: merges verified findings into the final feature map and report"
  auditor      "Phase audit: runs the gates and audits a local repo against one phase of the implementation plan"
  audit-lead   "Phase audit lead: verifies the auditors' findings, decides the verdict, and writes the audit report"
)
# council.conf key prefix for a role: audit-lead -> AUDIT_LEAD
conf_key() { local k=${(U)1}; print -r -- ${k//-/_}; }

set_env() {
  local file=$1 key=$2 value=$3 rest
  touch "$file" && chmod 600 "$file"
  rest=$(grep -v "^${key}=" "$file" || true)
  { [[ -n $rest ]] && print -r -- "$rest"; print -r -- "${key}=${value}"; } > "$file"
}

for cmd in hermes node npm npx curl; do
  command -v $cmd >/dev/null || { print "Missing required command: $cmd"; exit 1; }
done

print "==> Installing Playwright and Chromium"
npm install --silent
npx playwright install chromium
mkdir -p output screenshots runs

# Prefer installed Google Chrome: no browser-version coupling with @playwright/mcp, and a less bot-like fingerprint.
if [[ -e "/Applications/Google Chrome.app" ]] || command -v google-chrome >/dev/null; then
  MCP_BROWSER=chrome
else
  MCP_BROWSER=chromium
fi
print "==> Agents will browse with: $MCP_BROWSER"
[[ -f auth.json ]] || print -r '{"cookies":[],"origins":[]}' > auth.json

if [[ ! -f .env ]]; then
  cp .env.example .env && chmod 600 .env
  if [[ -t 0 ]]; then
    print "==> Dashboard login (stored only in $DIR/.env)"
    read "url?Dashboard URL: "
    read "user?Dashboard username/email/phone (optional, pre-fills the login form): "
    read -s "pass?Dashboard password (leave empty for OTP/SSO login): " && print
    set_env .env DASHBOARD_URL "$url"
    set_env .env DASHBOARD_USER "$user"
    set_env .env DASHBOARD_PASS "$pass"
  else
    print "==> Created $DIR/.env from template; fill it in before running."
  fi
fi

if [[ $CARTOGRAPHER_PROVIDER == auto ]]; then
  if curl -sf --max-time 3 "$CARTOGRAPHER_LOCAL_BASE_URL/models" | grep -q "\"$CARTOGRAPHER_LOCAL_MODEL\""; then
    CARTOGRAPHER_PROVIDER=custom
    CARTOGRAPHER_MODEL=$CARTOGRAPHER_LOCAL_MODEL
    print "==> Cartographer: local model $CARTOGRAPHER_LOCAL_MODEL found at $CARTOGRAPHER_LOCAL_BASE_URL"
  else
    CARTOGRAPHER_PROVIDER=openrouter
    print "==> Cartographer: no local model reachable, using OpenRouter $CARTOGRAPHER_MODEL"
  fi
fi

needs_openrouter=false
for role in $ROLES; do
  eval "p=\${$(conf_key $role)_PROVIDER}"
  [[ $p == openrouter ]] && needs_openrouter=true
done

OR_KEY=${OPENROUTER_API_KEY:-$(grep '^OPENROUTER_API_KEY=' .env 2>/dev/null | tail -1 | cut -d= -f2- | tr -d "\"'")}
if $needs_openrouter && [[ -z $OR_KEY ]]; then
  for role in $ROLES; do
    f="$HOME/.hermes/profiles/$role/.env"
    [[ -f $f ]] && OR_KEY=$(grep '^OPENROUTER_API_KEY=' "$f" | tail -1 | cut -d= -f2-) || true
    [[ -n $OR_KEY ]] && break
  done
  if [[ -z $OR_KEY && -t 0 ]]; then
    read -s "OR_KEY?OpenRouter API key (input hidden): " && print
  fi
  [[ -z $OR_KEY ]] && print "!! No OpenRouter key set. Add OPENROUTER_API_KEY to $DIR/.env and re-run ./setup.sh"
fi
[[ -n $OR_KEY ]] && set_env .env OPENROUTER_API_KEY "$OR_KEY"

for role in $ROLES; do
  print "==> Configuring profile: $role"
  hermes profile show $role >/dev/null 2>&1 || hermes profile create $role --clone --description "${DESC[$role]}" >/dev/null
  home=${$(hermes -p $role config path):h}

  sed "s|{{COUNCIL_DIR}}|$DIR|g" "roles/$role.md" > "$home/SOUL.md"

  eval "provider=\${$(conf_key $role)_PROVIDER}; model=\${$(conf_key $role)_MODEL}"
  hermes -p $role config set model.provider "$provider" >/dev/null
  hermes -p $role config set model.default "$model" >/dev/null
  if [[ $provider == custom ]]; then
    hermes -p $role config set model.base_url "$CARTOGRAPHER_LOCAL_BASE_URL" >/dev/null
  else
    hermes -p $role config unset model.base_url >/dev/null 2>&1 || true
    hermes -p $role config unset model.context_length >/dev/null 2>&1 || true
  fi
  [[ $provider == openrouter && -n $OR_KEY ]] && set_env "$home/.env" OPENROUTER_API_KEY "$OR_KEY"

  hermes -p $role mcp remove playwright >/dev/null 2>&1 || true
  print Y | hermes -p $role mcp add playwright --command npx --connect-timeout 120 --args \
    -y @playwright/mcp@latest --browser $MCP_BROWSER --headless --isolated \
    --storage-state "$DIR/auth.json" --output-dir "$DIR/screenshots" >/dev/null

  hermes -p $role tools enable kanban >/dev/null
  hermes -p $role tools disable browser computer_use >/dev/null
done

hermes tools enable kanban >/dev/null
hermes kanban init >/dev/null

print
hermes profile list
print "\nSetup complete. Start a council run with: $DIR/run-council.sh"
