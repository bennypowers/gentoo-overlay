# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11,12,13} )

inherit cmake flag-o-matic python-single-r1

DESCRIPTION="Deep learning model optimization and deployment toolkit"
HOMEPAGE="https://docs.openvino.ai/"

_COMMIT="8a17657b995fd3b4a52f8484acfcf2bb61214623"
_ONEDNN_CPU="f82d833de6f13fac4bb1926d521ca8fec4f4ae01"
_ONEDNN_GPU="babb7375ff500dd8ad77d26cbd2b044122b7a8b4"
_XBYAK="0d67fd1530016b7c56f3cd74b3fca920f4c3e2b4"
_MLAS="d1bc25ec4660cddd87804fcf03b2411b5dfb2e94"
_ITTAPI="ca45fef1a12cef3316e6ff362a4d36571270e392"
_JSON="9cca280a4d0ccf0c08f47a99aa71d1b0e52f8d03"
_ONNX="e709452ef2bbc1d113faf678c24e6d3467696e83"
_PROTOBUF="f0dc78d7e6e331b8c6bb2d5283e06aa26883ca7c"
_PYBIND11="45fab4087eaaff234227a10cf7845e8b07f28a98"
_GFLAGS="e171aa2d15ed9eb17054558e0b3a6a413bb01067"
_TELEMETRY="8abddc3dbc8beb04a39b5ea40cbba5020317102f"
_CL_HEADERS="4ea6df132107e3b4b9407f903204b5522fdffcd6"
_CLHPP="c7b4aded1cab9560b226041dd962f63375a9a384"
_ZLIB="51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf"

SRC_URI="
	https://github.com/openvinotoolkit/openvino/archive/${_COMMIT}.tar.gz
		-> ${P}.tar.gz
	https://github.com/openvinotoolkit/oneDNN/archive/${_ONEDNN_CPU}.tar.gz
		-> ${P}-onednn-cpu.tar.gz
	https://github.com/herumi/xbyak/archive/${_XBYAK}.tar.gz
		-> ${P}-xbyak.tar.gz
	https://github.com/openvinotoolkit/mlas/archive/${_MLAS}.tar.gz
		-> ${P}-mlas.tar.gz
	https://github.com/intel/ittapi/archive/${_ITTAPI}.tar.gz
		-> ${P}-ittapi.tar.gz
	https://github.com/nlohmann/json/archive/${_JSON}.tar.gz
		-> ${P}-nlohmann-json.tar.gz
	https://github.com/onnx/onnx/archive/${_ONNX}.tar.gz
		-> ${P}-onnx.tar.gz
	https://github.com/protocolbuffers/protobuf/archive/${_PROTOBUF}.tar.gz
		-> ${P}-protobuf.tar.gz
	https://github.com/gflags/gflags/archive/${_GFLAGS}.tar.gz
		-> ${P}-gflags.tar.gz
	https://github.com/openvinotoolkit/telemetry/archive/${_TELEMETRY}.tar.gz
		-> ${P}-telemetry.tar.gz
	https://github.com/madler/zlib/archive/${_ZLIB}.tar.gz
		-> ${P}-zlib.tar.gz
	gpu? (
		https://github.com/oneapi-src/oneDNN/archive/${_ONEDNN_GPU}.tar.gz
			-> ${P}-onednn-gpu.tar.gz
		https://github.com/KhronosGroup/OpenCL-Headers/archive/${_CL_HEADERS}.tar.gz
			-> ${P}-opencl-headers.tar.gz
		https://github.com/KhronosGroup/OpenCL-CLHPP/archive/${_CLHPP}.tar.gz
			-> ${P}-opencl-clhpp.tar.gz
	)
	python? (
		https://github.com/pybind/pybind11/archive/${_PYBIND11}.tar.gz
			-> ${P}-pybind11.tar.gz
	)
"

S="${WORKDIR}/openvino-${_COMMIT}"

PATCHES=(
	"${FILESDIR}/${P}-install-paths.patch"
)

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

IUSE="gpu python test"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

RDEPEND="
	app-arch/snappy
	dev-cpp/tbb:=
	dev-libs/pugixml
	gpu? (
		virtual/opencl
	)
	python? (
		${PYTHON_DEPS}
	)
"

DEPEND="
	${RDEPEND}
	dev-libs/flatbuffers
	gpu? (
		dev-libs/opencl-headers
	)
"

BDEPEND="
	>=dev-build/cmake-3.26
	python? (
		$(python_gen_cond_dep '
			dev-python/setuptools[${PYTHON_USEDEP}]
			dev-python/wheel[${PYTHON_USEDEP}]
		')
	)
"

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_prepare() {
	# System ONNX's cmake config has transitive absl deps that require
	# find_package(absl) — which OpenVINO's cmake never calls. Force bundled.
	sed -i \
		's/find_package(ONNX 1.16.2 QUIET COMPONENTS onnx onnx_proto NO_MODULE)/set(ONNX_FOUND FALSE)/' \
		thirdparty/dependencies.cmake || die
	cmake_src_prepare
}

_unpack_submodule() {
	local tarball="${1}" dest="${S}/${2}"
	mkdir -p "${dest}" || die
	tar -xf "${DISTDIR}/${tarball}" --strip-components=1 -C "${dest}" || die
}

src_unpack() {
	unpack "${P}.tar.gz"

	_unpack_submodule "${P}-onednn-cpu.tar.gz" "src/plugins/intel_cpu/thirdparty/onednn"
	_unpack_submodule "${P}-xbyak.tar.gz" "thirdparty/xbyak"
	_unpack_submodule "${P}-mlas.tar.gz" "src/plugins/intel_cpu/thirdparty/mlas"
	_unpack_submodule "${P}-ittapi.tar.gz" "thirdparty/ittapi/ittapi"
	_unpack_submodule "${P}-nlohmann-json.tar.gz" "thirdparty/json/nlohmann_json"
	_unpack_submodule "${P}-onnx.tar.gz" "thirdparty/onnx/onnx"
	_unpack_submodule "${P}-protobuf.tar.gz" "thirdparty/protobuf/protobuf"
	_unpack_submodule "${P}-gflags.tar.gz" "thirdparty/gflags/gflags"
	_unpack_submodule "${P}-telemetry.tar.gz" "thirdparty/telemetry"
	_unpack_submodule "${P}-zlib.tar.gz" "thirdparty/zlib/zlib"

	if use gpu; then
		_unpack_submodule "${P}-onednn-gpu.tar.gz" "src/plugins/intel_gpu/thirdparty/onednn_gpu"
		_unpack_submodule "${P}-opencl-headers.tar.gz" "thirdparty/ocl/cl_headers"
		_unpack_submodule "${P}-opencl-clhpp.tar.gz" "thirdparty/ocl/clhpp_headers"
	fi

	if use python; then
		_unpack_submodule "${P}-pybind11.tar.gz" "src/bindings/python/thirdparty/pybind11"
	fi
}

src_configure() {
	# Upstream cmake forces _FORTIFY_SOURCE=2; strip portage's copy to avoid redefinition
	filter-flags '-Wp,-D_FORTIFY_SOURCE=*' '-D_FORTIFY_SOURCE=*'

	local mycmakeargs=(
		-DBUILD_TESTING=$(usex test ON OFF)
		-DCMAKE_CXX_STANDARD=17
		-DCMAKE_SKIP_RPATH=YES
		-DENABLE_CLANG_FORMAT=OFF
		-DENABLE_CM_FOR_GPU=OFF
		-DENABLE_INTEL_GPU=$(usex gpu ON OFF)
		-DENABLE_INTEL_NPU=OFF
		-DENABLE_NCC_STYLE=OFF
		-DENABLE_ONEDNN_FOR_GPU=$(usex gpu ON OFF)
		-DENABLE_PLUGINS_XML=ON
		-DENABLE_PYTHON=$(usex python ON OFF)
		-DENABLE_SAMPLES=OFF
		-DENABLE_SNIPPETS_LIBXSMM_TPP=OFF
		-DENABLE_SYSTEM_FLATBUFFERS=ON
		-DENABLE_SYSTEM_OPENCL=$(usex gpu ON OFF)
		-DENABLE_SYSTEM_PROTOBUF=OFF
		-DENABLE_SYSTEM_PUGIXML=ON
		-DENABLE_SYSTEM_SNAPPY=ON
		-DENABLE_SYSTEM_TBB=ON
		-DENABLE_TBBBIND_2_5=OFF
		-DENABLE_TESTS=$(usex test ON OFF)
	)

	if use gpu; then
		mycmakeargs+=(
			-DOpenCL_HPP="${S}/thirdparty/ocl/clhpp_headers/include/CL/opencl.hpp"
			-DOpenCL_INCLUDE_DIR="${S}/thirdparty/ocl/cl_headers"
		)
		append-cxxflags "-isystem${S}/thirdparty/ocl/clhpp_headers/include"
	fi

	if use python; then
		mycmakeargs+=(
			-DPYTHON_EXECUTABLE="${PYTHON}"
			-DPython3_EXECUTABLE="${PYTHON}"
		)
	fi

	cmake_src_configure
}

src_install() {
	cmake_src_install

	use python && python_optimize
}
