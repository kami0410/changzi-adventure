#!/usr/bin/env bash
# Runs the game scene with --quit-after and fails if the engine reports
# leaked objects or resources on exit.
#
# Usage: tests/check_exit_clean.sh [godot-binary] [runs] [scene]
# Example: tests/check_exit_clean.sh ~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64 10
set -euo pipefail

GODOT="${1:-godot}"
RUNS="${2:-10}"
SCENE="${3:-res://scenes/main.tscn}"
cd "$(dirname "$0")/.."

for i in $(seq 1 "$RUNS"); do
	if ! output=$("$GODOT" --headless --path . "$SCENE" --quit-after 400 2>&1); then
		echo "exit check: run $i failed to launch" >&2
		echo "$output" >&2
		exit 1
	fi
	if grep -qE "ObjectDB instances were leaked|resources still in use" <<<"$output"; then
		echo "exit check: run $i leaked objects/resources" >&2
		grep -E "leaked|still in use" <<<"$output" >&2
		exit 1
	fi
done

echo "exit check: $RUNS/$RUNS clean"
