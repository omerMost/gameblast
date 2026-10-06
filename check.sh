#!/bin/sh
# check.sh — one command checks everything (ADR 0003).
# Runs every Godot headless suite, fails on a non-zero exit, a script error, a missing RESULT line or a TIMEOUT.
# Usage: ./check.sh [suite ...]     (default: all suites)
# Logs: .check-logs/<suite>.log
cd "$(dirname "$0")" || exit 2
SUITES_DEFAULT="smoke shooters selfharm sweep"
[ -f godot/tests/suites.txt ] && SUITES_DEFAULT=$(grep -v '^#' godot/tests/suites.txt | tr '\n' ' ')
SUITES=${*:-$SUITES_DEFAULT}
mkdir -p .check-logs
command -v godot >/dev/null || { echo "check.sh: godot not on PATH"; exit 2; }
# Refresh class/resource cache when a port introduces new scripts.
perl -e 'alarm shift; exec @ARGV' 120 godot --headless --path godot --import > .check-logs/import.log 2>&1
import_code=$?
if [ "$import_code" -ne 0 ] || grep -qE '^ERROR:|SCRIPT ERROR|Parse Error' .check-logs/import.log; then
  echo "check.sh: Godot import failed — see .check-logs/import.log"
  exit 1
fi
pass=0; fail=0; failed=""; t0=$(date +%s)
for s in $SUITES; do
  log=.check-logs/$s.log
  t=$(date +%s)
  godot/tests/run.sh "$s" ${CHECK_TIMEOUT:-900} > "$log" 2>&1
  code=$?
  why=""
  [ $code -ne 0 ] && why="exit $code"
  grep -q "TIMEOUT after" "$log" && why="TIMEOUT"
  grep -qE "^ERROR:|SCRIPT ERROR|Parse Error|Invalid call|Invalid access|Invalid assignment|Nonexistent function" "$log" && why="${why:+$why, }script error"
  grep -qE "RESULT: PASS" "$log" || why="${why:-no PASS line}"
  dt=$(( $(date +%s) - t ))
  if [ -z "$why" ]; then
    pass=$((pass+1)); echo "  ok    $s (${dt}s)"
  else
    fail=$((fail+1)); failed="$failed $s"; echo "  FAIL  $s (${dt}s): $why — see $log"
    grep -E "^ERROR:|SCRIPT ERROR|RESULT|FAIL" "$log" | head -8 | sed 's/^/        /'
  fi
done
echo "CHECK: $pass passed, $fail failed$( [ -n "$failed" ] && echo " ($failed )") in $(( $(date +%s) - t0 ))s"
[ $fail -eq 0 ]
