#!/bin/sh
#
# Custom prepare script for gui-apps/lan-mouse (live ebuild).
#
# The ebuild has no distfiles (cargo_live_src_unpack fetches and vendors
# the crates at build time), so there is nothing to download or manifest.
# Patches live in /etc/portage/patches/gui-apps/lan-mouse-9999/ and are
# applied by the ebuild itself in src_unpack. This script verifies that
# they still apply to upstream main.
#
# Env provided by larry: EBUILD, PN, PV, CATEGORY, DISTDIR, TMPDIR.

set -eu

WORK="${TMPDIR}/lan-mouse-main"
rm -rf "$WORK"
mkdir -p "$WORK"

echo "Fetching upstream main..."
curl -sfL "https://codeload.github.com/feschber/lan-mouse/tar.gz/refs/heads/main" \
	| tar -xz -C "$WORK"

TREE=$(find "$WORK" -mindepth 1 -maxdepth 1 -type d | head -n1)
if [ -z "$TREE" ]; then
	echo "ERROR: failed to extract upstream tarball" >&2
	exit 1
fi

PATCHDIR="/etc/portage/patches/gui-apps/${P}"
if [ ! -d "$PATCHDIR" ]; then
	echo "No user patches at $PATCHDIR; nothing to check."
	exit 0
fi

echo "Checking user patches against main..."
status=0
for p in "$PATCHDIR"/*.patch; do
	[ -e "$p" ] || continue
	if ! patch -p1 -d "$TREE" --forward --dry-run < "$p"; then
		echo "ERROR: $(basename "$p") no longer applies to main." >&2
		echo "If it is an upstream PR that merged, delete it." >&2
		echo "Otherwise rebase it against main." >&2
		status=1
	fi
done
exit "$status"
