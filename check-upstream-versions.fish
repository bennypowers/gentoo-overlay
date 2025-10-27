#!/usr/bin/env fish

# Script to check for outdated packages in this Gentoo overlay
# Compares current ebuild versions with latest upstream releases

set -g OVERLAY_DIR (dirname (status --current-filename))
set -g CACHE_DIR /tmp/overlay-version-check-cache
set -g CHECKED_PACKAGES # Track checked packages to avoid cycles

# Color codes for output
set -g COLOR_RESET \e\[0m
set -g COLOR_GREEN \e\[32m
set -g COLOR_YELLOW \e\[33m
set -g COLOR_RED \e\[31m
set -g COLOR_BLUE \e\[34m
set -g COLOR_GRAY \e\[90m

function setup_cache
    mkdir -p $CACHE_DIR
end

function cleanup_cache
    rm -rf $CACHE_DIR
end

# Extract version from ebuild filename
# Example: package-1.2.3.ebuild -> 1.2.3
# Example: package-1.2.3-r1.ebuild -> 1.2.3
function get_version_from_filename
    set -l ebuild_file $argv[1]
    set -l basename (basename $ebuild_file .ebuild)
    # Remove package name prefix and revision suffix
    set -l package_name (basename (dirname $ebuild_file))
    set -l ver (string replace -r "^$package_name-" "" $basename)
    set -l ver (string replace --regex -- '-r[0-9]+$' "" $ver)
    echo $ver
end

# Parse category and package name from ebuild path
function get_package_info
    set -l ebuild_path $argv[1]
    set -l package_name (basename (dirname $ebuild_path))
    set -l category (basename (dirname (dirname $ebuild_path)))
    echo "$category/$package_name"
end

# Find all ebuilds in the overlay
function find_all_ebuilds
    find $OVERLAY_DIR -name "*.ebuild" -type f | grep -v metadata | sort
end

# Find the latest version ebuild for a package (excluding -9999)
function find_latest_versioned_ebuild
    set -l category $argv[1]
    set -l package $argv[2]
    set -l package_dir "$OVERLAY_DIR/$category/$package"

    # Get all versioned ebuilds (not -9999)
    set -l ebuilds (find $package_dir -name "*.ebuild" ! -name "*-9999.ebuild" 2>/dev/null | sort -V | tail -1)

    if test -n "$ebuilds"
        echo $ebuilds
        return 0
    end
    return 1
end

# Check if package has a live ebuild (-9999)
function has_live_ebuild
    set -l category $argv[1]
    set -l package $argv[2]
    set -l package_dir "$OVERLAY_DIR/$category/$package"

    test -f "$package_dir/$package-9999.ebuild"
end

# Extract a variable value from ebuild
function get_ebuild_var
    set -l ebuild_file $argv[1]
    set -l var_name $argv[2]

    # Simple extraction - might not handle all cases perfectly
    grep -E "^$var_name=" $ebuild_file | head -1 | sed -E "s/^$var_name=\"?([^\"]*)\"?.*/\1/" | string trim
end

# Detect if ebuild inherits from pypi
function is_pypi_package
    set -l ebuild_file $argv[1]
    grep -q "inherit.*pypi" $ebuild_file
end

# Extract GitHub repo from various sources in ebuild
function extract_github_repo
    set -l ebuild_file $argv[1]

    # Helper function to clean GitHub URL
    function clean_github_url
        echo $argv[1] | \
            sed -E 's|.*github\.com/||' | \
            sed -E 's|\.git$||' | \
            sed -E 's|#.*||' | \
            sed -E 's|[[:space:]].*||' | \
            sed -E 's|/archive.*||' | \
            sed -E 's|/releases.*||' | \
            sed -E 's|/tarball.*||' | \
            sed -E 's|/zipball.*||' | \
            sed -E 's|/$||' | \
            cut -d/ -f1,2
    end

    # Try HOMEPAGE first
    set -l homepage (get_ebuild_var $ebuild_file HOMEPAGE)
    if string match -qr "github\.com/" $homepage
        set -l repo (clean_github_url $homepage)
        if test -n "$repo" -a "$repo" != "github.com"
            echo $repo
            return 0
        end
    end

    # Try SRC_URI
    set -l src_uri (get_ebuild_var $ebuild_file SRC_URI)
    if string match -qr "github\.com/" $src_uri
        set -l repo (clean_github_url $src_uri)
        if test -n "$repo" -a "$repo" != "github.com"
            echo $repo
            return 0
        end
    end

    # Try EGIT_REPO_URI
    set -l git_uri (get_ebuild_var $ebuild_file EGIT_REPO_URI)
    if string match -qr "github\.com/" $git_uri
        set -l repo (clean_github_url $git_uri)
        if test -n "$repo" -a "$repo" != "github.com"
            echo $repo
            return 0
        end
    end

    return 1
end

# Fetch latest version from PyPI
function fetch_pypi_version
    set -l package_name $argv[1]
    set -l cache_file "$CACHE_DIR/pypi-$package_name"

    # Check cache
    if test -f $cache_file
        cat $cache_file
        return 0
    end

    # Fetch from PyPI
    set -l ver (curl -s "https://pypi.org/pypi/$package_name/json" | jq -r '.info.version' 2>/dev/null)

    if test -n "$ver" -a "$ver" != "null"
        echo $ver | tee $cache_file
        return 0
    end

    return 1
end

# Fetch latest version from GitHub
function fetch_github_version
    set -l repo $argv[1]
    set -l cache_file "$CACHE_DIR/github-"(string replace -a / - $repo)

    # Check cache
    if test -f $cache_file
        cat $cache_file
        return 0
    end

    # Try releases first
    set -l ver (gh release list -R $repo --limit 1 --json tagName -q '.[0].tagName' 2>/dev/null)

    # If no releases, try tags
    if test -z "$ver" -o "$ver" = "null" -o "$ver" = ""
        set ver (gh api "repos/$repo/tags" --jq '.[0].name' 2>/dev/null)
    end

    # Filter out error messages (JSON responses)
    if string match -q -r '^\{' "$ver"
        return 1
    end

    if test -n "$ver" -a "$ver" != "null" -a "$ver" != ""
        # Strip common prefixes like 'v', 'release-', 'rocm-', etc.
        set ver (string replace --regex -- '^[vV]' '' $ver)
        set ver (string replace --regex -- '^release-' '' $ver)
        set ver (string replace --regex -- '^rocm-' '' $ver)
        echo $ver | tee $cache_file
        return 0
    end

    return 1
end

# Compare two versions using Python packaging library
function compare_versions
    set -l current $argv[1]
    set -l latest $argv[2]

    # Returns: "outdated", "current", or "unknown"
    set -l result (python3 -c "
from packaging import version
try:
    current = version.parse('$current')
    latest = version.parse('$latest')
    if current < latest:
        print('outdated')
    elif current == latest:
        print('current')
    else:
        print('newer')
except Exception:
    print('unknown')
" 2>/dev/null)

    echo $result
end

# Parse dependencies from ebuild
function parse_dependencies
    set -l ebuild_file $argv[1]

    # Extract RDEPEND, DEPEND, BDEPEND
    # This is simplified and may not handle all ebuild syntax
    grep -E "^\s*(R|B)?DEPEND=" $ebuild_file | \
        sed 's/.*="\?\(.*\)"\?/\1/' | \
        grep -oE '[a-z0-9-]+/[a-z0-9_-]+' | \
        sort -u
end

# Check if a dependency exists in this overlay
function is_in_overlay
    set -l dep $argv[1]
    set -l category (string split / $dep)[1]
    set -l package (string split / $dep)[2]

    test -d "$OVERLAY_DIR/$category/$package"
end

# Main function to check a package and its dependencies
function check_package
    set -l cat_pkg $argv[1]
    set -l depth $argv[2]
    set -l category (string split / $cat_pkg)[1]
    set -l package (string split / $cat_pkg)[2]

    # Avoid cycles
    if contains $cat_pkg $CHECKED_PACKAGES
        return 0
    end
    set -g CHECKED_PACKAGES $CHECKED_PACKAGES $cat_pkg

    # Find latest versioned ebuild
    set -l ebuild_file (find_latest_versioned_ebuild $category $package)

    if test -z "$ebuild_file"
        # Only live ebuild exists
        if has_live_ebuild $category $package
            set ebuild_file "$OVERLAY_DIR/$category/$package/$package-9999.ebuild"
            set -l current_ver "9999 (live)"

            # Try to detect upstream anyway
            set -l latest_ver "unknown"
            set -l src "unknown"
            set -l pkg_status "LIVE"

            if is_pypi_package $ebuild_file
                set src "PyPI"
                set latest_ver (fetch_pypi_version $package)
                if test -n "$latest_ver"
                    set pkg_status "HAS-RELEASE"
                end
            else if set -l repo (extract_github_repo $ebuild_file)
                set src "GitHub"
                set latest_ver (fetch_github_version $repo)
                if test -n "$latest_ver"
                    set pkg_status "HAS-RELEASE"
                end
            end

            printf "%-35s %-15s %-15s %-15s %s\n" "$cat_pkg" "$current_ver" "$latest_ver" "$pkg_status" "$src"
        end
        return 0
    end

    # Get current version
    set -l current_ver (get_version_from_filename $ebuild_file)
    set -l latest_ver "unknown"
    set -l src "unknown"
    set -l pkg_status "UNKNOWN"

    # Detect upstream and fetch latest version
    if is_pypi_package $ebuild_file
        set src "PyPI"
        set latest_ver (fetch_pypi_version $package)
    else if set -l repo (extract_github_repo $ebuild_file)
        set src "GitHub:$repo"
        set latest_ver (fetch_github_version $repo)
    end

    # Compare versions
    if test -n "$latest_ver" -a "$latest_ver" != "unknown"
        set -l comparison (compare_versions $current_ver $latest_ver)
        switch $comparison
            case outdated
                set pkg_status (printf "$COLOR_RED%s$COLOR_RESET" "OUTDATED")
            case current
                set pkg_status (printf "$COLOR_GREEN%s$COLOR_RESET" "UP-TO-DATE")
            case newer
                set pkg_status (printf "$COLOR_BLUE%s$COLOR_RESET" "AHEAD")
            case unknown
                set pkg_status (printf "$COLOR_GRAY%s$COLOR_RESET" "UNKNOWN")
        end
    else
        set pkg_status (printf "$COLOR_GRAY%s$COLOR_RESET" "UNKNOWN")
        set latest_ver "?"
    end

    # Print package info with indentation based on depth
    set -l indent (string repeat -n (math $depth \* 2) " ")
    printf "%s%-35s %-15s %-15s %-15s %s\n" "$indent" "$cat_pkg" "$current_ver" "$latest_ver" "$pkg_status" "$src"

    # Check dependencies recursively
    if test $depth -lt 3 # Limit recursion depth
        set -l deps (parse_dependencies $ebuild_file)
        for dep in $deps
            if is_in_overlay $dep
                check_package $dep (math $depth + 1)
            end
        end
    end
end

# Main execution
function main
    echo "Checking packages in overlay: $OVERLAY_DIR"
    echo ""

    setup_cache

    # Print header
    printf "%-35s %-15s %-15s %-15s %s\n" "Package" "Current" "Latest" "Status" "Source"
    printf "%s\n" (string repeat -n 110 "─")

    # Get all unique packages
    set -l packages
    for ebuild in (find_all_ebuilds)
        set -l cat_pkg (get_package_info $ebuild)
        if not contains $cat_pkg $packages
            set packages $packages $cat_pkg
        end
    end

    # Check each package
    for cat_pkg in $packages
        check_package $cat_pkg 0
    end

    echo ""
    echo "Check complete. Cache stored in: $CACHE_DIR"
    echo "Run 'rm -rf $CACHE_DIR' to clear cache and force refresh."
end

# Run main
main
