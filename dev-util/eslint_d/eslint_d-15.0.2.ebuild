# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Makes eslint the fastest linter on the planet"
HOMEPAGE="https://github.com/mantoni/eslint_d.js"
SRC_URI="
	mirror://npm/${PN}/-/${PN}-${PV}.tgz -> ${P}.tgz
	https://github.com/bennypowers/gentoo-overlay/releases/download/${P}/${P}-deps.tar.xz
"
S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND=">=net-libs/nodejs-18"
BDEPEND=">=net-libs/nodejs-18[npm]"

src_unpack() {
	cd "${T}" || die "Could not cd to temporary directory"
	unpack ${P}-deps.tar.xz
}

src_install() {
	npm \
		--offline \
		--verbose \
		--progress false \
		--foreground-scripts \
		--global \
		--prefix "${ED}"/usr \
		--cache "${T}"/npm-cache \
		install "${DISTDIR}"/${P}.tgz || die "npm install failed"

	cd "${ED}"/usr/$(get_libdir)/node_modules/${PN} || die "cd failed"
	einstalldocs
}
