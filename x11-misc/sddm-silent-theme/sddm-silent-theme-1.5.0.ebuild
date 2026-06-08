# Copyright 2025 Benny Powers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Customizable SDDM theme with multiple presets"
HOMEPAGE="https://github.com/uiriansan/SilentSDDM"
SRC_URI="https://github.com/uiriansan/SilentSDDM/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=x11-misc/sddm-0.21.0
	dev-qt/qtsvg:6
	dev-qt/qtvirtualkeyboard:6
	dev-qt/qtmultimedia:6
"

S="${WORKDIR}/SilentSDDM-${PV}"

src_install() {
	insinto /usr/share/sddm/themes/silent
	doins -r backgrounds components configs docs fonts icons
	doins Main.qml metadata.desktop qmldir

	# Install helper scripts
	exeinto /usr/share/sddm/themes/silent
	doexe change_avatar.sh test.sh
}

pkg_postinst() {
	elog "To activate this theme, add the following to /etc/sddm.conf:"
	elog ""
	elog "[General]"
	elog "InputMethod=qtvirtualkeyboard"
	elog "GreeterEnvironment=QML2_IMPORT_PATH=/usr/share/sddm/themes/silent/components/,QT_IM_MODULE=qtvirtualkeyboard"
	elog ""
	elog "[Theme]"
	elog "Current=silent"
	elog ""
	elog "Test the theme before rebooting with: /usr/share/sddm/themes/silent/test.sh"
	elog "See https://github.com/uiriansan/SilentSDDM/wiki/Customizing for configuration options."
}
