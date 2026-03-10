#!/usr/bin/env bash
# Check: run pkgcheck on staged ebuild changes
# Used by: pre-commit hook

staged_ebuilds=$(git diff --cached --name-only --diff-filter=ACM | grep '\.ebuild$')

if [ -z "$staged_ebuilds" ]; then
    exit 0
fi

echo "Running pkgcheck on staged ebuilds..."

output=$(pkgcheck scan -r bennypowers --staged \
    -k error,warning \
    2>&1)

if [ -n "$output" ]; then
    echo ""
    echo "pkgcheck found issues in staged ebuilds:"
    echo "──────────────────────────────────────────"
    echo "$output"
    echo "──────────────────────────────────────────"
    exit 1
fi

echo "pkgcheck: no errors or warnings found."
