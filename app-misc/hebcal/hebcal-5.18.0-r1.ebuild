# Copyright 2025 Benny Powers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Perpetual Jewish Calendar"
HOMEPAGE="https://github.com/hebcal/hebcal"
SRC_URI="https://github.com/hebcal/hebcal/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/bennypowers/gentoo-overlay/releases/download/${PN}/${P}-deps.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=">=dev-lang/go-1.13"

src_prepare() {
	default
	# Upstream ships a vendor tree built with an older Go (no "## explicit"
	# markers); replace it wholesale with the one from our deps tarball,
	# whose top-level ${P}/ prefix would otherwise nest it inside ${S}.
	rm -rf vendor || die
	tar xaf "${DISTDIR}/${P}-deps.tar.xz" -C "${S}" --strip-components=1 || die
}

src_compile() {
	export GOFLAGS="-mod=vendor"
	emake all
}

src_install() {
	dobin hebcal
	doman hebcal.1
	dodoc README.md
}
