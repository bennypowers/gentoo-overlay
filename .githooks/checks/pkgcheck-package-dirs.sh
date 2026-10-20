#!/usr/bin/env bash
# Check: pkgcheck the full package directories touched by staged changes
# Used by: pre-commit hook
#
# pkgcheck-staged.sh only reports findings on the staged files themselves,
# but the pre-push hook scans whole package directories via the synced
# repo. This check closes that gap by scanning every ebuild in the package
# directories affected by the staged changes (working tree), so old-version
# findings surface at commit time instead of blocking the push.
#
# Bypass with PKGCHECK_SKIP_DIRSCAN=1 when committing a fix for pre-existing
# findings in the same package.

if [ "${PKGCHECK_SKIP_DIRSCAN:-0}" = "1" ]; then
    echo "pkgcheck: package directory scan skipped (PKGCHECK_SKIP_DIRSCAN=1)."
    exit 0
fi

staged=$(git diff --cached --name-only --diff-filter=ACMRD)

if [ -z "$staged" ]; then
    exit 0
fi

# Unique candidate dirs (first two path segments) that are actual package
# directories (contain at least one ebuild); skips hooks/, profiles/, docs
dirs=""
for d in $(printf '%s\n' "$staged" | awk -F/ 'NF>=3 {print $1"/"$2}' | sort -u); do
    if ls "$d"/*.ebuild >/dev/null 2>&1; then
        dirs="$dirs $d"
    fi
done

if [ -z "$dirs" ]; then
    exit 0
fi

echo "Running pkgcheck on affected package directories..."

# shellcheck disable=SC2086
output=$(pkgcheck scan $dirs -k error,warning 2>&1)

if [ -n "$output" ]; then
    echo ""
    echo "pkgcheck found issues in affected packages:"
    echo "──────────────────────────────────────────"
    echo "$output"
    echo "──────────────────────────────────────────"
    echo "Pre-existing findings being fixed in this commit? Re-run with:"
    echo "  PKGCHECK_SKIP_DIRSCAN=1 git commit ..."
    exit 1
fi

echo "pkgcheck: affected packages clean."
