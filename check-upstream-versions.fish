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

# Extract a variable value from ebuild (single line only)
function get_ebuild_var
    set -l ebuild_file $argv[1]
    set -l var_name $argv[2]

    # Simple extraction - single line values only
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

    # Extract all GitHub URLs from the ebuild, then clean to owner/repo
    # This handles multi-line HOMEPAGE, SRC_URI, and EGIT_REPO_URI values
    set -l github_urls (grep -oE 'https?://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' $ebuild_file)

    for url in $github_urls
        set -l repo (echo $url | \
            sed -E 's|.*github\.com/||' | \
            sed -E 's|\.git$||' | \
            cut -d/ -f1,2)

        # Skip URLs containing ebuild variable references
        if string match -qr '\$\{' "$repo"
            continue
        end

        # Must be owner/repo format (exactly one slash)
        if string match -qr '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' "$repo"
            echo $repo
            return 0
        end
    end

    return 1
end

# Extract the upstream PyPI package name from an ebuild
# Checks for MY_PN, PYPI_PN overrides, or falls back to directory name
function get_pypi_name
    set -l ebuild_file $argv[1]
    set -l package_name (basename (dirname $ebuild_file))

    # Check for PYPI_PN override
    set -l pypi_pn (get_ebuild_var $ebuild_file PYPI_PN)
    if test -n "$pypi_pn"
        echo $pypi_pn
        return 0
    end

    # Check for MY_PN override (common pattern for renamed packages)
    set -l my_pn (get_ebuild_var $ebuild_file MY_PN)
    if test -n "$my_pn"
        echo $my_pn
        return 0
    end

    echo $package_name
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

# Strip tag prefixes to extract a clean version string
# Handles: v1.2.3, V1.2.3, v.1.2.3, release-1.2.3, rocm-1.2.3, etc.
function strip_tag_prefix
    set -l tag $argv[1]

    # Strip common prefixes, ordered from most specific to least
    # rocm-X.Y.Z
    set tag (string replace --regex -- '^rocm-' '' $tag)
    # release-X.Y.Z
    set tag (string replace --regex -- '^release-' '' $tag)
    # v.X.Y.Z (e.g., gmic uses "v.3.7.2")
    set tag (string replace --regex -- '^[vV]\.' '' $tag)
    # vX.Y.Z or VX.Y.Z (only strip if followed by a digit)
    set tag (string replace --regex -- '^[vV](?=\d)' '' $tag)

    echo $tag
end

# Check if a string looks like a version number
function is_version_like
    string match -qr '^\d+[\.\d]*' $argv[1]
end

# Extract a YYYYMMDD date from a string (tag name, version, etc.)
# Handles: stable_20250916, 1.20250916, 6.12.47_p20250916, etc.
function extract_date_from_string
    set -l str $argv[1]
    set -l date_match (string match -r '(20\d{6})' $str)
    if test (count $date_match) -ge 2
        echo $date_match[2]
        return 0
    end
    return 1
end

# Fetch latest non-semver tag info from GitHub
# Returns: "tag_name|tag_date" or fails
# Uses the GraphQL API to get tags sorted by commit date (descending)
function fetch_github_latest_tag_by_date
    set -l repo $argv[1]
    set -l cache_file "$CACHE_DIR/github-tags-"(string replace -a / - $repo)

    if test -f $cache_file
        cat $cache_file
        return 0
    end

    set -l owner (string split / $repo)[1]
    set -l name (string split / $repo)[2]

    # Use GraphQL to get the most recent tags by commit date
    set -l query '
    query($owner: String!, $name: String!) {
      repository(owner: $owner, name: $name) {
        refs(refPrefix: "refs/tags/", orderBy: {field: TAG_COMMIT_DATE, direction: DESC}, first: 10) {
          nodes {
            name
            target {
              ... on Commit { committedDate }
              ... on Tag { target { ... on Commit { committedDate } } tagger { date } }
            }
          }
        }
      }
    }'

    set -l tag_data (gh api graphql \
        -f query="$query" \
        -f owner="$owner" \
        -f name="$name" \
        --jq '.data.repository.refs.nodes[] | .name + "|" + (.target.committedDate // .target.tagger.date // .target.target.committedDate // "")' \
        2>/dev/null)

    if test -z "$tag_data"
        return 1
    end

    for line in $tag_data
        set -l tag_name (string split '|' $line)[1]
        set -l tag_raw_date (string split '|' $line)[2]

        # Skip obvious pre-release tags
        if string match -qri 'alpha|beta|rc|dev|nightly|canary' "$tag_name"
            continue
        end

        # Try to extract a YYYYMMDD date from the tag name first
        set -l tag_date (extract_date_from_string "$tag_name")

        # Fall back to the commit/tagger date
        if test -z "$tag_date" -a -n "$tag_raw_date"
            set tag_date (string replace -r -a '-' '' (string sub -l 10 $tag_raw_date))
        end

        if test -n "$tag_date"
            echo "$tag_name|$tag_date" | tee $cache_file
            return 0
        end
    end

    return 1
end

# Fetch latest version from GitHub
# Checks both releases and tags, preferring whichever yields the newer version
# Sets GITHUB_TAG_INFO when a non-semver tag is found (for date-based comparison)
function fetch_github_version
    set -l repo $argv[1]
    set -l cache_file "$CACHE_DIR/github-"(string replace -a / - $repo)

    # Check cache
    if test -f $cache_file
        cat $cache_file
        return 0
    end

    set -l release_ver ""
    set -l tag_ver ""

    # Try releases
    set -l raw_release (gh release list -R $repo --limit 1 --json tagName -q '.[0].tagName' 2>/dev/null)
    if test -n "$raw_release" -a "$raw_release" != "null"
        # Filter out error messages (JSON responses)
        if not string match -q -r '^\{' "$raw_release"
            set release_ver (strip_tag_prefix $raw_release)
        end
    end

    # Try tags (may be newer than the latest release)
    set -l raw_tag (gh api "repos/$repo/tags" --jq '.[0].name' 2>/dev/null)
    if test -n "$raw_tag" -a "$raw_tag" != "null"
        if not string match -q -r '^\{' "$raw_tag"
            set tag_ver (strip_tag_prefix $raw_tag)
        end
    end

    # Pick the best version from releases and tags
    set -l ver ""
    if test -n "$release_ver" -a -n "$tag_ver"
        # Both available: compare and use the newer one
        if is_version_like $release_ver; and is_version_like $tag_ver
            set -l newer (compare_versions $release_ver $tag_ver)
            if test "$newer" = "outdated"
                # release < tag, so tag is newer
                set ver $tag_ver
            else
                set ver $release_ver
            end
        else if is_version_like $tag_ver
            set ver $tag_ver
        else if is_version_like $release_ver
            set ver $release_ver
        end
    else if test -n "$release_ver"
        set ver $release_ver
    else if test -n "$tag_ver"
        set ver $tag_ver
    end

    # Validate that the result looks like a version
    if test -n "$ver"; and is_version_like $ver
        echo $ver | tee $cache_file
        return 0
    end

    # No semver found -- try date-based tag comparison
    set -l tag_info (fetch_github_latest_tag_by_date $repo)
    if test -n "$tag_info"
        # Store for the caller to use in date-based comparison
        set -g GITHUB_TAG_INFO $tag_info
        return 2 # Special return code: non-semver tag found
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
                set -l pypi_name (get_pypi_name $ebuild_file)
                set latest_ver (fetch_pypi_version $pypi_name)
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
    set -g GITHUB_TAG_INFO ""
    set -l fetch_result 1
    if is_pypi_package $ebuild_file
        set -l pypi_name (get_pypi_name $ebuild_file)
        set src "PyPI:$pypi_name"
        set latest_ver (fetch_pypi_version $pypi_name)
        and set fetch_result 0
    else if set -l repo (extract_github_repo $ebuild_file)
        set src "GitHub:$repo"
        set latest_ver (fetch_github_version $repo)
        set fetch_result $status
    end

    # Compare versions
    if test $fetch_result -eq 0 -a -n "$latest_ver" -a "$latest_ver" != "unknown"
        # Standard semver comparison
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
    else if test $fetch_result -eq 2 -a -n "$GITHUB_TAG_INFO"
        # Non-semver tag found -- do date-based comparison
        set -l tag_name (string split '|' $GITHUB_TAG_INFO)[1]
        set -l tag_date (string split '|' $GITHUB_TAG_INFO)[2]

        # Try to extract a date from the current ebuild version
        set -l current_date (extract_date_from_string $current_ver)

        set latest_ver "$tag_name"
        if test -n "$current_date" -a -n "$tag_date"
            if test "$tag_date" -gt "$current_date"
                set pkg_status (printf "$COLOR_YELLOW%s$COLOR_RESET" "NEWER-TAG")
            else if test "$tag_date" = "$current_date"
                set pkg_status (printf "$COLOR_GREEN%s$COLOR_RESET" "UP-TO-DATE")
            else
                set pkg_status (printf "$COLOR_BLUE%s$COLOR_RESET" "AHEAD")
            end
        else
            set pkg_status (printf "$COLOR_YELLOW%s$COLOR_RESET" "CHECK-TAG")
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
