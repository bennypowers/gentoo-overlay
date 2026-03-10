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
	~dev-python/comfyui-workflow-templates-core-0.3.158[${PYTHON_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-api-0.3.58[${PYTHON_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-video-0.3.56[${PYTHON_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-image-0.3.97[${PYTHON_USEDEP}]
	~dev-python/comfyui-workflow-templates-media-other-0.3.130[${PYTHON_USEDEP}]
"
