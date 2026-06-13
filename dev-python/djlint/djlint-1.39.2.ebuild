# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="HTML template linter and formatter"
HOMEPAGE="
	https://djlint.com
	https://pypi.org/project/djlint/
"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/click-8.0.1[${PYTHON_USEDEP}]
	>=dev-python/colorama-0.4.4[${PYTHON_USEDEP}]
	>=dev-python/cssbeautifier-1.14.4[${PYTHON_USEDEP}]
	>=dev-python/jsbeautifier-1.14.4[${PYTHON_USEDEP}]
	>=dev-python/json5-0.9.11[${PYTHON_USEDEP}]
	>=dev-python/pathspec-0.12[${PYTHON_USEDEP}]
	>=dev-python/pyyaml-6[${PYTHON_USEDEP}]
	>=dev-python/regex-2023[${PYTHON_USEDEP}]
	>=dev-python/tqdm-4.62.2[${PYTHON_USEDEP}]
"

BDEPEND="
	dev-python/hatchling[${PYTHON_USEDEP}]
"
