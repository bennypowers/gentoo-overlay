# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit mount-boot kernel-build eselect-kernel

COMMIT="16f1da3c4e94437449d6aa151589ca0ad4b388bb"

DESCRIPTION="Raspberry Pi kernel built from Foundation sources"
HOMEPAGE="https://github.com/raspberrypi/linux"
SRC_URI="
	https://github.com/raspberrypi/linux/archive/${COMMIT}.tar.gz
		-> ${P}.tar.gz
"
S="${WORKDIR}/linux-${COMMIT}"

LICENSE="GPL-2"
SLOT="${PV}"
KEYWORDS="-* ~arm64"
IUSE="-initramfs debug +strip"

RDEPEND="
	>=sys-boot/raspberrypi-firmware-1.20260513
	sys-firmware/raspberrypi-wifi-firmware
"

src_prepare() {
	default

	cp arch/arm64/configs/bcm2712_defconfig .config || die

	local myversion="-p$(ver_cut 5)-raspberrypi"
	echo "CONFIG_LOCALVERSION=\"${myversion}\"" > "${T}"/version.config || die

	kernel-build_merge_configs "${T}"/version.config
}

src_install() {
	kernel-build_src_install

	dodir /boot/rpi-${KV_FULL}
	dodir /boot/rpi-${KV_FULL}/overlays

	insinto /boot/rpi-${KV_FULL}
	newins "${WORKDIR}/build/arch/arm64/boot/Image" kernel_2712.img

	local dtb_src="${WORKDIR}/build/arch/arm64/boot/dts/broadcom"
	if [[ -d "${dtb_src}" ]]; then
		doins "${dtb_src}"/*.dtb
	fi

	local overlay_src="${WORKDIR}/build/arch/arm64/boot/dts/overlays"
	if [[ -d "${overlay_src}" ]]; then
		insinto /boot/rpi-${KV_FULL}/overlays
		doins "${overlay_src}"/*.dtb*
		[[ -f "${overlay_src}/README" ]] && doins "${overlay_src}/README"
	fi
}

pkg_pretend() {
	if use initramfs; then
		ewarn "RPi5 boots without an initramfs. The firmware bootloader loads"
		ewarn "the kernel image directly from /boot/kernel_2712.img."
		ewarn "USE=initramfs will pull in dracut/ugrd unnecessarily."
	fi
	kernel-install_pkg_pretend
}

pkg_postinst() {
	kernel-build_pkg_postinst
	mount-boot_pkg_postinst
	eselect-kernel_pkg_postinst

	local boot_dir="${EROOT}/boot/rpi-${KV_FULL}"

	# --- Top-level compatibility fallbacks (cp -f, no symlinks in /boot) ---
	# Copy kernel image so older firmware without os_prefix still boots.
	cp -f "${boot_dir}/kernel_2712.img" "${EROOT}/boot/kernel_2712.img" || die
	einfo "Installed /boot/kernel_2712.img (compatibility fallback)"

	# Copy overlays directory so overlay_prefix=overlays/ still works.
	# Remove stale overlay dir first so cp -rf gets a clean slate.
	rm -rf "${EROOT}/boot/overlays" 2>/dev/null
	cp -rf "${boot_dir}/overlays" "${EROOT}/boot/overlays" || die
	einfo "Installed /boot/overlays/ (compatibility fallback)"

	ewarn ""
	ewarn "Boot layout uses version-isolated directories (no symlinks in /boot):"
	ewarn "  All boot artifacts are in /boot/rpi-${KV_FULL}/"
	ewarn "  Top-level compatibility fallbacks copied to /boot/"
	ewarn ""
	ewarn "Recommended /boot/config.txt setting for native prefix mode:"
	ewarn "  os_prefix=rpi-${KV_FULL}/"
	ewarn "  overlay_prefix=overlays/"
	ewarn ""

	if [[ -f "${EROOT}/boot/config.txt" ]] && \
		! grep -q 'pcie-32bit-dma' "${EROOT}/boot/config.txt"; then
		ewarn "If using a JMicron JMB582/585 SATA controller (e.g. Radxa SATA HAT),"
		ewarn "add to /boot/config.txt:"
		ewarn "  dtoverlay=pcie-32bit-dma-pi5"
		ewarn "See: https://github.com/raspberrypi/linux/issues/7375"
	fi
}

pkg_postrm() {
	mount-boot_pkg_postrm
	eselect-kernel_pkg_postrm

	local boot_dir="${EROOT}/boot/rpi-${KV_FULL}"

	# --- Remove versioned boot directory ---
	rm -rf "${boot_dir}" 2>/dev/null

	# --- Find latest remaining version directory (sort -V for correct ordering) ---
	local best_dir=""
	local candidates
	shopt -s nullglob
	candidates=("${EROOT}/boot"/rpi-*/)
	shopt -u nullglob
	if [[ ${#candidates[@]} -gt 0 ]]; then
		best_dir=$(printf '%s\n' "${candidates[@]}" | sort -V | tail -n1)
		best_dir="${best_dir%/}"  # strip trailing slash
	fi

	# --- Update or clean up top-level compatibility fallbacks ---
	if [[ -n "${best_dir}" ]]; then
		# Copy latest remaining version to top-level fallbacks
		cp -f "${best_dir}/kernel_2712.img" "${EROOT}/boot/kernel_2712.img" 2>/dev/null
		rm -rf "${EROOT}/boot/overlays" 2>/dev/null
		cp -rf "${best_dir}/overlays" "${EROOT}/boot/overlays" 2>/dev/null
		einfo "Updated top-level compatibility fallbacks to $(basename "${best_dir}")"
	else
		# No remaining kernels; clean up top-level fallbacks
		rm -f "${EROOT}/boot/kernel_2712.img" 2>/dev/null
		rm -rf "${EROOT}/boot/overlays" 2>/dev/null
	fi

	# --- Remove dead module build symlinks ---
	local link
	for link in build source config vmlinuz; do
		local mod_link="${EROOT}/lib/modules/${KV_FULL}/${link}"
		if [[ -L "${mod_link}" ]] && [[ ! -e "${mod_link}" ]]; then
			rm -f "${mod_link}" || die
			einfo "Removed dead symlink: ${mod_link}"
		fi
	done
}
