# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=standalone
PYTHON_COMPAT=( python3_{11..13} )

inherit distutils-r1 pypi

DESCRIPTION="Yield-based recursion for Python"
HOMEPAGE="https://gitlab.com/ferreum/trampoline"
SRC_URI="$(pypi_wheel_url)"
S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

python_compile() {
	distutils_wheel_install "${BUILD_DIR}/install" \
		"${DISTDIR}/$(pypi_wheel_name)"
}
