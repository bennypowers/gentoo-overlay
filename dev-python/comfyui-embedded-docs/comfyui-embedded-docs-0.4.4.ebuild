# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..13} )
PYPI_PN="${PN//-/_}"

inherit distutils-r1 pypi

DESCRIPTION="Embedded documentation for ComfyUI nodes"
HOMEPAGE="https://github.com/Comfy-Org/ComfyUI"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
