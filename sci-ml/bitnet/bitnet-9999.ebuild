# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

LLVM_COMPAT=( {18..22} )

inherit cmake git-r3 llvm-r2

DESCRIPTION="Official inference framework for 1-bit LLMs"
HOMEPAGE="https://github.com/microsoft/BitNet"
EGIT_REPO_URI="https://github.com/microsoft/BitNet.git"

LICENSE="MIT"
SLOT="0"
IUSE="+openmp tl2"

DEPEND="
	openmp? ( llvm-runtimes/openmp:= )
"
RDEPEND="${DEPEND}"
BDEPEND="
	$(llvm_gen_dep '
		llvm-core/clang:${LLVM_SLOT}
	')
"

src_configure() {
	local mycmakeargs=(
		-DCMAKE_C_COMPILER="$(get_llvm_prefix)/bin/clang"
		-DCMAKE_CXX_COMPILER="$(get_llvm_prefix)/bin/clang++"
		-DBITNET_X86_TL2=$(usex tl2)
		-DBUILD_NUMBER=1
	)
	cmake_src_configure
}

src_install() {
	newbin "${BUILD_DIR}/bin/llama-cli" bitnet-cli
	newbin "${BUILD_DIR}/bin/llama-server" bitnet-server

	insinto /usr/share/${PN}
	doins run_inference.py
	doins setup_env.py

	dodoc README.md
}
