![Larry the Cow](https://wiki.gentoo.org/images/thumb/b/b8/Larry-nefarius-v2.svg/600px-Larry-nefarius-v2.svg.png)

Install Gentoo. Do a Linux.

This repo is developed in a subdirectory of ~. Changes are pushed to GitHub, and picked up from there with emaint sync. When creating manifests, tools will have to fetch source tarballs themselves, since they often don't exist on upstream mirrors.

When making changes to ebuilds, copy them into a new revision first.

## Setup

Install the git hooks to get automatic QA checks on commit and push:

```bash
git config core.hooksPath hooks
```

## Generating Manifests

To generate manifests without sudo access to `/var/cache/distfiles`, use a custom DISTDIR:

```bash
mkdir -p /tmp/distfiles
DISTDIR=/tmp/distfiles ebuild package-version.ebuild digest
```

Or use the bulk script to update all manifests:

```bash
./update-manifests.fish
```

## Validating Ebuilds

### Lint with pkgcheck (runs automatically on commit)

```bash
# Scan only staged changes (used by pre-commit hook)
pkgcheck scan -r bennypowers --staged

# Scan only commits since last push
pkgcheck scan -r bennypowers --commits

# Scan a specific package
pkgcheck scan -r bennypowers dev-python/einops

# Full overlay scan
pkgcheck scan -r bennypowers
```

### Test-build locally

Use the `test-emerge` script to test fetch, unpack, compile, or full merge
of ebuilds in this overlay, without needing to push and sync first:

```bash
# Test that sources fetch and unpack correctly
./test-emerge.fish dev-python/einops-0.8.2
./test-emerge.fish dev-python/einops   # picks latest version

# Test through the compile phase
./test-emerge.fish --compile dev-python/einops-0.8.2

# Full build + install to image (does NOT merge into live system)
./test-emerge.fish --merge dev-python/einops-0.8.2

# Clean up build artifacts
./test-emerge.fish --clean dev-python/einops-0.8.2
```

### Check upstream versions

```bash
./check-upstream-versions.fish
```
