# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.85.0"

inherit cargo git-r3

DESCRIPTION="Rust LLM inference engine for AMD Radeon AI PRO R9700 (gfx1201 / RDNA4)"
HOMEPAGE="https://github.com/GGZ14/saber-engine"
EGIT_REPO_URI="https://github.com/GGZ14/saber-engine.git"
EGIT_BRANCH="main"
EGIT_LIVECTHOUR="12"

LICENSE="Apache-2.0"
# Dependent crate licenses
LICENSE+="
	BSD ISC MIT ZLIB Unicode-3.0
	|| ( Apache-2.0 BSD-2 )
	|| ( Apache-2.0 MIT )
	|| ( BSD-2 MIT )
"
SLOT="0"
KEYWORDS=""

# The engine dlopens libamdhip64.so.7 (ROCm 7.x HIP) at run time via
# --hip-lib; there is no portage ebuild for the HIP runtime, so no
# RDEPEND on it. Weights are runtime-downloaded packs, not distfiles.

src_unpack() {
	git-r3_src_unpack

	# `cargo fetch`/`cargo vendor` into the vendor dir and generate a
	# .cargo/config.toml pinning crates to it for offline builds.
	cd "${S}" || die
	cargo_live_src_unpack
	cd "${WORKDIR}" || die
}

src_compile() {
	cargo_src_compile -p saber-cli
}

src_install() {
	dobin "$(cargo_target_dir)/saber"
	dodoc README.md LICENSE NOTICE

	# Prebuilt gfx1201 HIP code objects + kernarg manifests. The CLI's
	# default --prebuilt is the repo-relative "prebuilt/gfx1201", so
	# installed users must pass --prebuilt /usr/share/saber/kernels/gfx1201.
	insinto /usr/share/saber/kernels
	doins -r prebuilt/gfx1201
}

pkg_postinst() {
	einfo "saber needs a ROCm 7.x HIP runtime (libamdhip64.so.7) at run time"
	einfo "and prebuilt weight packs (~26 GB for Qwen3.8-27B), see ${HOMEPAGE}."
	einfo "Example:"
	einfo "  saber serve --engine real --tp 2 \\"
	einfo "    --hip-lib /opt/rocm/lib/libamdhip64.so.7 \\"
	einfo "    --prebuilt /usr/share/saber/kernels/gfx1201 \\"
	einfo "    --pack /path/to/packs"
}
