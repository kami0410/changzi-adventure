#!/usr/bin/env bash
# Runs every integration suite one after another (they must not run in
# parallel) and prints one line per suite. Exit code 1 if any suite fails.
#   tools/run_integration.sh [godot-binary]
GODOT="${1:-godot}"
cd "$(dirname "$0")/.."
status=0
for suite in tests/integration_*.gd; do
	output=$("$GODOT" --headless --path . -s "res://$suite" 2>&1)
	code=$?
	fails=$(grep -c "FAIL: \|SCRIPT ERROR\|Parse Error" <<<"$output")
	summary=$(grep -E "^INTEGRATION|assertions" <<<"$output" | grep -v FAIL | tail -1)
	echo "$(basename "$suite") exit=$code fails=$fails ${summary}"
	if [ "$code" -ne 0 ] || [ "$fails" -ne 0 ]; then
		status=1
		grep -E "FAIL: |SCRIPT ERROR|Parse Error" <<<"$output" | head -8
	fi
done
exit $status
