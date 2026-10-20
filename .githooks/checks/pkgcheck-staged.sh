#!/usr/bin/env bash
# Check: run pkgcheck on staged ebuild changes
# Used by: pre-commit hook

staged_ebuilds=$(git diff --cached --name-only --diff-filter=ACM | grep '\.ebuild$')

if [ -z "$staged_ebuilds" ]; then
    exit 0
fi

echo "Running pkgcheck on staged ebuilds..."

# NonsolvableDeps* and RequiredUseDefaults fire on musl/hurd/x32 profiles
# for deps that cannot exist there (nvidia-drivers, systemd, nodejs); this
# overlay only targets amd64 glibc, so those results are filtered out here.
output=$(pkgcheck scan -r bennypowers --staged \
    -k error,warning \
    \
    2>&1 | grep -vE 'NonsolvableDeps(InDev|InExp|InStable)|RequiredUseDefaults' || true)

if [ -n "$output" ]; then
    echo ""
    echo "pkgcheck found issues in staged ebuilds:"
    echo "──────────────────────────────────────────"
    echo "$output"
    echo "──────────────────────────────────────────"
    exit 1
fi

echo "pkgcheck: no errors or warnings found."
