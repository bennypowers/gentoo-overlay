# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..13} )
PYPI_PN="${PN//-/_}"

inherit distutils-r1 pypi

DESCRIPTION="ComfyUI workflow templates"
HOMEPAGE="https://github.com/Comfy-Org/ComfyUI"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	~dev-python/comfyui-workflow-templates-core-0.3.193[${PYTHON_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-api-0.3.68[${PYTHON_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-video-0.3.72[${PYTHON_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-image-0.3.117[${PYTHON_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-other-0.3.165[${PYTHON_USEDEP}]
"
