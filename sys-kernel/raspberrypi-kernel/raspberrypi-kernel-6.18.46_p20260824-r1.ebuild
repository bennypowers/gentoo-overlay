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
	local active_link="${EROOT}/boot/active"
	local target_dir

	# --- Directory-level symlink: /boot/active -> rpi-${KV_FULL} ---
	if [[ -L "${active_link}" ]]; then
		target_dir="$(readlink -f "${active_link}")"
		if [[ "${target_dir}" == "${boot_dir}" ]]; then
			einfo "/boot/active already points to ${KV_FULL}, no update needed"
		else
			einfo "Updating /boot/active from ${target_dir#${EROOT}/boot/} to ${KV_FULL}"
			rm -f "${active_link}" || die
			ln -s "rpi-${KV_FULL}" "${active_link}" || die
		fi
	else
		ln -s "rpi-${KV_FULL}" "${active_link}" || die
		einfo "Created /boot/active -> rpi-${KV_FULL}"
	fi

	# --- Top-level compatibility symlinks ---
	ln -sf "rpi-${KV_FULL}/kernel_2712.img" "${EROOT}/boot/kernel_2712.img" || die
	ln -sf "rpi-${KV_FULL}/overlays" "${EROOT}/boot/overlays" || die

	# Individual DTB symlinks from installed target directory (Fixes ${WORKDIR} bug)
	local dtb
	shopt -s nullglob
	for dtb in "${boot_dir}"/*.dtb; do
		local dtb_name="${dtb##*/}"
		ln -sf "rpi-${KV_FULL}/${dtb_name}" "${EROOT}/boot/${dtb_name}" || die
	done
	shopt -u nullglob

	ewarn ""
	ewarn "Boot layout has changed for version isolation:"
	ewarn "  All boot artifacts are now in /boot/rpi-${KV_FULL}/"
	ewarn "  /boot/active -> rpi-${KV_FULL} (symlink to current version)"
	ewarn ""
	ewarn "Recommended /boot/config.txt setting:"
	ewarn "  os_prefix=active/"
	ewarn "  overlay_prefix=active/overlays/"
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
	local active_link="${EROOT}/boot/active"
	local target_dir

	# --- Remove top-level compatibility symlinks if they still point here ---
	if [[ -L "${EROOT}/boot/kernel_2712.img" ]]; then
		target_dir="$(readlink -f "${EROOT}/boot/kernel_2712.img")"
		if [[ "${target_dir}" == "${boot_dir}/kernel_2712.img" ]]; then
			rm -f "${EROOT}/boot/kernel_2712.img" || die
		fi
	fi

	if [[ -L "${EROOT}/boot/overlays" ]]; then
		target_dir="$(readlink -f "${EROOT}/boot/overlays")"
		if [[ "${target_dir}" == "${boot_dir}/overlays" ]]; then
			rm -f "${EROOT}/boot/overlays" || die
		fi
	fi

	# --- Promote /boot/active to next-highest remaining version ---
	if [[ -L "${active_link}" ]]; then
		target_dir="$(readlink -f "${active_link}")"
		if [[ "${target_dir}" == "${boot_dir}" ]]; then
			local best_dir=""
			local d
			shopt -s nullglob
			for d in "${EROOT}/boot"/rpi-*; do
				[[ "${d}" != "${boot_dir}" && -d "${d}" ]] && best_dir="${d}"
			done
			shopt -u nullglob

			if [[ -n "${best_dir}" ]]; then
				rm -f "${active_link}" || die
				ln -s "$(basename "${best_dir}")" "${active_link}" || die
				einfo "Updated /boot/active -> $(basename "${best_dir}")"
			else
				rm -f "${active_link}" || die
				einfo "Removed /boot/active (no remaining versions)"
			fi
		fi
	fi

	# --- Clean up individual DTB symlinks ---
	# boot_dir is already emptied by Portage before pkg_postrm runs,
	# so we must glob /boot/*.dtb and remove any dangling or stale ones.
	local dtb_name
	shopt -s nullglob
	for dtb in "${EROOT}/boot"/*.dtb; do
		dtb_name="${dtb##*/}"
		if [[ -L "${EROOT}/boot/${dtb_name}" ]]; then
			local link_target
			link_target="$(readlink -f "${EROOT}/boot/${dtb_name}" 2>/dev/null)"
			if [[ "${link_target}" == "${boot_dir}/${dtb_name}" || ! -e "${link_target}" ]]; then
				rm -f "${EROOT}/boot/${dtb_name}" || die
			fi
		fi
	done
	shopt -u nullglob

	# --- Remove dead module build symlinks ---
	local link
	for link in build source config vmlinuz; do
		local mod_link="${EROOT}/lib/modules/${KV_FULL}/${link}"
		if [[ -L "${mod_link}" ]] && [[ ! -e "${mod_link}" ]]; then
			rm -f "${mod_link}" || die
			einfo "Removed dead symlink: ${mod_link}"
		fi
	done

	# --- Remove versioned boot directory (safe, only if empty) ---
	rmdir "${boot_dir}" 2>/dev/null
}
