# Copyright 2025 Benny Powers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Polkit authentication agent with quickshell integration"
HOMEPAGE="https://github.com/bennypowers/quickshell-polkit-agent"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/bennypowers/quickshell-polkit-agent/"
	KEYWORDS=""
else
	SRC_URI="https://github.com/bennypowers/quickshell-polkit-agent/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${PN}-${PV}"
	KEYWORDS="~amd64"
fi

LICENSE="MIT"
SLOT="0"
IUSE=""
RESTRICT="mirror"

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
