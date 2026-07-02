# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..14} )
DISTUTILS_USE_PEP517=hatchling

inherit distutils-r1 pypi

DESCRIPTION="Simple text to phones converter for multiple languages"
HOMEPAGE="https://github.com/bootphon/phonemizer"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	app-accessibility/espeak-ng
	dev-python/attrs[${PYTHON_USEDEP}]
	dev-python/dlinfo[${PYTHON_USEDEP}]
	dev-python/joblib[${PYTHON_USEDEP}]
	dev-python/typing-extensions[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"

PATCHES=(
	"${FILESDIR}/${P}-optional-segments.patch"
)

src_prepare() {
	distutils-r1_src_prepare

	# Remove segments from hard dependencies; only espeak backend needed
	sed -i '/"segments",/d' pyproject.toml || die
}
