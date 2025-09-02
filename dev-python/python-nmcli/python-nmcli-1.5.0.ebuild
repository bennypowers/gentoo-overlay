# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} )

inherit distutils-r1 pypi

MY_PN="nmcli"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="A python wrapper library for NetworkManager's nmcli command-line tool"
HOMEPAGE="https://pypi.org/project/nmcli/"
SRC_URI="https://files.pythonhosted.org/packages/source/${MY_PN::1}/${MY_PN}/${MY_P}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/${MY_P}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	net-misc/networkmanager
"

BDEPEND="
	dev-python/setuptools[${PYTHON_USEDEP}]
"