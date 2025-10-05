# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

LLVM_COMPAT=( 20 )
ROCM_VERSION=${PV}

inherit cmake llvm-r1

DESCRIPTION="MLIR-based convolution and GEMM kernel generator for AMD GPUs"
HOMEPAGE="https://github.com/ROCm/rocMLIR"
SRC_URI="https://github.com/ROCm/rocMLIR/archive/rocm-${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/rocMLIR-rocm-${PV}"

LICENSE="Apache-2.0 MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"

IUSE="test"
RESTRICT="!test? ( test )"

DEPEND="
	sys-devel/llvm:${LLVM_SLOT}=
	sys-devel/clang:${LLVM_SLOT}=
"

RDEPEND="${DEPEND}"

BDEPEND="
	>=dev-build/cmake-3.15.1
	dev-build/ninja
	>=dev-build/rocm-cmake-5.3
"

src_configure() {
	local llvm_prefix="$(get_llvm_prefix ${LLVM_SLOT})"

	local mycmakeargs=(
		-DCMAKE_C_COMPILER="${llvm_prefix}/bin/clang"
		-DCMAKE_CXX_COMPILER="${llvm_prefix}/bin/clang++"
		-DCMAKE_SKIP_RPATH=ON
		-DCMAKE_BUILD_TYPE=Release
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr"
		-DBUILD_FAT_LIBROCKCOMPILER=ON
		-DBUILD_TESTING=$(usex test ON OFF)
		-Wno-dev
	)

	cmake_src_configure
}

src_test() {
	cmake_src_test
}
