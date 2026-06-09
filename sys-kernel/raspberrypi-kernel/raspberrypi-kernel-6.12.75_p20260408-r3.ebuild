# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit kernel-build

# Pin to the same commit shipped in raspberrypi-firmware 1.20260408.
# Obtained from: extra/git_hash in raspberrypi/firmware tag 1.20260408
COMMIT="89050b1059997d38d55462b323b099a6436dc10d"

DESCRIPTION="Raspberry Pi kernel built from Foundation sources"
HOMEPAGE="https://github.com/raspberrypi/linux"
SRC_URI="
	https://github.com/raspberrypi/linux/archive/${COMMIT}.tar.gz
		-> ${P}.tar.gz
"
S="${WORKDIR}/linux-${COMMIT}"

LICENSE="GPL-2"
KEYWORDS="-* ~arm64"
# RPi5 boots without initramfs; the firmware bootloader loads the kernel directly.
IUSE="-initramfs debug +strip"

RDEPEND="
	sys-boot/raspberrypi-firmware
	sys-firmware/raspberrypi-wifi-firmware
"

src_prepare() {
	default

	# RPi5 defconfig (includes ARM64_16K_PAGES=y)
	cp arch/arm64/configs/bcm2712_defconfig .config || die

	# LOCALVERSION must start with the suffix that dist-kernel_PV_to_KV
	# produces from PV. For 6.12.75_p20260408 that is 6.12.75-p20260408.
	local myversion="-p$(ver_cut 5)-raspberrypi"
	echo "CONFIG_LOCALVERSION=\"${myversion}\"" > "${T}"/version.config || die

	kernel-build_merge_configs "${T}"/version.config
}

src_install() {
	kernel-build_src_install

	# RPi firmware loads an uncompressed Image, not Image.gz.
	insinto /boot
	newins "${WORKDIR}/build/arch/arm64/boot/Image" kernel_2712.img

	# DTBs -- RPi firmware expects these in /boot/, not /lib/modules/*/dtb/
	local dtb_src="${WORKDIR}/build/arch/arm64/boot/dts/broadcom"
	if [[ -d "${dtb_src}" ]]; then
		doins "${dtb_src}"/*.dtb
	fi

	# DT overlays
	local overlay_src="${WORKDIR}/build/arch/arm64/boot/dts/overlays"
	if [[ -d "${overlay_src}" ]]; then
		insinto /boot/overlays
		doins "${overlay_src}"/*.dtb*
		[[ -f "${overlay_src}/README" ]] && doins "${overlay_src}/README"
	fi
}

pkg_pretend() {
	if use initramfs; then
		ewarn "RPi5 boots without an initramfs. The firmware bootloader loads"
		ewarn "the kernel image directly from /boot/kernel_2712.img."
		ewarn "USE=initramfs will pull in dracut/ugrd unnecessarily unless"
		ewarn "you have a specific need (e.g. encrypted root)."
	fi
	kernel-install_pkg_pretend
}

pkg_postinst() {
	kernel-build_pkg_postinst
	einfo "RPi firmware will load /boot/kernel_2712.img"
	einfo "DTBs and overlays installed to /boot/"
}
