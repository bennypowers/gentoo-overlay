# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..14} )

inherit python-single-r1

DESCRIPTION="Joystick-aware screen waker"
HOMEPAGE="https://codeberg.org/forestix/joystickwake"
SRC_URI="https://codeberg.org/forestix/joystickwake/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="dbus"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

S="${WORKDIR}/joystickwake"

RDEPEND="
	${PYTHON_DEPS}
	dev-python/pyudev
	dbus? ( dev-python/dbus-fast )
"

src_install() {
	dobin joystickwake
	insinto /etc/xdg/autostart
	doins joystickwake.desktop
}
