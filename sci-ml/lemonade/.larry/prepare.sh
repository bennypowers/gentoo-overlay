#!/usr/bin/env bash
#
# Custom prepare script for lemonade.
# Generates the vendored dependency tarballs (web-app node_modules,
# tauri app node_modules, cargo vendor) and uploads them to the
# package-name GitHub release, so the ebuild's SRC_URI entries resolve.
#
# This file lives under .larry/ so it never ships to end users —
# it's an overlay-maintainer concern only.
#
# Prerequisites: nodejs/npm, cargo, gh (authenticated), curl
#
# Tarballs are named ${PN}-${PV}-* (not ${P}-*) so ebuild revisions
# share them, and are built reproducibly so re-running prepare never
# changes their bytes. Existing tarballs in DISTDIR are NOT regenerated:
# published distfiles must stay immutable — delete the file in DISTDIR
# to force a rebuild.

set -euo pipefail

DISTDIR="${DISTDIR:?DISTDIR not set}"
EBUILD="${EBUILD:?EBUILD not set}"
PV="${PV:?PV not set}"
PN="${PN:?PN not set}"

# Reproducible tar flags: same input always yields the same tarball, so
# re-running prepare does not invalidate the Manifest or clobber the
# uploaded release asset with different bytes.
TAR_FLAGS=(--sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -cJf)

BASE="${PN}-${PV}"
NPM_DEPS="${BASE}-npm-deps.tar.xz"
APP_NPM_DEPS="${BASE}-app-npm-deps.tar.xz"
CARGO_DEPS="${BASE}-cargo-deps.tar.xz"

if [ -f "$DISTDIR/$NPM_DEPS" ] && [ -f "$DISTDIR/$APP_NPM_DEPS" ] && [ -f "$DISTDIR/$CARGO_DEPS" ]; then
    echo ">>> lemonade: dependency tarballs for ${BASE} already in DISTDIR, skipping regeneration"
    exit 0
fi

echo ">>> lemonade: preparing dependency tarballs for ${BASE}..."

WORK=$(mktemp -d /tmp/prepare-lemonade-XXXXXX)
trap 'rm -rf "$WORK"' EXIT

# ── Download source ────────────────────────────────────────────────────────

SRC_URL="https://github.com/lemonade-sdk/lemonade/archive/refs/tags/v${PV}.tar.gz"
curl -sL "$SRC_URL" | tar xzf - -C "$WORK"

SRC_DIR="$WORK/${BASE}"
if [ ! -d "$SRC_DIR" ]; then
    echo ">>> lemonade: ERROR: source directory not found"
    exit 1
fi

# ── 1. Web app node_modules ────────────────────────────────────────────────

echo ">>> lemonade: creating ${NPM_DEPS}..."
(
    cd "$SRC_DIR/src/web-app"
    npm ci --ignore-scripts --no-audit --no-fund
)
tar "${TAR_FLAGS[@]}" "$DISTDIR/$NPM_DEPS" \
    -C "$SRC_DIR/src/web-app" node_modules

# ── 2. Tauri app node_modules ──────────────────────────────────────────────

echo ">>> lemonade: creating ${APP_NPM_DEPS}..."
(
    cd "$SRC_DIR/src/app"
    npm ci --ignore-scripts --no-audit --no-fund
)
tar "${TAR_FLAGS[@]}" "$DISTDIR/$APP_NPM_DEPS" \
    -C "$SRC_DIR/src/app" node_modules

# ── 3. Tauri cargo vendor ──────────────────────────────────────────────────

echo ">>> lemonade: creating ${CARGO_DEPS}..."
(
    cd "$SRC_DIR/src/app/src-tauri"
    export CARGO_HOME="$WORK/cargo-home"
    cargo vendor --locked --quiet
)
tar "${TAR_FLAGS[@]}" "$DISTDIR/$CARGO_DEPS" \
    -C "$SRC_DIR/src/app/src-tauri" vendor

# ── Upload to GitHub release ───────────────────────────────────────────────
# The release is tagged with the package name so the tarballs are reusable
# across ebuild revisions.

GH_REPO="bennypowers/gentoo-overlay"
TAG="lemonade"

# gh release upload does not create the release; make sure it exists.
if ! gh release view "$TAG" --repo "$GH_REPO" >/dev/null 2>&1; then
    echo ">>> lemonade: creating release $TAG..."
    gh release create "$TAG" --repo "$GH_REPO" --title "lemonade deps" \
        --notes "npm and cargo dependency cache" >/dev/null
fi

for asset in "$NPM_DEPS" "$APP_NPM_DEPS" "$CARGO_DEPS"; do
    echo ">>> lemonade: uploading $asset..."
    gh release upload "$TAG" "$DISTDIR/$asset" --repo "$GH_REPO" --clobber
done

echo ">>> lemonade: done"
