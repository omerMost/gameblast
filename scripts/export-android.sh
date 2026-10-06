#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
godot_bin="${GODOT_BIN:-/opt/homebrew/bin/godot}"
mkdir -p "$repo_dir/godot/build"
"$godot_bin" --headless --path "$repo_dir/godot" --editor --import
"$godot_bin" --headless --path "$repo_dir/godot" --export-debug Android build/blast-ranger-debug.apk
printf 'APK: %s\n' "$repo_dir/godot/build/blast-ranger-debug.apk"
