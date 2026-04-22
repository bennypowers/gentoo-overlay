# Copyright 2026 Benny Powers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit udev

DESCRIPTION="Firmware updater for Dell U4025QW monitor (M3T105)"
HOMEPAGE="https://www.dell.com/support/home/en-us/product-support/product/dell-u4025qw-monitor/drivers"

MY_FW_VER="M3T${PV}"
MY_PN="Dell_U4025QW_FWUpdate_${MY_FW_VER}_Ubuntu"
SRC_URI="${MY_PN}.deb"

LICENSE="Dell-EULA Boost-1.0"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="fetch bindist mirror strip"

RDEPEND="
	dev-libs/libusb:1
	virtual/udev
"

QA_PREBUILT="
	opt/dell/firmware/U4025QW/*
"

S="${WORKDIR}"

pkg_nofetch() {
	elog "Download the firmware updater .deb from Dell:"
	elog "  https://www.dell.com/support/home/en-us/drivers/driversdetails?driverid=nvpvj"
	elog ""
	elog "Place the file in your DISTDIR:"
	elog "  cp ${MY_PN}.deb \${DISTDIR}/"
}

src_unpack() {
	local deb="${DISTDIR}/${MY_PN}.deb"
	mkdir -p "${S}" || die
	cd "${S}" || die
	ar x "${deb}" || die "Failed to extract .deb"
	unpack ./data.tar.*
}

src_install() {
	local destdir="/opt/dell/firmware/U4025QW"

	insinto "${destdir}"
	doins usr/share/Dell/firmware/U4025QW/appconfig.dat
	doins usr/share/Dell/firmware/U4025QW/cert.dat
	doins usr/share/Dell/firmware/U4025QW/cert2.dat
	doins usr/share/Dell/firmware/U4025QW/"Firmware Updater.cfg"

	exeinto "${destdir}"
	doexe usr/share/Dell/firmware/U4025QW/"Firmware Updater"
	doexe usr/share/Dell/firmware/U4025QW/libhidapi-libusb-0.15.0.so
	doexe usr/share/Dell/firmware/U4025QW/librtburn.so
	doexe usr/share/Dell/firmware/U4025QW/libsciter.so

	insinto "${destdir}/plugins"
	doins usr/share/Dell/firmware/U4025QW/plugins/*.so

	insinto "${destdir}/${MY_FW_VER}"
	doins usr/share/Dell/firmware/U4025QW/${MY_FW_VER}/*.upg

	udev_dorules etc/udev/rules.d/99-monitorfirmwareupdateutility-U4025QW.rules

	newbin - dell-u4025qw-fwupdate <<-EOF
		#!/bin/sh
		cd "${destdir}" || exit 1
		LD_LIBRARY_PATH="${destdir}" exec "${destdir}/Firmware Updater" "\$@"
	EOF
}

pkg_postinst() {
	udev_reload

	elog "To update your Dell U4025QW firmware to ${MY_FW_VER}:"
	elog "  1. Connect the monitor via USB upstream cable"
	elog "  2. Run: dell-u4025qw-fwupdate"
	elog "  3. Follow the on-screen instructions (~20 minutes)"
	elog ""
	elog "Do not disconnect the monitor during the update."
	elog "If the screen goes black after updating, unplug"
	elog "the monitor power cable for 5 seconds."
}
