#!/usr/bin/env fish
# A fish script to update all Manifest files in a Gentoo repository.
# Find every ebuild file in the current directory and its subdirectories,
# and for each one, run the `ebuild digest` command.

# Create a temporary DISTDIR to avoid needing sudo access to /var/cache/distfiles
set -x DISTDIR /tmp/distfiles
# Skip Gentoo mirrors and download directly from upstream sources
set -x GENTOO_MIRRORS ""
mkdir -p $DISTDIR

# Find all ebuild files.
# `find . -name "*.ebuild"` will list all ebuilds.
# The result is piped to a `while` loop to process each one.
find . -name "*.ebuild" | while read -l ebuild_path
    # Print the path of the ebuild being processed.
    echo "Updating manifest for $ebuild_path"

    # Run the ebuild command to update the manifest.
    # We use `ebuild` with the full path to the ebuild file.
    # The `digest` argument tells it to fetch sources and update the Manifest file.
    ebuild $ebuild_path digest
end

echo "All manifests have been updated."

