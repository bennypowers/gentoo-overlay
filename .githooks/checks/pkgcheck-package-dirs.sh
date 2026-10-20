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

# NonsolvableDeps* and RequiredUseDefaults fire on musl/hurd/x32 profiles
# for deps that cannot exist there (nvidia-drivers, systemd, nodejs); this
# overlay only targets amd64 glibc, so those results are filtered out here.
# NonexistentDeps lines mentioning specific atoms are also filtered: those
# packages live in other configured repos (guru, brother-overlay,
# hyproverlay) which pkgcheck's domain (this repo + ::gentoo) cannot see.
# The migraphx RedundantVersion is a deliberate two-generation keep
# (7.2.4-r1 for ROCm 7.2 stacks, 10.1 for current). gaia depends on
# dev-python/httpx, which ::gentoo deprecated after upstream abandoned
# it; gaia still requires it, so that result is filtered too.
# shellcheck disable=SC2086
output=$(pkgcheck scan $dirs -k error,warning 2>&1 | grep -vE 'NonsolvableDeps(InDev|InExp|InStable)|RequiredUseDefaults|NonexistentDeps:.*(gui-wm/niri|gui-wm/hyprland|dev-python/pygls|dev-python/textual|sci-libs/onnxruntime|media-gfx/brother-scan4-bin|dev-python/openai)|RedundantVersion: version 7.2.4-r1|DeprecatedDep:.*dev-python/httpx' || true)

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
