# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit kernel-build

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
IUSE="initramfs debug +strip"

RDEPEND="
	>=sys-boot/raspberrypi-firmware-1.20260513
	sys-firmware/raspberrypi-wifi-firmware
"

# Name the Pi 5 firmware bootloader loads. Keep in one place: it appears in the
# staged payload, the versioned boot dir and the top-level fallback.
RPI_IMAGE_NAME="kernel_2712.img"

# Populate RPI_STASH (package-owned payload) and RPI_BOOT (the dir the firmware
# reads when os_prefix points at it) for the current phase.
rpi_dirs() {
	RPI_STASH="${EROOT}/usr/lib/${PN}/${KV_FULL}"
	RPI_BOOT="${EROOT}/boot/rpi-${KV_FULL}"
}

# True when /etc/fstab declares /boot as a separate filesystem but it is not
# usable: absent from /proc/mounts, or mounted read-only. mount-boot.eclass
# disables itself whenever EROOT is non-empty (always during a merge), and this
# cluster's fstab marks /boot noauto, so an unusable /boot otherwise sends the
# kernel and DTBs to the root filesystem, where the Raspberry Pi firmware can
# never see them.
boot_partition_not_usable() {
	local fstab=${RPI_FSTAB:-/etc/fstab}
	local mounts=${RPI_MOUNTS:-/proc/mounts}

	# Only meaningful for a live merge into the current root; skip for ROOT
	# images and binpkg-only builds (mount-boot-utils.eclass does the same).
	if [[ -n ${ROOT} && ${ROOT} != / ]]; then
		return 1
	fi
	if [[ ${MERGE_TYPE} == buildonly ]]; then
		return 1
	fi
	# Same escape hatch mount-boot-utils.eclass documents.
	[[ -n ${DONT_MOUNT_BOOT} ]] && return 1
	[[ -r ${fstab} ]] || return 1

	# Skip comments and the /dev/BOOT placeholder from the default fstab;
	# tolerate a trailing slash on the mount point.
	awk '!/^[[:blank:]]*#/ && $1 != "/dev/BOOT" &&
		($2 == "/boot" || $2 == "/boot/") { found = 1 }
		END { exit !found }' "${fstab}" || return 1

	# Mounted read-write? (mount-boot_check_status semantics.)
	awk '($2 == "/boot" || $2 == "/boot/") {
			n = split($4, opts, ",")
			for (i = 1; i <= n; i++) if (opts[i] == "rw") rw = 1
			found = 1
		}
		END { exit !(found && rw) }' "${mounts}" && return 1

	return 0
}

# Fail before building if the merge target cannot receive the payload.
rpi_check_boot_mounted() {
	if boot_partition_not_usable; then
		eerror "/etc/fstab declares a separate /boot, but it is not mounted"
		eerror "read-write. The kernel and DTBs would land on the root filesystem,"
		eerror "where the firmware cannot find them (boot fails with a missing DTB)."
		die "/boot is not mounted read-write; run 'mount -o remount,rw /boot' and retry"
	fi
}

# Materialise RPI_BOOT from the package-owned payload, atomically: build the new
# tree beside the old one, verify it, then swap. A copy failure is fatal because
# the stash under /usr/lib survives for a retry (emerge --config or a re-merge),
# and a truncated kernel is worse than a failed phase.
rpi_materialise_boot() {
	local staging="${RPI_BOOT}.new"
	local old="${RPI_BOOT}.old"

	[[ -s "${RPI_STASH}/${RPI_IMAGE_NAME}" ]] \
		|| die "Missing ${RPI_STASH}/${RPI_IMAGE_NAME}; the package image is incomplete"

	rm -rf "${staging}" "${old}"
	mkdir -p "${staging}/overlays" || die "Cannot create ${staging}"
	cp -f "${RPI_STASH}/${RPI_IMAGE_NAME}" "${staging}/" \
		|| die "Failed to copy the kernel image into ${staging}"
	cp -f "${RPI_STASH}"/*.dtb "${staging}/" \
		|| die "Failed to copy DTBs into ${staging}"
	cp -f "${RPI_STASH}/overlays/"* "${staging}/overlays/" \
		|| die "Failed to copy overlays into ${staging}"

	# Never install an empty or partial payload.
	[[ -s "${staging}/${RPI_IMAGE_NAME}" ]] || die "Empty kernel image in ${staging}"
	compgen -G "${staging}/*.dtb" >/dev/null || die "No DTBs staged in ${staging}"
	compgen -G "${staging}/overlays/*" >/dev/null || die "No overlays staged in ${staging}"

	if [[ -d "${RPI_BOOT}" ]]; then
		mv "${RPI_BOOT}" "${old}" || die "Cannot move ${RPI_BOOT} aside"
	fi
	mv "${staging}" "${RPI_BOOT}" || die "Cannot install ${RPI_BOOT}"
	rm -rf "${old}"
}

# Populate the top-level fallbacks used by nodes without os_prefix. These paths
# are shared by every installed kernel slot, so they are never package-owned.
# Failures are reported but not fatal: the versioned layout is authoritative.
rpi_install_top_level_fallbacks() {
	local failed=0
	local f

	cp -f "${RPI_BOOT}/${RPI_IMAGE_NAME}" "${EROOT}/boot/${RPI_IMAGE_NAME}" \
		|| { eerror "Failed to update /boot/${RPI_IMAGE_NAME}"; failed=1; }

	for f in "${RPI_BOOT}"/*.dtb; do
		[[ -e ${f} ]] || continue
		cp -f "${f}" "${EROOT}/boot/" \
			|| { eerror "Failed to update /boot/$(basename "${f}")"; failed=1; }
	done

	local ovl_new="${EROOT}/boot/.overlays.new"
	rm -rf "${ovl_new}"
	if cp -rf "${RPI_BOOT}/overlays" "${ovl_new}"; then
		rm -rf "${EROOT}/boot/overlays"
		mv "${ovl_new}" "${EROOT}/boot/overlays" \
			|| { eerror "Failed to install /boot/overlays"; failed=1; }
	else
		rm -rf "${ovl_new}"
		eerror "Failed to stage /boot/overlays"
		failed=1
	fi

	if (( failed )); then
		eerror "Top-level boot fallbacks under /boot are incomplete; a node"
		eerror "without os_prefix may fail to boot. Verify /boot is mounted"
		eerror "read-write and re-merge this package."
	fi
}

# True when another installed package owns the path (e.g. the 6.12 SLOT=0
# ebuild or sys-kernel/raspberrypi-image, which own top-level /boot files).
rpi_owned_by_other_pkg() {
	local path=$1
	[[ -e ${path} ]] || return 1
	[[ -n $(portageq owners "${EROOT}" "${path}" 2>/dev/null) ]]
}

src_prepare() {
	default

	cp arch/arm64/configs/bcm2712_defconfig .config || die

	local myversion="-p$(ver_cut 5)-raspberrypi"
	echo "CONFIG_LOCALVERSION=\"${myversion}\"" > "${T}"/version.config || die

	kernel-build_merge_configs "${T}"/version.config
}

src_install() {
	kernel-build_src_install

	local image_src="${WORKDIR}/build/arch/arm64/boot/Image"
	local dtb_src="${WORKDIR}/build/arch/arm64/boot/dts/broadcom"
	local overlay_src="${WORKDIR}/build/arch/arm64/boot/dts/overlays"

	# Never ship a kernel without DTBs. The old code skipped the copy when the
	# build directory was absent, which produced a package the firmware could
	# not boot and only showed up at the next reboot.
	shopt -s nullglob
	local dtbs=( "${dtb_src}"/*.dtb )
	# *.dtb* (not *.dtbo): the overlays build dir also emits plain-DTB maps
	# (overlay_map.dtb, hat_map.dtb) that the firmware needs for overlay
	# resolution.
	local overlays=( "${overlay_src}"/*.dtb* )
	shopt -u nullglob
	[[ -f "${image_src}" ]] || die "Missing kernel image: ${image_src}"
	[[ ${#dtbs[@]} -gt 0 ]] || die "No DTBs built under ${dtb_src}"
	[[ ${#overlays[@]} -gt 0 ]] || die "No overlays built under ${overlay_src}"

	# --- Package-owned payload ---
	# Keep the firmware payload out of the package's /boot paths and under a
	# path only this package owns. pkg_postinst materialises /boot from here
	# on every merge, which is what makes revision upgrades safe: Portage
	# merges the new files, then runs the *replaced* package's pkg_postrm
	# (which may rm -rf the shared /boot/rpi-${KV_FULL} directory), and only
	# then the new pkg_postinst. Without this staging copy that order leaves
	# the new kernel and DTBs deleted before the firmware ever sees them.
	insinto /usr/lib/${PN}/${KV_FULL}
	newins "${image_src}" "${RPI_IMAGE_NAME}"
	doins "${dtbs[@]}"

	insinto /usr/lib/${PN}/${KV_FULL}/overlays
	doins "${overlays[@]}"
	if [[ -f "${overlay_src}/README" ]]; then
		doins "${overlay_src}/README"
	fi
}

pkg_pretend() {
	rpi_check_boot_mounted

	if use initramfs; then
		ewarn "RPi5 boots without an initramfs. The firmware bootloader loads"
		ewarn "the kernel image directly from /boot/${RPI_IMAGE_NAME}."
		ewarn "USE=initramfs will pull in dracut/ugrd unnecessarily."
	fi
	kernel-install_pkg_pretend
}

pkg_preinst() {
	# pkg_pretend is not run by direct 'ebuild ... merge' invocations, so keep
	# the mount gate here as well.
	rpi_check_boot_mounted

	# Chaining is mandatory: defining pkg_preinst shadows the eclass-exported
	# kernel-install_pkg_preinst, which restores the module signing key, checks
	# the installed kernel dir/version, and rewrites /lib/modules/${KV_FULL}
	# symlinks on merged-usr systems.
	kernel-install_pkg_preinst
}

pkg_postinst() {
	rpi_dirs

	# Materialise the boot payload before installkernel/dracut runs: if that
	# step dies, the replaced package's postrm may already have removed every
	# bootable file, and the node must still have a kernel in place.
	rpi_materialise_boot

	kernel-build_pkg_postinst

	if boot_partition_not_usable; then
		ewarn "A separate /boot is declared in /etc/fstab but is not mounted"
		ewarn "read-write. Files were written to the root filesystem; the firmware"
		ewarn "will not see them. Mount /boot and re-merge this package."
	fi

	rpi_install_top_level_fallbacks

	ewarn ""
	ewarn "Boot layout uses version-isolated directories (no symlinks in /boot):"
	ewarn "  All boot artifacts are in /boot/rpi-${KV_FULL}/"
	ewarn "  Top-level compatibility fallbacks installed to /boot/"
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

pkg_config() {
	rpi_dirs

	# Recovery path advertised by dist-kernel: restores /boot from the staged
	# copy, then re-runs installkernel/dracut.
	rpi_materialise_boot
	rpi_install_top_level_fallbacks
	kernel-install_pkg_config
}

pkg_postrm() {
	rpi_dirs

	# During a revision replacement the new pkg_postinst runs after this phase
	# and materialises /boot from the new package's staged copy. Doing nothing
	# here keeps the previous kernel bootable for the whole window.
	if [[ -n ${REPLACED_BY_VERSION} ]]; then
		return 0
	fi

	# Removes initramfs/uki leftovers and any dead /lib/modules symlinks.
	kernel-install_pkg_postrm

	rm -rf "${RPI_BOOT}" 2>/dev/null

	# --- Find latest remaining version directory (sort -V) ---
	local best_dir=""
	local candidates
	shopt -s nullglob
	candidates=("${EROOT}/boot"/rpi-*/)
	shopt -u nullglob
	if [[ ${#candidates[@]} -gt 0 ]]; then
		best_dir=$(printf '%s\n' "${candidates[@]}" | sort -V | tail -n1)
		best_dir="${best_dir%/}"
	fi

	# --- Update or clean up top-level compatibility fallbacks ---
	if [[ -n "${best_dir}" ]]; then
		local repointed=1
		local f
		cp -f "${best_dir}/${RPI_IMAGE_NAME}" "${EROOT}/boot/${RPI_IMAGE_NAME}" \
			|| repointed=0
		for f in "${best_dir}"/*.dtb; do
			[[ -e ${f} ]] || continue
			cp -f "${f}" "${EROOT}/boot/" || repointed=0
		done
		if [[ -d "${best_dir}/overlays" ]]; then
			local ovl_new="${EROOT}/boot/.overlays.new"
			rm -rf "${ovl_new}"
			if cp -rf "${best_dir}/overlays" "${ovl_new}"; then
				rm -rf "${EROOT}/boot/overlays"
				mv "${ovl_new}" "${EROOT}/boot/overlays" || repointed=0
			else
				rm -rf "${ovl_new}"
				repointed=0
			fi
		fi
		if (( repointed )); then
			einfo "Updated top-level compatibility fallbacks to $(basename "${best_dir}")"
		else
			ewarn "Failed to update some top-level boot fallbacks from $(basename "${best_dir}")"
		fi
	else
		# Last kernel of this package. Leave the files alone when another
		# installed package owns them (e.g. the 6.12 SLOT=0 ebuild or
		# sys-kernel/raspberrypi-image own the top-level /boot paths).
		if rpi_owned_by_other_pkg "${EROOT}/boot/${RPI_IMAGE_NAME}"; then
			einfo "Leaving top-level boot files alone: owned by another installed package"
		else
			local f
			rm -f "${EROOT}/boot/${RPI_IMAGE_NAME}" 2>/dev/null
			for f in "${EROOT}"/boot/*.dtb; do
				[[ -e ${f} ]] || continue
				rpi_owned_by_other_pkg "${f}" || rm -f "${f}" 2>/dev/null
			done
			rpi_owned_by_other_pkg "${EROOT}/boot/overlays" \
				|| rm -rf "${EROOT}/boot/overlays" 2>/dev/null
		fi
	fi
}
