# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..13} )
DISTUTILS_USE_PEP517=standalone

inherit distutils-r1

DESCRIPTION="The most powerful and modular diffusion model GUI and backend"
HOMEPAGE="https://www.comfy.org/"
SRC_URI="https://github.com/comfyanonymous/ComfyUI/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/ComfyUI-${PV}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="rocm cuda migraphx"

RDEPEND="
	>=dev-python/numpy-1.25.0[${PYTHON_USEDEP}]
	dev-python/einops[${PYTHON_USEDEP}]
	>=dev-python/transformers-4.37.2[${PYTHON_USEDEP}]
	>=dev-python/tokenizers-0.13.3[${PYTHON_USEDEP}]
	dev-python/sentencepiece[${PYTHON_USEDEP}]
	>=dev-python/safetensors-0.4.2[${PYTHON_USEDEP}]
	>=dev-python/aiohttp-3.11.8[${PYTHON_USEDEP}]
	>=dev-python/yarl-1.18.0[${PYTHON_USEDEP}]
	dev-python/pyyaml[${PYTHON_USEDEP}]
	dev-python/pillow[${PYTHON_USEDEP}]
	dev-python/scipy[${PYTHON_USEDEP}]
	dev-python/tqdm[${PYTHON_USEDEP}]
	dev-python/psutil[${PYTHON_USEDEP}]
	dev-python/alembic[${PYTHON_USEDEP}]
	dev-python/sqlalchemy[${PYTHON_USEDEP}]
	>=dev-python/av-14.2.0[${PYTHON_USEDEP}]
	>=dev-python/kornia-0.7.1[${PYTHON_USEDEP}]
	dev-python/spandrel[${PYTHON_USEDEP}]
	dev-python/soundfile[${PYTHON_USEDEP}]
	dev-python/pydantic[${PYTHON_USEDEP}]
	dev-python/pydantic-settings[${PYTHON_USEDEP}]
	sci-ml/pytorch[${PYTHON_USEDEP}]
	rocm? ( sci-ml/pytorch[rocm] )
	cuda? ( sci-ml/pytorch[cuda] )
	migraphx? ( dev-libs/migraphx[python,${PYTHON_USEDEP}] )
"

DEPEND="${RDEPEND}"

python_install() {
	distutils-r1_python_install

	# Install main application files
	python_moduleinto comfyui
	python_domodule *.py
	python_domodule comfy comfy_api comfy_api_nodes comfy_config comfy_execution comfy_extras
	python_domodule api_server app middleware utils alembic_db

	# Install data directories
	insinto "/usr/share/${PN}"
	doins -r models input output user
	doins alembic.ini extra_model_paths.yaml.example

	# Create launcher script
	cat > "${T}"/comfyui <<-EOF
		#!/bin/bash
		exec python -m comfyui.main "\$@"
	EOF
	dobin "${T}"/comfyui
}

pkg_postinst() {
	elog "ComfyUI has been installed."
	elog "Models directory: /usr/share/${PN}/models"
	elog "You can run ComfyUI with: comfyui"
	elog ""
	elog "For ROCm support, ensure you have:"
	elog "  - sci-ml/pytorch[rocm]"
	elog "  - Appropriate ROCm drivers installed"
	elog ""
	if use migraphx; then
		elog "MIGraphX support enabled."
		elog "Install ComfyUI_MIGraphX custom node for acceleration:"
		elog "  https://github.com/pnikolic-amd/ComfyUI_MIGraphX"
	fi
}
