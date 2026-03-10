# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..13} )
PYPI_PN="comfyui_frontend_package"

inherit distutils-r1 pypi

DESCRIPTION="ComfyUI frontend static assets"
HOMEPAGE="https://github.com/Comfy-Org/ComfyUI_frontend"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

export COMFYUI_FRONTEND_VERSION="${PV}"
