# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_NPM_NAME="language-server"

DESCRIPTION="LSP wrapper for TypeScript extension of VSCode"
HOMEPAGE="https://github.com/yioneko/vtsls"
SRC_URI="
	mirror://npm/@vtsls/${MY_NPM_NAME}/-/${MY_NPM_NAME}-${PV}.tgz -> ${P}.tgz
	https://github.com/bennypowers/gentoo-overlay/releases/download/${P}/${P}-deps.tar.xz
"
S="${WORKDIR}"

# NOTE: to generate the dependency tarball:
#       npm --cache ./npm-cache install $(portageq envvar DISTDIR)/${P}.tgz
#       tar -caf ${P}-deps.tar.xz npm-cache

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

	cd "${ED}"/usr/$(get_libdir)/node_modules/@vtsls/${MY_NPM_NAME} || die "cd failed"
	einstalldocs
}
