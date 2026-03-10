#!/usr/bin/env bash
# Check: run pkgcheck on commits being pushed
# Used by: pre-push hook
# Expects: $PUSH_RANGE set by the calling hook

ebuilds=$(git diff --name-only $PUSH_RANGE -- '*.ebuild' 2>/dev/null)
if [ -z "$ebuilds" ]; then
    exit 0
fi

echo "Running pkgcheck on commits being pushed..."

output=$(pkgcheck scan -r bennypowers --commits \
    -k error,warning \
    2>&1)

if [ -n "$output" ]; then
    echo ""
    echo "pkgcheck found issues in commits being pushed:"
    echo "──────────────────────────────────────────"
    echo "$output"
    echo "──────────────────────────────────────────"
    exit 1
fi

echo "pkgcheck: no errors or warnings found."
