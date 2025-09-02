#!/usr/bin/env fish
# A fish script to update all Manifest files in a Gentoo repository.
# Find every ebuild file in the current directory and its subdirectories,
# and for each one, run the `ebuild manifest` command.

# Check if the user is root.
if [ (id -u) != "0" ]
    echo "Error: This script must be run as root to update manifests."
    echo "Please run with sudo: sudo ./update_manifests.fish"
    exit 1
end

# Find all ebuild files.
# `find . -name "*.ebuild"` will list all ebuilds.
# The result is piped to a `while` loop to process each one.
find . -name "*.ebuild" | while read -l ebuild_path
    # Print the path of the ebuild being processed.
    echo "Updating manifest for $ebuild_path"

    # Run the ebuild command to update the manifest.
    # We use `ebuild` with the full path to the ebuild file.
    # The `manifest` argument tells it to only update the Manifest file.
    ebuild $ebuild_path manifest
end

echo "All manifests have been updated."

