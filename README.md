![Larry the Cow](https://wiki.gentoo.org/images/thumb/b/b8/Larry-nefarius-v2.svg/600px-Larry-nefarius-v2.svg.png)

> [!important]
> Install Gentoo. Do a Linux

# bennypowers overlay

A Gentoo overlay for packages that haven't herded their way into `::gentoo` or
`::guru` yet.

## Setup

```bash
git config core.hooksPath hooks   # QA checks on commit and push
```

## Scripts

All scripts live in `scripts/` and need no sudo. They do the heavy lifting
so Larry can keep chewing his cud.

| Script                    | What it does                                                                                          |
| ------------------------- | ----------------------------------------------------------------------------------------------------- |
| `prepare-ebuild`          | Download distfiles, generate dep caches, upload, and create Manifest. Auto-detects npm/cargo/generic. Use `--all` for the whole herd. |
| `bump-ebuild`             | Copy latest ebuild to a new version (`<atom> <ver>`) or next revision (`--revision <atom>`), then prepare it. |
| `test-emerge`             | Test-build ebuilds locally without pushing. Supports `--compile`, `--merge`, `--pretend`.             |
| `check-upstream-versions` | Check all packages for upstream updates (PyPI, GitHub, npm). Use `--fresh` to waddle past the cache.  |

## Workflow

```
eix -e <pkg>                                          # don't duplicate ::gentoo or ::guru
scripts/bump-ebuild <cat>/<pkg> <version>             # copies, fetches, caches, manifests
# edit the ebuild if needed, then re-run prepare-ebuild
pkgcheck scan -r bennypowers <cat>/<pkg>              # lint (also runs on commit)
scripts/test-emerge <cat>/<pkg>                       # moo-ve fast, break nothing
git add && git commit                                 # hooks handle the rest
```
