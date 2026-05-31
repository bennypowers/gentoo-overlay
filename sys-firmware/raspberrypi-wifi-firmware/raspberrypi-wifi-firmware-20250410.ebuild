# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Broadcom/Cypress WiFi firmware for Raspberry Pi (BCM43455)"
HOMEPAGE="https://github.com/RPi-Distro/firmware-nonfree"

COMMIT="9794282eb9f4a2de1f23b41a738926740e975d83"
SRC_URI="
	https://github.com/RPi-Distro/firmware-nonfree/archive/${COMMIT}.tar.gz
		-> ${P}.tar.gz
"
S="${WORKDIR}/firmware-nonfree-${COMMIT}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~arm64"
RESTRICT="bindist strip"

src_install() {
	local fwdir="${ED}/lib/firmware/brcm"
	local srcdir="debian/config/brcm80211"

	insinto /lib/firmware/brcm

	# Main firmware binary (standard variant)
	newins "${srcdir}/cypress/cyfmac43455-sdio-standard.bin" brcmfmac43455-sdio.bin

	# CLM regulatory blob
	newins "${srcdir}/cypress/cyfmac43455-sdio.clm_blob" brcmfmac43455-sdio.clm_blob

	# NVRAM configs per board
	doins "${srcdir}/brcm/brcmfmac43455-sdio.txt"
	doins "${srcdir}/brcm/brcmfmac43455-sdio.raspberrypi,5-model-b.txt"
	doins "${srcdir}/brcm/brcmfmac43455-sdio.raspberrypi,500.txt"
	doins "${srcdir}/brcm/brcmfmac43455-sdio.raspberrypi,5-compute-module.txt"

	# Board-specific symlinks (Pi 5 looks for firmware by model name)
	dosym brcmfmac43455-sdio.bin /lib/firmware/brcm/brcmfmac43455-sdio.raspberrypi,5-model-b.bin
	dosym brcmfmac43455-sdio.clm_blob /lib/firmware/brcm/brcmfmac43455-sdio.raspberrypi,5-model-b.clm_blob
	dosym brcmfmac43455-sdio.bin /lib/firmware/brcm/brcmfmac43455-sdio.raspberrypi,500.bin
	dosym brcmfmac43455-sdio.clm_blob /lib/firmware/brcm/brcmfmac43455-sdio.raspberrypi,500.clm_blob
	dosym brcmfmac43455-sdio.bin /lib/firmware/brcm/brcmfmac43455-sdio.raspberrypi,5-compute-module.bin
	dosym brcmfmac43455-sdio.clm_blob /lib/firmware/brcm/brcmfmac43455-sdio.raspberrypi,5-compute-module.clm_blob

	# Ensure brcmfmac-wcc module loads before brcmfmac
	insinto /lib/modules-load.d
	newins - raspberrypi-wifi.conf <<-EOF
		brcmfmac-wcc
	EOF
}
