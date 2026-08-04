# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES=""

inherit cargo desktop xdg

DESCRIPTION="Clean, fast, GNOME-native email client"
HOMEPAGE="https://github.com/hyprlab/vireo"
SRC_URI="
	https://github.com/hyprlab/vireo/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/bennypowers/gentoo-overlay/releases/download/vireo/${P}-crates.tar.xz
"

LICENSE="
	AGPL-3+
	0BSD Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD
	CDLA-Permissive-2.0 ISC MIT MPL-2.0 Unicode-3.0 ZLIB
"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	dev-db/sqlite:3
	dev-libs/openssl:=
	>=gui-libs/gtk-4.10.0:4
	>=gui-libs/libadwaita-1.4.0:1
	net-libs/libsoup:3.0
	net-libs/webkit-gtk:6
	sys-apps/dbus
"
RDEPEND="
	${DEPEND}
	virtual/secret-service
"
BDEPEND="
	dev-libs/glib:2
	virtual/pkgconfig
"

src_prepare() {
	default
	# Use system sqlite instead of bundled
	sed -i 's/features = \["bundled"\]/features = []/' Cargo.toml || die
}

src_install() {
	cargo_src_install

	insinto /usr/share
	doins -r data/icons

	domenu data/co.hyprlab.Vireo.desktop

	insinto /usr/share/metainfo
	doins data/co.hyprlab.Vireo.metainfo.xml
}
