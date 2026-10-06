#!/bin/sh
# Run a headless test scene with a watchdog (script errors don't make Godot exit).
# Usage: tests/run.sh <smoke|sweep|shooters> [seconds] [-- user args]
cd "$(dirname "$0")/.." || exit 2
name=$1; secs=${2:-300}; shift; [ $# -gt 0 ] && shift
[ -d .godot/imported ] || godot --headless --path . --import >/dev/null 2>&1
perl -e 'alarm shift; exec @ARGV' "$secs" godot --headless --fixed-fps 60 --path . "res://tests/$name.tscn" "$@" 2>&1
code=$?
[ $code -eq 142 ] && echo "TIMEOUT after ${secs}s"
exit $code
