# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )
DISTUTILS_USE_PEP517=hatchling

inherit distutils-r1 pypi

DESCRIPTION="Developer tools for working with Language Server Protocol (LSP) servers and clients"
HOMEPAGE="https://github.com/swyddfa/lsp-devtools"
SRC_URI="https://files.pythonhosted.org/packages/source/l/lsp-devtools/lsp_devtools-${PV}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/lsp_devtools-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/aiosqlite[${PYTHON_USEDEP}]
	dev-python/platformdirs[${PYTHON_USEDEP}]
	>=dev-python/pygls-2.0[${PYTHON_USEDEP}]
	dev-python/stamina[${PYTHON_USEDEP}]
	>=dev-python/textual-6.3.0[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"

distutils_enable_tests pytest
