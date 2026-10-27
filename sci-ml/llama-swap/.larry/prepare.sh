#!/usr/bin/env bash
#
# Custom prepare script for llama-swap.
# Generates the go vendor and UI node_modules tarballs and uploads
# them to GitHub releases.
#
# This file lives under .larry/ so it never ships to end users —
# it's an overlay-maintainer concern only.
#
# Prerequisites: go, nodejs+npm, gh (with GITHUB_TOKEN), curl
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

# Reproducible tar flags: same input always yields the same tarball, so
# re-running prepare does not invalidate the Manifest or clobber the
# uploaded release asset with different bytes.
TAR_FLAGS=(--sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cJf)

# Tarballs are named ${PN}-${PV}-* (not ${P}-*) so ebuild revisions share
# them. Existing tarballs in DISTDIR are NOT regenerated: published
# distfiles must stay immutable — delete the file in DISTDIR to force a
# rebuild.
BASE="${PN}-${PV}"
DEPS_TARBALL="${BASE}-deps.tar.xz"
NODE_MODULES_TARBALL="${BASE}-ui-node-modules.tar.xz"

if [ -f "$DISTDIR/$DEPS_TARBALL" ] && [ -f "$DISTDIR/$NODE_MODULES_TARBALL" ]; then
    echo ">>> llama-swap: dependency tarballs for ${BASE} already in DISTDIR, skipping regeneration"
    exit 0
fi

echo ">>> llama-swap: preparing dependency tarballs for ${BASE}..."

# ── Resolve paths ──────────────────────────────────────────────────────────

OVERLAY_DIR="$(dirname "$(dirname "$EBUILD")")/.."
WORK=$(mktemp -d /tmp/prepare-XXXXXX)
trap 'rm -rf "$WORK"' EXIT

# ── Download source ────────────────────────────────────────────────────────

echo ">>> llama-swap: downloading source..."
SRC_URL="https://github.com/mostlygeek/llama-swap/archive/refs/tags/v${PV}.tar.gz"
curl -sL "$SRC_URL" | tar xzf - -C "$WORK"

# Find the single extracted directory
SRC_DIR=$(find "$WORK" -maxdepth 1 -mindepth 1 -type d | head -1)
if [ -z "$SRC_DIR" ]; then
    echo ">>> llama-swap: ERROR: no source directory found"
    exit 1
fi

# Tarball roots must carry the ${P}/ prefix (the upstream source dir
# name) so they unpack into ${S}: go-module_src_unpack skips
# `ego mod verify` — which needs network — only when ${S}/vendor exists,
# and the ebuild references the UI node_modules relative to ${S}.
PREFIX="$(basename "$SRC_DIR")"

# ── 1. Go vendor deps tarball ─────────────────────────────────────────────

echo ">>> llama-swap: creating ${DEPS_TARBALL}..."
(
    cd "$SRC_DIR"
    export TMPDIR="$WORK"
    go mod vendor
)
tar "${TAR_FLAGS[@]}" "$DISTDIR/$DEPS_TARBALL" -C "$WORK" "${PREFIX}/vendor"

# ── 2. UI node_modules tarball ────────────────────────────────────────────

echo ">>> llama-swap: creating ${NODE_MODULES_TARBALL}..."
(
    cd "$SRC_DIR/ui"
    export TMPDIR="$WORK"
    npm ci --ignore-scripts --no-audit --no-fund
)
tar "${TAR_FLAGS[@]}" "$DISTDIR/$NODE_MODULES_TARBALL" -C "$WORK" "${PREFIX}/ui/node_modules"

# ── Upload to GitHub release ──────────────────────────────────────────────
# The release is tagged with the package name — this is what the ebuild's
# SRC_URI fetches (`releases/download/${PN}/...`) and it makes the tarballs
# reusable across ebuild revisions.

GH_REPO="bennypowers/gentoo-overlay"
TAG="${PN}"

# gh release upload does not create the release; make sure it exists.
if ! gh release view "$TAG" --repo "$GH_REPO" >/dev/null 2>&1; then
    echo ">>> llama-swap: creating release $TAG..."
    gh release create "$TAG" --repo "$GH_REPO" --title "llama-swap deps" \
        --notes "Vendored dependency tarballs for llama-swap" >/dev/null
fi

for asset in "$DEPS_TARBALL" "$NODE_MODULES_TARBALL"; do
    echo ">>> llama-swap: uploading $asset..."
    gh release upload "$TAG" "$DISTDIR/$asset" --repo "$GH_REPO" --clobber
done

echo ">>> llama-swap: done"
