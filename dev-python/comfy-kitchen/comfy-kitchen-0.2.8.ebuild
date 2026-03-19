# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )
DISTUTILS_USE_PEP517=setuptools
DISTUTILS_EXT=1

inherit distutils-r1

DESCRIPTION="Fast Kernel Library for ComfyUI with multiple compute backends"
HOMEPAGE="https://github.com/Comfy-Org/comfy-kitchen"
SRC_URI="https://github.com/Comfy-Org/comfy-kitchen/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="cuda"

BDEPEND="
	cuda? (
		>=dev-build/cmake-3.18
		>=dev-python/nanobind-2.0.0[${PYTHON_USEDEP}]
		dev-util/nvidia-cuda-toolkit
	)
"

RDEPEND="
	sci-ml/pytorch
"

DEPEND="${RDEPEND}"

python_configure() {
	if ! use cuda; then
		DISTUTILS_ARGS=( --no-cuda )
	fi
}
