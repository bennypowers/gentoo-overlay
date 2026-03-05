#!/usr/bin/env fish

# test-emerge: Test-build ebuilds from this overlay without pushing or syncing.
#
# Usage:
#   ./test-emerge.fish [options] <atom>
#
# Atoms:
#   category/package              Build the latest version
#   category/package-version      Build a specific version
#
# Options:
#   --compile, -c    Run through the compile phase (default: fetch + unpack)
#   --merge, -m      Run all phases through install (does NOT merge into live system)
#   --clean, -C      Clean build artifacts for the package
#   --pretend, -p    Show what would be done without running it
#   --help, -h       Show this help message
#
# Examples:
#   ./test-emerge.fish dev-python/einops
#   ./test-emerge.fish dev-python/einops-0.8.2
#   ./test-emerge.fish --compile dev-libs/migraphx-7.2.0
#   ./test-emerge.fish --merge media-gfx/gmic-3.7.2
#   ./test-emerge.fish --clean dev-python/einops-0.8.2

set -g OVERLAY_DIR (dirname (status --current-filename))
set -g DISTDIR /tmp/distfiles
set -g GENTOO_MIRRORS ""

# Color codes
set -g COLOR_RESET \e\[0m
set -g COLOR_GREEN \e\[32m
set -g COLOR_RED \e\[31m
set -g COLOR_YELLOW \e\[33m
set -g COLOR_BLUE \e\[34m
set -g COLOR_BOLD \e\[1m

function print_usage
    echo "Usage: test-emerge [options] <category/package[-version]>"
    echo ""
    echo "Test-build ebuilds from this overlay without pushing or syncing."
    echo ""
    echo "Options:"
    echo "  --compile, -c    Run through the compile phase (default: fetch + unpack)"
    echo "  --merge, -m      Run all phases through install (does NOT merge into live system)"
    echo "  --clean, -C      Clean build artifacts for the package"
    echo "  --pretend, -p    Show what would be done without running it"
    echo "  --help, -h       Show this help message"
    echo ""
    echo "Atoms:"
    echo "  category/package              Build the latest version"
    echo "  category/package-version      Build a specific version"
    echo ""
    echo "Examples:"
    echo "  ./test-emerge.fish dev-python/einops"
    echo "  ./test-emerge.fish dev-python/einops-0.8.2"
    echo "  ./test-emerge.fish --compile dev-libs/migraphx-7.2.0"
end

function msg
    printf "$COLOR_BOLD$COLOR_GREEN>>>$COLOR_RESET %s\n" $argv
end

function warn
    printf "$COLOR_BOLD$COLOR_YELLOW***$COLOR_RESET %s\n" $argv >&2
end

function err
    printf "$COLOR_BOLD$COLOR_RED!!!$COLOR_RESET %s\n" $argv >&2
end

# Parse a package atom into category, package name, and optional version
# Input: "dev-python/einops-0.8.2" or "dev-python/einops"
# Output: sets CATEGORY, PKG_NAME, PKG_VERSION
function parse_atom
    set -l atom $argv[1]

    # Must contain exactly one slash
    if not string match -qr '^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.+-]+$' $atom
        err "Invalid atom: $atom"
        err "Expected format: category/package or category/package-version"
        return 1
    end

    set -g CATEGORY (string split / $atom)[1]
    set -l remainder (string split / $atom)[2]

    set -l pkg_dir "$OVERLAY_DIR/$CATEGORY"
    if not test -d "$pkg_dir"
        err "Category not found: $CATEGORY"
        err "Available categories:" (find "$OVERLAY_DIR" -mindepth 1 -maxdepth 1 -type d -name '*-*' -printf '%f\n' | sort | string join ", ")
        return 1
    end

    # Try exact match first: does a directory named $remainder exist?
    if test -d "$pkg_dir/$remainder"
        set -g PKG_NAME $remainder
        set -g PKG_VERSION ""
        return 0
    end

    # Otherwise, try to split into name-version by finding a matching package dir
    # Walk backwards through hyphens to find the longest package name that matches a directory
    set -l parts (string split - $remainder)
    set -l num_parts (count $parts)

    for i in (seq $num_parts -1 1)
        set -l candidate_name (string join - $parts[1..$i])
        if test -d "$pkg_dir/$candidate_name"
            set -g PKG_NAME $candidate_name
            if test $i -lt $num_parts
                set -g PKG_VERSION (string join - $parts[(math $i + 1)..$num_parts])
            else
                set -g PKG_VERSION ""
            end
            return 0
        end
    end

    err "Package not found: $atom"
    err "Available packages in $CATEGORY:" (ls -1 "$pkg_dir" | string join ", ")
    return 1
end

# Find the ebuild file for the parsed atom
function find_ebuild
    set -l pkg_dir "$OVERLAY_DIR/$CATEGORY/$PKG_NAME"

    if test -n "$PKG_VERSION"
        # Specific version requested
        set -l ebuild "$pkg_dir/$PKG_NAME-$PKG_VERSION.ebuild"
        if test -f "$ebuild"
            echo $ebuild
            return 0
        end

        err "Ebuild not found: $PKG_NAME-$PKG_VERSION"
        err "Available versions:"
        for f in $pkg_dir/$PKG_NAME-*.ebuild
            set -l ver (basename $f .ebuild | string replace "$PKG_NAME-" "")
            echo "  $ver" >&2
        end
        return 1
    end

    # No version specified: find the latest non-9999 ebuild
    set -l ebuilds (find $pkg_dir -name "$PKG_NAME-*.ebuild" ! -name "*-9999.ebuild" 2>/dev/null | sort -V)

    if test -z "$ebuilds"
        # Fall back to 9999
        set ebuilds (find $pkg_dir -name "$PKG_NAME-9999.ebuild" 2>/dev/null)
    end

    if test -z "$ebuilds"
        err "No ebuilds found in $pkg_dir"
        return 1
    end

    # Return the last (highest version)
    echo $ebuilds[-1]
end

# Main
function main
    set -l mode "unpack" # default: fetch + unpack
    set -l pretend false
    set -l atom ""

    # Parse arguments
    for arg in $argv
        switch $arg
            case --compile -c
                set mode "compile"
            case --merge -m
                set mode "merge"
            case --clean -C
                set mode "clean"
            case --pretend -p
                set pretend true
            case --help -h
                print_usage
                return 0
            case '-*'
                err "Unknown option: $arg"
                print_usage
                return 1
            case '*'
                if test -n "$atom"
                    err "Multiple atoms not supported, got: $atom and $arg"
                    return 1
                end
                set atom $arg
        end
    end

    if test -z "$atom"
        err "No package atom specified"
        print_usage
        return 1
    end

    # Parse the atom
    parse_atom $atom
    or return 1

    # Find the ebuild
    set -l ebuild (find_ebuild)
    or return 1

    set -l ebuild_basename (basename $ebuild)
    set -l ver (string replace "$PKG_NAME-" "" (basename $ebuild .ebuild))

    msg "Package: $CATEGORY/$PKG_NAME-$ver"
    msg "Ebuild:  $ebuild"

    # Determine phases to run
    set -l phases
    set -l description
    switch $mode
        case unpack
            set phases clean fetch unpack
            set description "fetch and unpack"
        case compile
            set phases clean fetch unpack compile
            set description "compile"
        case merge
            set phases clean fetch unpack compile install
            set description "full build + install (to image only)"
        case clean
            set phases clean
            set description "clean"
    end

    msg "Mode:    $description ($phases)"
    echo ""

    if $pretend
        warn "Pretend mode: would run:"
        echo "  sudo DISTDIR=$DISTDIR GENTOO_MIRRORS=\"\" ebuild $ebuild $phases"
        return 0
    end

    # Ensure DISTDIR and TMPDIR exist
    mkdir -p $DISTDIR
    set -l tmpdir /tmp/portage-test
    mkdir -p $tmpdir

    # Run without sandbox so we don't need root.
    # Sandbox catches install-path mistakes but isn't needed for test builds.
    set -x FEATURES "-sandbox -usersandbox -network-sandbox -ipc-sandbox -pid-sandbox"
    set -x PORTAGE_TMPDIR $tmpdir
    set -x DISTDIR $DISTDIR
    set -x GENTOO_MIRRORS ""
    ebuild $ebuild $phases

    set -l status_code $status
    echo ""

    if test $status_code -eq 0
        msg "Success: $CATEGORY/$PKG_NAME-$ver ($description)"
    else
        err "Failed: $CATEGORY/$PKG_NAME-$ver ($description)"
        err "Exit code: $status_code"
    end

    return $status_code
end

main $argv
