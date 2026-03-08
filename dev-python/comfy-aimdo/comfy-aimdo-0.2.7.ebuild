# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1 toolchain-funcs

DESCRIPTION="AI Model Dynamic Offloader for ComfyUI"
HOMEPAGE="https://github.com/Comfy-Org/comfy-aimdo"
SRC_URI="https://github.com/Comfy-Org/comfy-aimdo/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="
	dev-util/nvidia-cuda-toolkit
"

RDEPEND="
	x11-drivers/nvidia-drivers
"

DEPEND="${RDEPEND}"

export SETUPTOOLS_SCM_PRETEND_VERSION="${PV}"

src_compile() {
	# Build the native C shared library
	local cuda_include="${EPREFIX}/opt/cuda/include"
	local cuda_stubs="${EPREFIX}/opt/cuda/lib64/stubs"

	$(tc-getCC) -shared -o comfy_aimdo/aimdo.so -fPIC \
		-I"${cuda_include}" \
		-L"${cuda_stubs}" \
		src/*.c -lcuda || die "Failed to compile aimdo.so"

	distutils-r1_src_compile
}
