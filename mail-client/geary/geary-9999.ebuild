# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3 gnome2-utils meson vala virtualx xdg

DESCRIPTION="A lightweight, easy-to-use, feature-rich email client (GTK4 port)"
HOMEPAGE="https://gitlab.gnome.org/GNOME/geary"

EGIT_REPO_URI="https://gitlab.gnome.org/onny/geary.git"
EGIT_BRANCH="gtk4-port"

LICENSE="LGPL-2.1+ CC-BY-3.0 CC-BY-SA-3.0"
SLOT="0"
IUSE="test ytnef"
RESTRICT="!test? ( test )"

# GTK4 port dependencies
# Key changes from upstream 46.0:
#   gtk+:3 → gtk:4, webkit-gtk:4.1 → webkit-gtk:6, gcr:0 → gcr:4
#   libhandy:1 → libadwaita:1, gspell → libspelling, libpeas:0 → libpeas:2
DEPEND="
	>=dev-libs/glib-2.80:2
	>=gui-libs/gtk-4.16:4
	>=net-libs/webkit-gtk-2.40:6=
	>=dev-libs/gmime-3.2.4:3.0
	>=dev-db/sqlite-3.24:3

	x11-libs/cairo
	>=app-text/enchant-2.1:2
	>=dev-libs/folks-0.11:0=
	>=app-crypt/gcr-4.3:4=
	>=dev-libs/libgee-0.8.5:0.8=
	net-libs/gnome-online-accounts
	media-libs/gsound
	>=app-text/libspelling-0.4:1
	>=dev-libs/icu-60:=
	app-text/iso-codes
	>=dev-libs/json-glib-1.0
	>=gui-libs/libadwaita-1.7:1=
	>=dev-libs/libpeas-2.0:2
	>=app-crypt/libsecret-0.11
	net-libs/libsoup:3.0
	dev-libs/snowball-stemmer:=
	>=dev-libs/libxml2-2.7.8:2=
	ytnef? ( >=net-mail/ytnef-1.9.3 )
"
RDEPEND="${DEPEND}
	gnome-base/gsettings-desktop-schemas
"
BDEPEND="
	>=dev-libs/libxml2-2.7.8
	dev-util/itstool
	>=sys-devel/gettext-0.19.8
	virtual/pkgconfig
	test? ( net-libs/gnutls[tools] )

	$(vala_depend)
	gui-libs/gtk:4[introspection]
	net-libs/webkit-gtk:6[introspection]
	dev-libs/gmime:3.0[vala]
	app-crypt/gcr:4[introspection,vala]
	dev-libs/libgee:0.8[introspection]
	media-libs/gsound[vala]
	app-text/libspelling[vala]
	gui-libs/libadwaita:1[introspection,vala]
	app-crypt/libsecret[introspection,vala]
	net-libs/libsoup:3.0[introspection,vala]
"

src_prepare() {
	vala_setup
	gnome2_environment_reset
	default
}

src_configure() {
	local emesonargs=(
		-Dprofile=release
		-Drevno="${PR}"
		-Dvaladoc=disabled
		-Dcontractor=disabled
		-Dlibunwind=disabled
		$(meson_feature ytnef tnef)
	)

	meson_src_configure
}

src_test() {
	virtx meson_src_test
}

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_schemas_update
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_schemas_update
}
