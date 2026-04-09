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

## Larry

Larry the CLI (`scripts/larry`) does the heavy lifting so Larry the Cow can
keep chewing his cud.

| Command            | What it does |
| ------------------ | ------------ |
| `larry bump`       | Copy latest ebuild to a new version or `--revision`, then prepare it. One command to moo-ve upstream. |
| `larry prepare`    | Download distfiles, generate dep caches, create Manifest. Auto-detects npm/cargo/generic. `--all` for the whole herd. |
| `larry check`      | Check all packages for upstream updates (PyPI, GitHub, npm). `--fresh` to waddle past the cache. |

`scripts/test-emerge` is still its own script for test-building ebuilds locally.

## Workflow

```
eix -e <pkg>                                          # don't duplicate ::gentoo or ::guru
scripts/larry bump <cat>/<pkg> <version>              # copies, fetches, caches, manifests
# edit the ebuild if needed, then re-run larry prepare
pkgcheck scan -r bennypowers <cat>/<pkg>              # lint (also runs on commit)
scripts/test-emerge <cat>/<pkg>                       # moo-ve fast, break nothing
git add && git commit                                 # hooks handle the rest
```
