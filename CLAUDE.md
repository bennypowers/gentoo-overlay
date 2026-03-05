# Gentoo Overlay Instructions

When working with this Gentoo overlay, always consult the README.md file for important instructions on:

- Generating manifests with custom DISTDIR
- Creating new ebuild revisions
- Repository workflow and syncing

Before creating or modifying ebuilds, read the README.md for the current best practices.

## Key Scripts

- `update-manifests.fish` - Update manifests for all ebuilds
- `check-upstream-versions.fish` - Check for upstream version updates
- `test-emerge.fish` - Test-build ebuilds locally without pushing

## Validating Ebuilds

Git hooks in `hooks/` run pkgcheck automatically on commit and push.
To install them: `git config core.hooksPath hooks`

Before creating or modifying ebuilds:

1. Run `pkgcheck scan -r bennypowers <cat/pkg>` to lint the ebuild
2. Run `./test-emerge.fish --pretend <cat/pkg>` to verify atom resolution
3. Run `./test-emerge.fish <cat/pkg>` to test fetch and unpack
4. Run `./test-emerge.fish --compile <cat/pkg>` to test compilation
