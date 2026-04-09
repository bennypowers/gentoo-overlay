# Gentoo Overlay Instructions

When working with this Gentoo overlay, always consult the README.md file for important instructions on:

- Generating manifests with custom DISTDIR
- Creating new ebuild revisions
- Repository workflow and syncing

Before creating or modifying ebuilds, read the README.md for the current best practices.

## Key Scripts

Script files are located in `./scripts/`. All scripts are self-contained and
need no sudo or interactive input.

- `larry` - Download distfiles, generate dep caches, upload, and create Manifest.
  Auto-detects type from ebuild content:
  - `npm`: downloads from npm registry, generates deps tarball, uploads to GitHub release
  - `cargo`: downloads Cargo.lock from GitHub tag, parses registry crates, updates CRATES variable
  - `generic`: just runs `ebuild digest`
- `check-upstream-versions` - Check for upstream version updates. Supports PyPI, GitHub,
  and npm registry. Use `--fresh` to clear cache. Cache expires after 6 hours.

## Workflows

### New ebuild

1. Create `<cat>/<pkg>/` directory, write the ebuild and `metadata.xml`
2. `scripts/larry prepare <cat>/<pkg>/<pkg>-<ver>.ebuild`
3. `pkgcheck scan -r bennypowers <cat>/<pkg>`
4. `scripts/larry test --pretend <cat>/<pkg>`
5. `scripts/larry test <cat>/<pkg>`

### Version bump (upstream release)

1. `scripts/larry bump <cat>/<pkg> <new-version>`
2. Edit the new ebuild if SRC_URI, deps, or patches changed
3. Re-run `scripts/larry prepare <cat>/<pkg>/<pkg>-<new-version>.ebuild` if edited
4. `pkgcheck scan -r bennypowers <cat>/<pkg>`
5. `scripts/larry test <cat>/<pkg>-<new-version>`

### Revision bump (fix existing ebuild)

1. `scripts/larry bump --revision <cat>/<pkg>`
2. Edit the new revision with the fix
3. Re-run `scripts/larry prepare <cat>/<pkg>/<pkg>-<ver>-rN.ebuild` if edited
4. `pkgcheck scan -r bennypowers <cat>/<pkg>`
5. `scripts/larry test <cat>/<pkg>-<ver>-rN`

## Validating Ebuilds

Git hooks in `hooks/` run pkgcheck automatically on commit and push.
To install them: `git config core.hooksPath hooks`

## Pre-flight checks

Before creating or modifying ebuilds, check `::gentoo` and `::guru` first with
`eix -e <pkg>`. If a suitable version exists in a main repo, drop ours instead
of bumping.

## Git

Prefer not to use worktrees for this git repository.
