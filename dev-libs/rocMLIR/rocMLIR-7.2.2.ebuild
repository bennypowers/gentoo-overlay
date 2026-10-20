# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION=${PV}
LLVM_SLOT="22"

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
	sed -i 's|rocm_path / "amdgcn"|rocm_path / "lib" / "amdgcn"|' \
		mlir/lib/Target/AmdDeviceLibsIncGen.py || die
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_SKIP_INSTALL_RPATH=OFF
		-DCMAKE_INSTALL_RPATH=""
		-DCMAKE_INSTALL_LIBDIR="$(get_libdir)"
		# Do NOT set LLVM_LIBDIR_SUFFIX -- it breaks the fat archive build
		# by making bundled LLVM use lib64/ while the MRI script expects lib/.
		# The bundled LLVM is internal only; CMAKE_INSTALL_LIBDIR controls
		# the installed library path. Static archives in usr/lib do not trip
		# multilib-strict (it only denies shared libs there).
		# Build bundled LLVM/MLIR as static libs so the fat archive
		# (librockCompiler.a) can combine them into a self-contained unit.
		# The FAT branch also carries the entire export machinery: package
		# config, rocMLIR::rockCompiler target, and the full header set;
		# shared builds install none of those, and shipping the shared
		# component libraries would put a second LLVM (22) next to comgr's
		# libLLVM.so.23 in hipRTC processes with interposable symbols.
		-DBUILD_SHARED_LIBS=OFF
		-DBUILD_FAT_LIBROCKCOMPILER=ON
		-DCMAKE_C_COMPILER="${EPREFIX}/usr/lib/llvm/${LLVM_SLOT}/bin/clang"
		-DCMAKE_CXX_COMPILER="${EPREFIX}/usr/lib/llvm/${LLVM_SLOT}/bin/clang++"
		# Need build-tree rpaths so internal llvm-min-tblgen can find
		# libLLVMTableGen.so; strip rpaths only at install time.
		-DCMAKE_SKIP_BUILD_RPATH=OFF
		-DCMAKE_BUILD_TYPE=Release
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr"
		-DBUILD_TESTING=$(usex test ON OFF)
		-Wno-dev
	)

	cmake_src_configure
}

src_test() {
	cmake_src_test
}
