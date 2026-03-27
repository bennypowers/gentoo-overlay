# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit kernel-build

# Match raspberrypi-sources version scheme: PV is e.g. 6.12.47_p20250916
# The upstream tag is stable_YYYYMMDD
MY_TAG="stable_$(ver_cut 5)"
MY_P="linux-${MY_TAG}"

DESCRIPTION="Raspberry Pi kernel built from Foundation sources"
HOMEPAGE="https://github.com/raspberrypi/linux"
SRC_URI="
	https://github.com/raspberrypi/linux/archive/${MY_TAG}.tar.gz
		-> ${P}.tar.gz
"
S="${WORKDIR}/${MY_P}"

LICENSE="GPL-2"
KEYWORDS="-* ~arm64"
IUSE="+strip"

RDEPEND="
	!sys-kernel/raspberrypi-kernel-bin:${SLOT}
	sys-boot/raspberrypi-firmware
"

src_prepare() {
	default

	# Use the RPi5 defconfig (includes ARM64_16K_PAGES=y)
	cp arch/arm64/configs/bcm2712_defconfig .config || die

	local myversion="-raspberrypi"
	echo "CONFIG_LOCALVERSION=\"${myversion}\"" > "${T}"/version.config || die

	kernel-build_merge_configs "${T}"/version.config
}

src_install() {
	kernel-build_src_install

	# The eclass installs Image.gz for arm64, but RPi firmware needs
	# the uncompressed Image. Install it alongside for pkg_postinst.
	insinto /usr/src/linux-${KV_FULL}/arch/arm64/boot
	doins "${WORKDIR}/build/arch/arm64/boot/Image"
}

pkg_postinst() {
	# Let the eclass handle everything normally (symlinks, modules,
	# installkernel, etc.) -- this is forward-compatible with eclass changes.
	kernel-build_pkg_postinst

	# Then overwrite /boot with what RPi firmware actually needs:
	# uncompressed Image (not the Image.gz that installkernel deployed)
	local kernel_dir="${EROOT}/usr/src/linux-${KV_FULL}"

	cp "${kernel_dir}/arch/arm64/boot/Image" \
		"${EROOT}/boot/kernel_2712.img" || die "Failed to install kernel image"
	einfo "Installed /boot/kernel_2712.img"

	# DTBs and overlays: eclass puts them in /lib/modules/*/dtb/,
	# RPi firmware expects them in /boot/
	local dtb_dir="${EROOT}/lib/modules/${KV_FULL}/dtb"
	if [[ -d "${dtb_dir}/broadcom" ]]; then
		cp "${dtb_dir}"/broadcom/*.dtb "${EROOT}/boot/" \
			|| die "Failed to install DTBs"
		einfo "Installed DTBs to /boot/"
	fi
	if [[ -d "${dtb_dir}/overlays" ]]; then
		cp -r "${dtb_dir}/overlays" "${EROOT}/boot/" \
			|| die "Failed to install overlays"
		einfo "Installed overlays to /boot/"
	fi
}
