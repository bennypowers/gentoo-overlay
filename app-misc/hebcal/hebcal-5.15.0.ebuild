# Copyright 2025 Benny Powers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Perpetual Jewish Calendar"
HOMEPAGE="https://github.com/hebcal/hebcal"
SRC_URI="https://github.com/hebcal/hebcal/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://raw.githubusercontent.com/bennypowers/gentoo-overlay/main/app-misc/hebcal/${P}-deps.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=">=dev-lang/go-1.13"
RDEPEND=""

src_prepare() {
	default
	# Upstream v5.9.7 ships vendored hebcal-go v0.11.0 but the code uses
	# event.UserEvent which was added in v0.11.1; replace with our tarball.
	rm -rf vendor || die
	mv "${WORKDIR}/vendor" "${S}/vendor" || die
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
