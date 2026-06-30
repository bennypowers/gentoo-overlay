# Copyright 2026 Benny Powers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )
PYPI_PN="comfyui_workflow_templates_media_assets_01"

inherit distutils-r1 pypi

DESCRIPTION="Media assets bundle 01 for ComfyUI workflow templates"
HOMEPAGE="https://github.com/Comfy-Org/ComfyUI"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
