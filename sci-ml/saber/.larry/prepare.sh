#!/usr/bin/env bash
#
# Custom prepare script for saber.
# Upstream has no release tags, so larry's cargo auto-detect (which
# resolves Cargo.lock from a tag) cannot run. This hook vendors the
# workspace crates at a pinned commit and uploads the tarball to the
# overlay's GitHub release.
#
# This file lives under .larry/ so it never ships to end users —
# it's an overlay-maintainer concern only.
#
# Prerequisites: cargo, gh (with GITHUB_TOKEN), curl
#

set -euo pipefail

# Prepend user-local bin to PATH (sandbox restricts to system dirs only)
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

DISTDIR="${DISTDIR:?DISTDIR not set}"
EBUILD="${EBUILD:?EBUILD not set}"
PV="${PV:?PV not set}"
PN="${PN:?PN not set}"

# Must match COMMIT in the ebuild.
COMMIT="c8a1e84b39e73363495e549d480a6f6c3893800c"

BASE="${P}"
CRATES_TARBALL="${BASE}-crates.tar.xz"

if [ -f "$DISTDIR/$CRATES_TARBALL" ]; then
    echo ">>> saber: ${CRATES_TARBALL} already in DISTDIR, skipping regeneration"
    exit 0
fi

echo ">>> saber: vendoring crates at ${COMMIT}..."

WORK=$(mktemp -d /tmp/saber-prepare-XXXXXX)
trap 'rm -rf "$WORK"' EXIT

curl -sL "https://github.com/GGZ14/saber-engine/archive/${COMMIT}.tar.gz" \
    | tar xzf - -C "$WORK"

SRC_DIR=$(find "$WORK" -maxdepth 1 -mindepth 1 -type d | head -1)
[ -n "$SRC_DIR" ] || { echo ">>> saber: no source directory found" >&2; exit 1; }
PREFIX="$(basename "$SRC_DIR")"

(
    cd "$SRC_DIR"
    export TMPDIR="$WORK"
    cargo vendor vendor
)

# Root the tarball at ${P} so it unpacks into ${S} from the ebuild.
tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
    --create --file "$DISTDIR/$CRATES_TARBALL" --xz \
    --transform "s|^${PREFIX}|${P}|" \
    -C "$WORK" "${PREFIX}/vendor"

# Upload to the package-named release so revisions can reuse the asset.
GH_REPO="bennypowers/gentoo-overlay"
TAG="${PN}"

if ! gh release view "$TAG" --repo "$GH_REPO" >/dev/null 2>&1; then
    echo ">>> saber: creating release $TAG..."
    gh release create "$TAG" --repo "$GH_REPO" --title "saber deps" \
        --notes "Vendored crate tarballs for saber" >/dev/null
fi

echo ">>> saber: uploading $CRATES_TARBALL..."
gh release upload "$TAG" "$DISTDIR/$CRATES_TARBALL" --repo "$GH_REPO" --clobber

echo ">>> saber: done"
