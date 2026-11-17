# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson xdg

DESCRIPTION="A GTK frontend for GNOME Online Accounts"
HOMEPAGE="https://github.com/xapp-project/gnome-online-accounts-gtk"
SRC_URI="https://github.com/xapp-project/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	>=dev-libs/glib-2.44:2
	gui-libs/gtk:4
	>=gui-libs/libadwaita-1:1
	>=net-libs/gnome-online-accounts-3.50
"
DEPEND="${RDEPEND}"
BDEPEND="
	sys-devel/gettext
	virtual/pkgconfig
"
