# Copyright 2025 Benny Powers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="MCP server exposing man pages, info pages, and eclass docs to LLM agents"
HOMEPAGE="https://bennypowers.dev/mansplain"
SRC_URI="https://github.com/bennypowers/mansplain/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://raw.githubusercontent.com/bennypowers/gentoo-overlay/main/app-misc/mansplain/${P}-deps.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=">=dev-lang/go-1.25"
RDEPEND="
	sys-apps/man-db
	sys-apps/texinfo
"

src_prepare() {
	default
	mv "${WORKDIR}/vendor" "${S}/vendor" || die
}

src_compile() {
	export GOFLAGS="-mod=vendor"
	export CGO_ENABLED=0
	ego build -o mansplain .
}

src_test() {
	export GOFLAGS="-mod=vendor"
	ego test ./... -count=1
}

src_install() {
	dobin mansplain
	dodoc README.md
}
