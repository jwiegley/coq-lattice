#!/usr/bin/env bash
# Compare current build timing against saved baseline.
# Fails if any file regresses by more than 5%.
set -euo pipefail

BASELINE="${1:-.perf-baseline.log}"
CURRENT=$(mktemp)
trap 'rm -f "$CURRENT"' EXIT

if [ ! -f "$BASELINE" ]; then
    echo "No performance baseline found at $BASELINE"
    echo "Run 'make timing > $BASELINE' to create one."
    exit 0
fi

make timing 2>&1 | tee "$CURRENT"
python3 scripts/timing-diff.py "$BASELINE" "$CURRENT"
