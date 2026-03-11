# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_UPSTREAM_PEP517=standalone
DISTUTILS_EXT=1
PYTHON_COMPAT=( python3_{11..13} )

inherit distutils-r1 pypi

DESCRIPTION="Open Neural Network Exchange format"
HOMEPAGE="https://github.com/onnx/onnx"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="
	dev-build/cmake
	dev-build/ninja
	dev-libs/protobuf
	dev-python/nanobind[${PYTHON_USEDEP}]
	>=dev-python/protobuf-4.25.1[${PYTHON_USEDEP}]
"

RDEPEND="
	>=dev-python/numpy-1.23.2[${PYTHON_USEDEP}]
	>=dev-python/protobuf-4.25.1[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-4.7.1[${PYTHON_USEDEP}]
	>=dev-python/ml-dtypes-0.5.0[${PYTHON_USEDEP}]
"

python_configure() {
	export ONNX_ML=1
	export ONNX_BUILD_TESTS=0
	export USE_NINJA=1
	local nanobind_dir="$(python_get_sitedir)/nanobind/cmake"
	export CMAKE_ARGS="-DONNX_USE_PROTOBUF_SHARED_LIBS=ON -DFETCHCONTENT_FULLY_DISCONNECTED=ON -Dnanobind_DIR=${nanobind_dir}"
}
