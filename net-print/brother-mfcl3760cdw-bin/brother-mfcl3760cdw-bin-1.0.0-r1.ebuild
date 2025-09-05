# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit rpm multilib

PRINTER_MODEL=${PN#*-}
PRINTER_MODEL=${PRINTER_MODEL%-*}

DESCRIPTION="Brother printer driver for ${PRINTER_MODEL}"
HOMEPAGE="https://support.brother.com/g/b/downloadhowto.aspx?c=us&lang=en&prod=${PRINTER_MODEL}_us_eu_as"
SRC_URI="
	https://download.brother.com/welcome/dlf105778/${PRINTER_MODEL}pdrv-3.5.1-1.i386.rpm
"

RESTRICT="mirror strip"

LICENSE="brother-eula"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="scanner"

DEPEND=">=net-print/cups-2.2.7"
RDEPEND="
	${DEPEND}
	scanner? ( >=media-gfx/brother-scan4-bin-0.4.6 )
"

S="${WORKDIR}"

src_unpack() {
	rpm_unpack ${A}
}

src_prepare() {
	default
	sed -i'' \
		-e "s:my \$PRINTER=.*:my \$PRINTER='${PRINTER_MODEL}';:" \
		-e 's:$PRINTER =~ .*::' \
		"${S}"/opt/brother/Printers/${PRINTER_MODEL}/cupswrapper/brother_lpdwrapper_${PRINTER_MODEL}
}

src_install() {
	local ABI="x86_64"
	if has_multilib_profile && use x86; then
		ABI="i686"
	fi

	# Install PPD file
	insinto /usr/share/ppd/Brother
	doins "${S}"/opt/brother/Printers/${PRINTER_MODEL}/cupswrapper/brother_${PRINTER_MODEL}_printer_en.ppd"

	# Install LPD filter files
	insinto /usr/lib/cups/filter
	doins "${S}"/opt/brother/Printers/${PRINTER_MODEL}/lpd/${ABI}/brmfcl3760cdwfilter"
	doins "${S}"/opt/brother/Printers/${PRINTER_MODEL}/lpd/${ABI}/brprintconf_mfcl3760cdw"

	# Install CUPS wrapper files and set up symbolic links
	insinto /usr/lib/cups/driver
	doins "${S}"/opt/brother/Printers/${PRINTER_MODEL}/cupswrapper/cupswrapper${PRINTER_MODEL}"

	# The brother_lpdwrapper_mfcl3760cdw filter needs to be in a specific location
	exeinto /usr/libexec/cups/filter
	doexe "${S}"/opt/brother/Printers/${PRINTER_MODEL}/cupswrapper/brother_lpdwrapper_${PRINTER_MODEL}"

	# If the scanner USE flag is enabled, install the scanner drivers as a dependency.
	# The scanner driver is in a separate package, so this ebuild doesn't need to
	# handle its installation.
	if use scanner; then
		elog "Please ensure net-libs/brother-scan4-bin is emerged with the correct USE flags."
	fi
}

