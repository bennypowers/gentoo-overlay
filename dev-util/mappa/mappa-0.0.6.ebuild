# Copyright 2025 Benny Powers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="High-performance import map generator for the modern web"
HOMEPAGE="https://github.com/bennypowers/mappa"
SRC_URI="https://github.com/bennypowers/mappa/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://raw.githubusercontent.com/bennypowers/gentoo-overlay/main/dev-util/mappa/${P}-deps.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=">=dev-lang/go-1.25"

src_prepare() {
	default
	mv "${WORKDIR}/vendor" "${S}/vendor" || die
}

src_compile() {
	export GOFLAGS="-mod=vendor"
	export CGO_ENABLED=1
	ego build -o mappa .
}

src_install() {
	dobin mappa
	dodoc README.md
}
