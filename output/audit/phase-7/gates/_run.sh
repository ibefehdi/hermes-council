#!/bin/bash
# Runner that executes a command and tees output to a log, reporting exit code.
# Usage: bash run-check.sh <logfile> <command...>
LOG="$1"; shift
"$@" > "$LOG" 2>&1
echo "$?" > "${LOG}.exit"