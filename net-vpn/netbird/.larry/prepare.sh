#!/usr/bin/env bash
#
# Custom prepare script for netbird.
# Generates dependency tarballs (deps, frontend-bindings, node-modules)
# and uploads them to GitHub releases.
#
# This file lives under .larry/ so it never ships to end users —
# it's an overlay-maintainer concern only.
#
# Prerequisites: go, pnpm, gh (with GITHUB_TOKEN), curl
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
BINDINGS_TARBALL="${BASE}-frontend-bindings.tar.xz"
NODE_MODULES_TARBALL="${BASE}-node-modules.tar.xz"

if [ -f "$DISTDIR/$DEPS_TARBALL" ] && [ -f "$DISTDIR/$BINDINGS_TARBALL" ] && [ -f "$DISTDIR/$NODE_MODULES_TARBALL" ]; then
    echo ">>> netbird: dependency tarballs for ${BASE} already in DISTDIR, skipping regeneration"
    exit 0
fi

echo ">>> netbird: preparing dependency tarballs for ${BASE}..."

# ── Resolve paths ──────────────────────────────────────────────────────────

OVERLAY_DIR="$(dirname "$(dirname "$EBUILD")")/.."
WORK=$(mktemp -d /tmp/prepare-XXXXXX)
trap 'rm -rf "$WORK"' EXIT

# ── Download source ────────────────────────────────────────────────────────

echo ">>> netbird: downloading source..."
SRC_URL="https://github.com/netbirdio/netbird/archive/refs/tags/v${PV}.tar.gz"
curl -sL "$SRC_URL" | tar xzf - -C "$WORK"

# Find the single extracted directory
SRC_DIR=$(find "$WORK" -maxdepth 1 -mindepth 1 -type d | head -1)
if [ -z "$SRC_DIR" ]; then
    echo ">>> netbird: ERROR: no source directory found"
    exit 1
fi

# ── Extract wails fork commit from go.mod ──────────────────────────────────
# go.mod has: replace github.com/wailsapp/wails/v3 =>
#     github.com/netbirdio/wails/v3 v3.0.0-beta.3.0.20261009120932-4e087a8bfd6d
# Extract the 12+ char hex commit hash (the pseudo-version suffix).
WAILS_COMMIT=$(grep 'replace github.com/wailsapp/wails/v3 =>' "$SRC_DIR/go.mod" \
    | sed -E 's|.*-([0-9a-f]{12,})|\1|' \
    | tr -d ' \t\r')

if [ -z "$WAILS_COMMIT" ]; then
    echo ">>> netbird: ERROR: could not find wails fork tag in go.mod"
    exit 1
fi
echo ">>> netbird: wails fork tag: $WAILS_COMMIT"

# ── 1. Go vendor deps tarball ─────────────────────────────────────────────

echo ">>> netbird: creating deps.tar.xz..."
(
    cd "$SRC_DIR"
    export TMPDIR="$WORK"
    go mod vendor
)
# Tarball roots must carry the ${P}/ prefix (the upstream source dir
# name) so they unpack into ${S}: go-module_src_unpack skips
# `ego mod verify` — which needs network — only when ${S}/vendor exists,
# and the ebuild references the frontend assets relative to ${S}.
PREFIX="$(basename "$SRC_DIR")"

tar "${TAR_FLAGS[@]}" "$DISTDIR/$DEPS_TARBALL" -C "$WORK" "${PREFIX}/vendor"

# ── 2. Frontend bindings tarball ───────────────────────────────────────────
# The wails fork at github.com/netbirdio/wails has go.mod with
# module github.com/wailsapp/wails/v3 in v3/go.mod, but netbird's go.mod
# replace directive points to github.com/netbirdio/wails/v3 (wrong path).
# We clone the fork, patch the replace to a local path, then run wails3.

echo ">>> netbird: creating frontend-bindings.tar.xz..."
WAILS_DIR="$WORK/wails-fork"
git clone "https://github.com/netbirdio/wails" "$WAILS_DIR"
cd "$WAILS_DIR"
git checkout -q "$WAILS_COMMIT"

# Patch netbird's go.mod: replace the broken remote => with local path
(
    cd "$SRC_DIR"
    sed -i "s|replace github.com/wailsapp/wails/v3 => github.com/netbirdio/wails/v3 .*|replace github.com/wailsapp/wails/v3 => $WAILS_DIR/v3|" go.mod
    rm -rf vendor  # clean old vendor so the local replace takes effect
)
(
    cd "$SRC_DIR/client/ui"
    export TMPDIR="$WORK"
    go run -mod=mod github.com/wailsapp/wails/v3/cmd/wails3 generate bindings -clean=true -ts
)
tar "${TAR_FLAGS[@]}" "$DISTDIR/$BINDINGS_TARBALL" \
    -C "$WORK" "${PREFIX}/client/ui/frontend/bindings"

# ── 3. Node modules tarball ───────────────────────────────────────────────

echo ">>> netbird: creating node-modules.tar.xz..."
(
    cd "$SRC_DIR/client/ui/frontend"
    pnpm install --node-linker=hoisted --frozen-lockfile --ignore-scripts
)
tar "${TAR_FLAGS[@]}" "$DISTDIR/$NODE_MODULES_TARBALL" \
    -C "$WORK" "${PREFIX}/client/ui/frontend/node_modules"

# ── Upload to GitHub release ──────────────────────────────────────────────
# The release is tagged with the package name — this is what the ebuild's
# SRC_URI fetches (`releases/download/${PN}/...`) and it makes the tarballs
# reusable across ebuild revisions.

GH_REPO="bennypowers/gentoo-overlay"
TAG="${PN}"

# gh release upload does not create the release; make sure it exists.
if ! gh release view "$TAG" --repo "$GH_REPO" >/dev/null 2>&1; then
    echo ">>> netbird: creating release $TAG..."
    gh release create "$TAG" --repo "$GH_REPO" --title "netbird deps" \
        --notes "Vendored dependency tarballs for netbird" >/dev/null
fi

for asset in "$DEPS_TARBALL" "$BINDINGS_TARBALL" "$NODE_MODULES_TARBALL"; do
    echo ">>> netbird: uploading $asset..."
    gh release upload "$TAG" "$DISTDIR/$asset" --repo "$GH_REPO" --clobber
done

echo ">>> netbird: done"
