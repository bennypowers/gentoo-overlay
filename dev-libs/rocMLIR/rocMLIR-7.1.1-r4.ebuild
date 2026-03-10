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
		# FAT static archive requires static libs which Gentoo doesn't build;
		# the shared libMLIRRockThin.so provides the same functionality.
		-DBUILD_FAT_LIBROCKCOMPILER=OFF
		-DBUILD_TESTING=$(usex test ON OFF)
		-Wno-dev
	)

	cmake_src_configure
}

src_install() {
	# Upstream gates all install rules behind BUILD_FAT_LIBROCKCOMPILER,
	# which requires static LLVM/MLIR libs Gentoo doesn't build.
	# Manually install the thin shared library, headers, and cmake config
	# so downstream consumers (migraphx) can use find_package(rocMLIR).
	# https://github.com/ROCm/rocMLIR/issues/1947

	# Install the thin shared library
	dolib.so "${BUILD_DIR}/lib/libMLIRRockThin.so"

	# Install rocMLIR's own C API headers (Rock/MIGraphX dialects)
	insinto /usr/include/rocmlir
	doins -r "${S}"/mlir/include/mlir-c

	# Install standard MLIR C API headers from bundled LLVM
	# (mlir-c/IR.h, mlir-c/Support.h, etc.) — these are included
	# transitively by the Rock dialect headers
	doins -r "${S}"/external/llvm-project/mlir/include/mlir-c

	# Install cmake config for find_package(rocMLIR CONFIG)
	local libdir="$(get_libdir)"
	local cmakedir="/usr/${libdir}/cmake/rocMLIR"
	insinto "${cmakedir}"

	cat > "${T}/rocMLIRConfig.cmake" <<-_EOF_ || die
		get_filename_component(_ROCMLIR_PREFIX "\${CMAKE_CURRENT_LIST_DIR}/../../../" ABSOLUTE)

		if(NOT TARGET rocMLIR::rockCompiler)
		    add_library(rocMLIR::rockCompiler SHARED IMPORTED)
		    set_target_properties(rocMLIR::rockCompiler PROPERTIES
		        IMPORTED_LOCATION "\${_ROCMLIR_PREFIX}/${libdir}/libMLIRRockThin.so"
		        IMPORTED_SONAME "libMLIRRockThin.so"
		        INTERFACE_INCLUDE_DIRECTORIES "\${_ROCMLIR_PREFIX}/include/rocmlir"
		    )
		endif()

		unset(_ROCMLIR_PREFIX)
	_EOF_
	doins "${T}/rocMLIRConfig.cmake"

	cat > "${T}/rocMLIRConfigVersion.cmake" <<-_EOF_ || die
		set(PACKAGE_VERSION "${PV}")
		if("\${PACKAGE_FIND_VERSION}" VERSION_GREATER "${PV}")
		    set(PACKAGE_VERSION_COMPATIBLE FALSE)
		else()
		    set(PACKAGE_VERSION_COMPATIBLE TRUE)
		    if("\${PACKAGE_FIND_VERSION}" VERSION_EQUAL "${PV}")
		        set(PACKAGE_VERSION_EXACT TRUE)
		    endif()
		endif()
	_EOF_
	doins "${T}/rocMLIRConfigVersion.cmake"
}

src_test() {
	cmake_src_test
}
