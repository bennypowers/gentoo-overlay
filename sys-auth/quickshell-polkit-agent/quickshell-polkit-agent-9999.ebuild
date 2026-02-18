# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Polkit authentication agent with quickshell integration"
HOMEPAGE="https://github.com/bennypowers/quickshell-polkit-agent"

# Live ebuild using local development directory
SRC_URI=""
KEYWORDS=""
RESTRICT="mirror fetch"

LICENSE="MIT"
SLOT="0"
IUSE=""

DEPEND="
	dev-qt/qtbase:6
	sys-apps/systemd
	sys-auth/polkit-qt[qt6]
"
RDEPEND="${DEPEND}
	net-misc/socat
"
BDEPEND="
	dev-build/cmake
	dev-qt/qttools:6[linguist]
"

S="${WORKDIR}/quickshell-polkit-agent"

src_unpack() {
	# Copy from development directory  
	mkdir -p "${S}" || die
	cp -r --exclude=tests /home/bennyp/Developer/quickshell-polkit-agent/* "${S}/" || die
}

src_prepare() {
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE=Release
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install
	
	# Install quickshell component
	insinto /usr/share/quickshell/components
	doins "${S}/quickshell/PolkitAgent.qml"
	
	# Install examples
	dodoc -r examples/
}