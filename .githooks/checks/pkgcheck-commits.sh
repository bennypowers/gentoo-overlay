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
output=$(pkgcheck scan -r bennypowers --commits \
    -k error,warning \
    \
    2>&1 | grep -vE 'NonsolvableDeps(InDev|InExp|InStable)|RequiredUseDefaults|NonexistentDeps:.*(gui-wm/niri|gui-wm/hyprland|dev-python/pygls|dev-python/textual|sci-libs/onnxruntime|dev-python/av|media-gfx/brother-scan4-bin|dev-python/openai)|RedundantVersion: version 7.2.4-r1|DeprecatedDep:.*dev-python/httpx' || true)

if [ -n "$output" ]; then
    echo ""
    echo "pkgcheck found issues in commits being pushed:"
    echo "──────────────────────────────────────────"
    echo "$output"
    echo "──────────────────────────────────────────"
    exit 1
fi

echo "pkgcheck: no errors or warnings found."
