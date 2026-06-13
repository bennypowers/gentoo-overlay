# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DOCS_BUILDER="doxygen"
DOCS_DIR="docs/doxygen"
DOCS_DEPEND="media-gfx/graphviz"
LLVM_COMPAT=( 22 )
ROCM_VERSION=${PV}
PYTHON_COMPAT=( python3_{10..13} )

inherit cmake docs flag-o-matic rocm llvm-r2 python-r1

DESCRIPTION="AMD's graph inference engine"
HOMEPAGE="https://github.com/ROCm/AMDMIGraphX"
SRC_URI="https://github.com/ROCm/AMDMIGraphX/archive/rocm-${PV}.tar.gz -> rocm-${P}.tar.gz"
S="${WORKDIR}/AMDMIGraphX-rocm-${PV}"

LICENSE="BSD"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"
IUSE="python"
REQUIRED_USE="
	${ROCM_REQUIRED_USE}
	python? ( ${PYTHON_REQUIRED_USE} )
"

BDEPEND="
	>=dev-build/rocm-cmake-5.3
"

DEPEND="
	>=dev-cpp/msgpack-cxx-6.0.0
	dev-libs/rocMLIR
	dev-util/hip:${SLOT}
	sci-libs/rocBLAS:${SLOT}
	sci-libs/miopen:${SLOT}
	sci-libs/hipBLAS:${SLOT}
	sci-libs/hipBLASLt:${SLOT}
	dev-libs/half
	dev-cpp/nlohmann_json
	dev-db/sqlite
	dev-libs/protobuf

	python? (
		dev-python/pybind11[${PYTHON_USEDEP}]
	)
"

RDEPEND="
	${DEPEND}
	python? ( ${PYTHON_DEPS} )
"

src_prepare() {
	cmake_src_prepare
	# pybind11 3.x removed the pybind11::lto target
	sed -e 's/ pybind11::lto//' -i cmake/PythonModules.cmake || die
}

src_configure() {
	llvm_prepend_path "${LLVM_SLOT}"
	rocm_use_clang

	# too many warnings
	append-cxxflags -Wno-explicit-specialization-storage-class -Wno-unused-value

	# Hide static LLVM/MLIR symbols from rocMLIR's fat archive so they
	# don't clash with shared libLLVM loaded by pytorch/ROCm at runtime.
	append-ldflags -Wl,--exclude-libs,ALL

	local mycmakeargs=(
		-DCMAKE_SKIP_RPATH=ON
		-DBUILD_FILE_REORG_BACKWARD_COMPATIBILITY=OFF
		-DROCM_SYMLINK_LIBS=OFF
		-DAMDGPU_TARGETS="$(get_amdgpu_flags)"
		-DCMAKE_INSTALL_INCLUDEDIR="include/migraphx"
		-DMIGRAPHX_ENABLE_PYTHON="$(usex python ON OFF)"
		-DBUILD_CLIENTS_SAMPLES=OFF
		-DBUILD_WITH_PIP=OFF
		-DLINK_BLIS=OFF
		# Gentoo's composable-kernel doesn't build the jit_library component
		# https://github.com/ROCm/rocm-libraries/issues/4245
		-DMIGRAPHX_USE_COMPOSABLEKERNEL=OFF
		-Wno-dev
	)

	cmake_src_configure
}

src_compile() {
	docs_compile
	cmake_src_compile
}

src_install() {
	cmake_src_install

	# Register migraphx lib directory with the linker
	echo "/usr/$(get_libdir)/migraphx/lib" > "${T}"/50-migraphx.conf || die
	insinto /etc/ld.so.conf.d
	doins "${T}"/50-migraphx.conf

	# Move Python extension from lib64 to site-packages so it's importable
	if use python; then
		python_foreach_impl _migraphx_install_py
	fi
}

_migraphx_install_py() {
	local pyver="${EPYTHON#python}"
	pyver="${pyver/./}"
	local sitedir="$(python_get_sitedir)"
	dodir "${sitedir}"
	mv "${ED}/usr/$(get_libdir)/migraphx.cpython-${pyver}"*-linux-gnu.so \
		"${ED}${sitedir}/" || die
}
