# Copyright 2025 Benny Powers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

MY_PN="dtls"

DESCRIPTION="LSP server for DTCG design tokens"
HOMEPAGE="https://github.com/bennypowers/design-tokens-language-server"
SRC_URI="https://github.com/bennypowers/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://raw.githubusercontent.com/bennypowers/gentoo-overlay/main/dev-util/${PN}/${P}-deps.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=">=dev-lang/go-1.25"

src_prepare() {
	default
	mv "${WORKDIR}/vendor" "${S}/vendor" || die
	# Remove local replace directive used for development
	sed -i '/^replace /d' go.mod || die
}

src_compile() {
	export GOFLAGS="-mod=vendor"
	export CGO_ENABLED=1
	ego build -o ${PN} ./cmd/${PN}
}

src_install() {
	dobin ${PN}
	dodoc README.md
}
