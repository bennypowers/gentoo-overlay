# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )
DISTUTILS_USE_PEP517=poetry

inherit distutils-r1 pypi

DESCRIPTION="Pythonic generic implementation of the Language Server Protocol"
HOMEPAGE="https://github.com/openlawlibrary/pygls https://pypi.org/project/pygls/"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="websockets"

RDEPEND="
	>=dev-python/attrs-24.3.0[${PYTHON_USEDEP}]
	>=dev-python/cattrs-23.1.2[${PYTHON_USEDEP}]
	dev-python/lsprotocol[${PYTHON_USEDEP}]
	websockets? ( >=dev-python/websockets-13.0[${PYTHON_USEDEP}] )
"
DEPEND="${RDEPEND}"

distutils_enable_tests pytest
