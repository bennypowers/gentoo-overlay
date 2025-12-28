# Copyright 2025 Benny Powers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Linux CLI tool to understand why a process is running"
HOMEPAGE="https://github.com/pranshuparmar/witr"
SRC_URI="https://github.com/pranshuparmar/witr/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

DEPEND=">=dev-lang/go-1.25"
RDEPEND=""

src_compile() {
	ego build -o witr ./cmd/witr
}

src_install() {
	dobin witr
	doman docs/witr.1
	dodoc README.md CONTRIBUTING.md
}
