# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION=${PV}
LLVM_SLOT="20"

inherit cmake

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
	dev-libs/rocm-device-libs
	llvm-core/llvm:${LLVM_SLOT}=
	llvm-core/clang:${LLVM_SLOT}=
"

RDEPEND="${DEPEND}"

BDEPEND="
	>=dev-build/cmake-3.15.1
	dev-build/ninja
	>=dev-build/rocm-cmake-5.3
"

src_prepare() {
	cmake_src_prepare

	# Gentoo installs device libs to /usr/lib/amdgcn/bitcode/ but the
	# codegen script expects them at <prefix>/amdgcn/bitcode/ (no lib/).
	# AMD_DEVICE_LIBS_PREFIX resolves to /usr via the cmake config, so
	# fix the script to include the lib/ component.
	# Note: 7.1.x uses camelCase (rocmPath), 7.2.x uses snake_case (rocm_path).
	sed -i 's|rocmPath / "amdgcn"|rocmPath / "lib" / "amdgcn"|' \
		mlir/lib/Target/AmdDeviceLibsIncGen.py || die
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_C_COMPILER="${EPREFIX}/usr/lib/llvm/${LLVM_SLOT}/bin/clang"
		-DCMAKE_CXX_COMPILER="${EPREFIX}/usr/lib/llvm/${LLVM_SLOT}/bin/clang++"
		# Need build-tree rpaths so internal llvm-min-tblgen can find
		# libLLVMTableGen.so; strip rpaths only at install time.
		-DCMAKE_SKIP_BUILD_RPATH=OFF
		-DCMAKE_SKIP_INSTALL_RPATH=OFF
		-DCMAKE_INSTALL_RPATH=""
		-DCMAKE_BUILD_TYPE=Release
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr"
		-DCMAKE_INSTALL_LIBDIR="$(get_libdir)"
		-DLLVM_LIBDIR_SUFFIX="$(get_libdir | sed 's/lib//')"
		# Build bundled LLVM/MLIR as static libs so the fat archive
		# (librockCompiler.a) can combine them into a self-contained unit.
		-DBUILD_SHARED_LIBS=OFF
		-DBUILD_FAT_LIBROCKCOMPILER=ON
		-DBUILD_TESTING=$(usex test ON OFF)
		-Wno-dev
	)

	cmake_src_configure
}

src_test() {
	cmake_src_test
}
