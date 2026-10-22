# Copyright 2026 Benny Powers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )
PYPI_PN="${PN//-/_}"

inherit distutils-r1 pypi

DESCRIPTION="Workflow template JSON definitions for ComfyUI"
HOMEPAGE="https://github.com/Comfy-Org/ComfyUI"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
