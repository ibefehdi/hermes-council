#!/usr/bin/env zsh
# Auto-commit and push council outputs whenever files are added or change.
# Usage: ./autopush.sh start | stop | status | run (foreground)
# Only output/ and screenshots/ are staged. A change is pushed once it has been stable for one interval,
# so files are not pushed half-written. Set AUTOPUSH_INTERVAL (seconds, default 30).
[ -n "${ZSH_VERSION:-}" ] || exec zsh "$0" "$@"
set -uo pipefail

DIR="${0:A:h}"
cd "$DIR"
PIDFILE="$DIR/.autopush.pid"
LOG="$DIR/autopush.log"
INTERVAL=${AUTOPUSH_INTERVAL:-30}
PATHS=(output screenshots)

running() { [[ -f $PIDFILE ]] && kill -0 "$(<$PIDFILE)" 2>/dev/null; }

push() {
  git push -q origin HEAD 2>>"$LOG" && return 0
  git pull -q --rebase origin "$(git branch --show-current)" >>"$LOG" 2>&1 && git push -q origin HEAD 2>>"$LOG"
}

loop() {
  local prev="" last
  last=$(git rev-parse -q --verify 'HEAD^{tree}' 2>/dev/null)
  while true; do
    git add -A -- ${^PATHS}(N) 2>>"$LOG"
    local tree=$(git write-tree)
    if [[ $tree != $last && $tree == $prev ]]; then
      if git diff --cached -U0 | grep -qE 'sk-or-v1-[A-Za-z0-9]{16,}|OPENROUTER_API_KEY=[^ ]{8,}'; then
        print "$(date '+%F %T') refused: staged changes contain what looks like an API key; unstaged" >>"$LOG"
        git reset -q
      else
        local files=(${(f)"$(git diff --cached --name-only)"})
        local names=(${files[1,4]:t})
        local more=""
        (( ${#files} > 4 )) && more=" (+$(( ${#files} - 4 )) more)"
        git commit -qm "Auto: council progress $(date +%H:%M) - ${#files} file(s): ${(j:, :)names}$more" >>"$LOG" 2>&1
        if push; then
          print "$(date '+%F %T') pushed ${#files} file(s)" >>"$LOG"
          last=$tree
        else
          print "$(date '+%F %T') push failed; will retry" >>"$LOG"
        fi
      fi
    fi
    prev=$tree
    sleep "$INTERVAL"
  done
}

case "${1:-status}" in
  start)
    if running; then print "autopush already running (pid $(<$PIDFILE))"; exit 0; fi
    nohup "$0" run >/dev/null 2>&1 &
    print $! > "$PIDFILE"
    print "autopush started (pid $!, every ${INTERVAL}s, log: $LOG)"
    ;;
  stop)
    if running; then kill "$(<$PIDFILE)" && rm -f "$PIDFILE" && print "autopush stopped"; else print "autopush not running"; rm -f "$PIDFILE"; fi
    ;;
  status)
    if running; then print "autopush running (pid $(<$PIDFILE))"; tail -3 "$LOG" 2>/dev/null; else print "autopush not running"; fi
    ;;
  run) loop ;;
  *) print "Usage: $0 start|stop|status|run"; exit 2 ;;
esac
