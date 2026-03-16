#!/usr/bin/env python3
"""Compare two Coq timing logs and report regressions > 5%."""

import re
import sys


def parse_timing(path):
    """Parse a Coq timing log, returning {filename: seconds}."""
    timings = {}
    pattern = re.compile(r"^(.*\.v)\s+.*\b(\d+\.\d+)\s*s")
    with open(path) as f:
        for line in f:
            m = pattern.search(line)
            if m:
                timings[m.group(1)] = float(m.group(2))
    return timings


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <before.log> <after.log>", file=sys.stderr)
        sys.exit(1)

    before = parse_timing(sys.argv[1])
    after = parse_timing(sys.argv[2])

    regression = False
    for fname in sorted(set(before) | set(after)):
        b = before.get(fname, 0)
        a = after.get(fname, 0)
        if b > 0:
            pct = ((a - b) / b) * 100
            marker = ""
            if pct > 5:
                marker = " ** REGRESSION **"
                regression = True
            elif pct < -5:
                marker = " (improved)"
            print(f"  {fname}: {b:.2f}s -> {a:.2f}s ({pct:+.1f}%){marker}")
        elif a > 0:
            print(f"  {fname}: NEW {a:.2f}s")

    if regression:
        print("\nERROR: Performance regression detected (>5%)")
        sys.exit(1)
    else:
        print("\nNo significant regressions.")


if __name__ == "__main__":
    main()
