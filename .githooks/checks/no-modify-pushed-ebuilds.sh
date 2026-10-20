#!/usr/bin/env bash
# Check: ensure pushed ebuilds are not modified in-place
#
# Already-pushed ebuilds must not be modified — create a new revision
# (e.g. foo-1.0-r1.ebuild) instead. This prevents users who have already
# synced from silently getting different ebuild content for the same
# version-revision.
#
# Used by: pre-push hook
# Expects: $PUSH_RANGE set by the calling hook

modified_ebuilds=$(git diff --name-only --diff-filter=M $PUSH_RANGE -- '*.ebuild' 2>/dev/null)
if [ -z "$modified_ebuilds" ]; then
    exit 0
fi

# Check which of these modified ebuilds already exist on the remote
errors=()
for ebuild in $modified_ebuilds; do
    # Live ebuilds (9999) are expected to be modified in place
    [[ "$ebuild" == *-9999.ebuild ]] && continue

    # Check if the file exists in the remote ref we're pushing to
    if git cat-file -e "${PUSH_REMOTE_OID}:${ebuild}" 2>/dev/null; then
        errors+=("$ebuild")
    fi
done

if [ ${#errors[@]} -eq 0 ]; then
    exit 0
fi

echo ""
echo "ERROR: Modified ebuilds that already exist on the remote:"
echo "──────────────────────────────────────────"
for ebuild in "${errors[@]}"; do
    echo "  $ebuild"
done
echo "──────────────────────────────────────────"
echo ""
echo "Already-pushed ebuilds must not be modified in-place."
echo "Create a new revision instead (e.g. foo-1.0.ebuild → foo-1.0-r1.ebuild)."
echo ""
echo "Manifest changes are exempt — update the Manifest by creating the"
echo "new revision ebuild, not by editing the old one."
exit 1
