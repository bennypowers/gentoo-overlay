#!/usr/bin/env bash
# Check: run pkgcheck on commits being pushed
# Used by: pre-push hook
# Expects: $PUSH_RANGE set by the calling hook

ebuilds=$(git diff --name-only $PUSH_RANGE -- '*.ebuild' 2>/dev/null)
if [ -z "$ebuilds" ]; then
    exit 0
fi

# Skip packages that only have live ebuilds -- pkgcheck scans the synced
# repo, not the working tree, so live-only packages produce stale results
# until the next sync.
non_live_ebuilds=""
for eb in $ebuilds; do
    pkg_dir=$(dirname "$eb")
    if ls "$pkg_dir"/*.ebuild 2>/dev/null | grep -qv '\-9999\.ebuild$'; then
        non_live_ebuilds="$non_live_ebuilds $eb"
    fi
done
if [ -z "$non_live_ebuilds" ]; then
    echo "pkgcheck: skipping live-only packages."
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
