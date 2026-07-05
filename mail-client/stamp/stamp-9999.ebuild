# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3 gnome2-utils meson xdg

DESCRIPTION="GNOME mail client"
HOMEPAGE="https://gitlab.gnome.org/jbrummer/stamp"
EGIT_REPO_URI="https://gitlab.gnome.org/jbrummer/stamp.git"

LICENSE="GPL-3+"
SLOT="0"

DEPEND="
	>=gui-libs/gtk-4:4
	>=gui-libs/libadwaita-1.4:1
	dev-libs/glib:2
	gnome-extra/evolution-data-server
	media-libs/gstreamer:1.0
	net-libs/libsoup:3.0
	>=dev-libs/libportal-0.6[gtk]
	net-libs/libpsl
	dev-libs/nss
	>=net-libs/webkit-gtk-2.40:6
"
RDEPEND="${DEPEND}
	gnome-base/gsettings-desktop-schemas
"
BDEPEND="
	dev-util/blueprint-compiler
	>=sys-devel/gettext-0.19.8
	virtual/pkgconfig
"

src_configure() {
	local emesonargs=()
	meson_src_configure
}

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_schemas_update
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_schemas_update
}
