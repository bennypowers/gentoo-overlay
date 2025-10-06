# Copyright 2025 Benny Powers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Perpetual Jewish Calendar"
HOMEPAGE="https://github.com/hebcal/hebcal"
SRC_URI="https://github.com/hebcal/hebcal/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2.0"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=">=dev-lang/go-1.13"
RDEPEND=""

src_compile() {
	ego build -o hebcal
}

src_install() {
	dobin hebcal
	doman hebcal.1
	dodoc README.md
}
