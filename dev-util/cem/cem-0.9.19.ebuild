# Copyright 2025 Benny Powers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Custom Elements Manifest multitool"
HOMEPAGE="https://github.com/bennypowers/cem"
SRC_URI="https://github.com/bennypowers/cem/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://raw.githubusercontent.com/bennypowers/gentoo-overlay/main/dev-util/cem/${P}-deps.tar.gz"

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
	export GOEXPERIMENT=jsonv2
	ego build -o cem .
}

src_install() {
	dobin cem
	dodoc README.md
}
