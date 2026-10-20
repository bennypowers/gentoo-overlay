#!/usr/bin/env bash
# Check: run pkgcheck on staged ebuild changes
# Used by: pre-commit hook

staged_ebuilds=$(git diff --cached --name-only --diff-filter=ACM | grep '\.ebuild$')

if [ -z "$staged_ebuilds" ]; then
    exit 0
fi

echo "Running pkgcheck on staged ebuilds..."

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
output=$(pkgcheck scan -r bennypowers --staged \
    -k error,warning \
    \
    2>&1 | grep -vE 'NonsolvableDeps(InDev|InExp|InStable)|RequiredUseDefaults|NonexistentDeps:.*(gui-wm/niri|gui-wm/hyprland|dev-python/pygls|dev-python/textual|sci-libs/onnxruntime|media-gfx/brother-scan4-bin|dev-python/openai)|RedundantVersion: version 7.2.4-r1|DeprecatedDep:.*dev-python/httpx' || true)

if [ -n "$output" ]; then
    echo ""
    echo "pkgcheck found issues in staged ebuilds:"
    echo "──────────────────────────────────────────"
    echo "$output"
    echo "──────────────────────────────────────────"
    exit 1
fi

echo "pkgcheck: no errors or warnings found."
