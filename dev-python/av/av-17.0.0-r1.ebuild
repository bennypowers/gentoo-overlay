# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..13} )

inherit distutils-r1

DESCRIPTION="Pythonic bindings for FFmpeg's libraries"
HOMEPAGE="https://github.com/PyAV-Org/PyAV"
SRC_URI="https://github.com/PyAV-Org/PyAV/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/PyAV-${PV}"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="media-video/ffmpeg:="
RDEPEND="${DEPEND}"
BDEPEND=">=dev-python/cython-3.2[${PYTHON_USEDEP}]"
