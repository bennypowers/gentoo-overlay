# Copyright 2025 Benny Powers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Prometheus exporter for systemd unit metrics"
HOMEPAGE="https://github.com/prometheus-community/systemd_exporter"
SRC_URI="https://github.com/prometheus-community/systemd_exporter/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/bennypowers/gentoo-overlay/releases/download/${PN}/${P}-deps.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

DEPEND=">=dev-lang/go-1.23"
RDEPEND=""

src_compile() {
	export GOFLAGS="-mod=vendor"
	export CGO_ENABLED=0
	ego build -o ${PN} .
}

src_install() {
	dobin ${PN}
	dodoc CHANGELOG.md CODE_OF_CONDUCT.md README.md SECURITY.md
}
