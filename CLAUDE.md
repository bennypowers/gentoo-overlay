# Gentoo Overlay Instructions

When working with this Gentoo overlay, always consult the README.md file for important instructions on:

- Generating manifests with custom DISTDIR
- Creating new ebuild revisions
- Repository workflow and syncing

Before creating or modifying ebuilds, read the README.md for the current best practices.

## Key Scripts

Script files are located in `./scripts/`. All scripts are self-contained and
need no sudo or interactive input.

- `larry` - Overlay management CLI with subcommands:
  - `import` - Import ebuild from another overlay (::guru, ::gentoo), rewrite maintainer, prepare
  - `bump` - Copy latest ebuild to new version or revision, then prepare
  - `prepare` - Download distfiles, generate dep caches, upload, and create Manifest.
    Auto-detects type from ebuild content:
    - `npm`: downloads from npm registry, generates deps tarball, uploads to GitHub release
    - `cargo`: downloads Cargo.lock from GitHub tag (tries root, then `bindings/python/`), parses registry crates, updates CRATES variable
    - `go`: downloads source, runs `go mod vendor`, stores deps tarball in package dir
    - `generic`: just runs `ebuild digest`
  - `test` - Test-build ebuilds locally without pushing. Accepts `--compile`, `--merge`,
    or any ebuild phase like `--prepare`, `--configure`, `--install`. Multiple phases can
    be combined: `larry test --fetch --unpack --prepare <atom>`.
    Use `--emerge` for clean-room container builds with GPU passthrough.
  - `upstream` - Check for upstream version updates. Supports PyPI, GitHub,
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

## Commit Messages
use conventional commit style

## Push Hook

The remote push hook rejects modifying already-pushed ebuilds in-place.
If you edit an ebuild that exists on origin, you **must** create a new revision instead:

1. Copy the ebuild to a new revision: `<pkg>-<ver>-rN.ebuild`
2. Apply the fix to the new revision
3. Keep the old ebuild unchanged
4. Commit only the new revision (not the old one)

Git hooks in `hooks/` run pkgcheck automatically on commit and push.
To install them: `git config core.hooksPath hooks`

## Pre-flight checks

Before creating or modifying ebuilds, check `::gentoo` and `::guru` first with
`eix -e <pkg>`. If a suitable version exists in a main repo, drop ours instead
of bumping.

## npm Dependencies

Builds that run `npm install`/`npm ci` during compile fail because the
Gentoo sandbox blocks network access. **Do not** disable the sandbox with
`unset FEATURES` — that disables the entire sandbox (filesystem, mount,
kernel, network), not just network. That's a terrible security regression.

Instead, vendor npm deps into a tarball:

1. Install deps locally: `npm ci --ignore-scripts`
2. Tar the result: `tar caf ${P}-npm-deps.tar.xz node_modules`
3. Upload to GitHub release with the **package name** as tag (not version):
   `gh release create ${PN} --repo $GH_REPO ${P}-npm-deps.tar.xz`
4. Add to ebuild `SRC_URI`, extract in `src_prepare()`, patch CMake to
   skip `npm ci`

Using the package name as the release tag (not the version) means the tarball
is reusable across revisions and the name matches the ebuild's package.

## Unbundling Dependencies

Gentoo policy requires using system libraries over bundled copies.
See [Why not bundle dependencies](https://wiki.gentoo.org/wiki/Why_not_bundle_dependencies).

When upstream Python packages bundle C/shared libraries (e.g. shipping a
prebuilt `.so` in a wheel), patch them out and depend on system packages.

Established patterns from ::gentoo:

- `dev-python/blake3`: patch + `FORCE_SYSTEM_BLAKE3=1` + `rm -r` vendored source
- `dev-python/grpcio`: `GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1` etc.
- `dev-python/argon2-cffi-bindings`: `ARGON2_CFFI_USE_SYSTEM=1`
- CPython itself: `--with-system-expat`, removes bundled ensurepip

General approach:

1. Add system library to DEPEND/RDEPEND
2. Set env var or patch build to force system usage
3. Optionally `rm -r` vendored sources to guarantee they are not used

## ML Model Files

Do not package large (100MB+) ML model files as distfiles. Gentoo mirrors
and distfile infrastructure are not designed for multi-gigabyte weights.

Patterns by size (from ::gentoo precedent):

| Size | Approach | Example |
|------|----------|---------|
| KB-MB per file | Separate data package + L10N USE | `tessdata_best`, `mbrola-voices` |
| ~30MB, version-coupled | SRC_URI inline | `libpinyin` |
| 100MB+ / user-selected | Runtime download only | `ollama`, `whisper-cpp`, `transformers` |

For ML inference packages: install engine only, print download instructions
in `pkg_postinst`. Use `sci-ml/huggingface_hub` when models are on HuggingFace.

## Git

Prefer not to use worktrees for this git repository.
