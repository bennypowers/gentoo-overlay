# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

LLVM_COMPAT=( {18..22} )

inherit cmake git-r3 llvm-r2 systemd toolchain-funcs

DESCRIPTION="Official inference framework for 1-bit LLMs"
HOMEPAGE="https://github.com/microsoft/BitNet"
EGIT_REPO_URI="https://github.com/microsoft/BitNet.git"

LICENSE="MIT"
SLOT="0"
IUSE="+openmp cpu_flags_x86_avx2 cpu_flags_arm_neon"

DEPEND="
	openmp? ( llvm-runtimes/openmp:= )
"
RDEPEND="
	${DEPEND}
	acct-user/ollama
"
BDEPEND="
	$(llvm_gen_dep '
		llvm-core/clang:${LLVM_SLOT}
	')
"

bitnet_run_codegen() {
	# The forked llama.cpp unconditionally references bitnet-lut-kernels.h.
	# Codegen creates it with arch-specific optimized kernels; the content
	# is guarded by preprocessor conditionals.
	local codegen_script codegen_args=(
		--model bitnet_b1_58-3B
		--BM 160,320,320
		--BK 96,96,96
		--bm 32,32,32
	)

	if use cpu_flags_arm_neon; then
		codegen_script=utils/codegen_tl1.py
	else
		codegen_script=utils/codegen_tl2.py
	fi

	python3 "${codegen_script}" "${codegen_args[@]}" \
		|| die "codegen failed"
}

src_prepare() {
	# Fix const-correctness for clang >= 21
	sed -i 's/int8_t \* y_col = y/const int8_t * y_col = y/' \
		src/ggml-bitnet-mad.cpp || die

	cmake_src_prepare
	bitnet_run_codegen
}

src_configure() {
	CC="$(get_llvm_prefix)/bin/clang"
	CXX="$(get_llvm_prefix)/bin/clang++"
	tc-export CC CXX

	local mycmakeargs=(
		-DBITNET_X86_TL2=$(usex cpu_flags_x86_avx2 ON OFF)
		-DBITNET_ARM_TL1=$(usex cpu_flags_arm_neon ON OFF)
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

	systemd_dounit "${FILESDIR}/bitnet.service"

	keepdir /var/lib/bitnet/models

	dodoc README.md
}
