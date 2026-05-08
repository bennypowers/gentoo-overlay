# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Local LLM server orchestrating backend inference processes"
HOMEPAGE="https://github.com/lemonade-sdk/lemonade"
SRC_URI="https://github.com/lemonade-sdk/lemonade/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
IUSE="+webapp"
KEYWORDS="~amd64"

S="${WORKDIR}/lemonade-${PV}"

RDEPEND="
	net-libs/libcurl
	app-arch/zstd
	net-libs/libwebsockets
"
DEPEND="${RDEPEND}
	dev-cpp/nlohmann_json
	dev-cpp/cli11
	dev-cpp/cpp-httplib
"
BDEPEND="
	webapp? (
		net-libs/nodejs
	)
"

src_configure() {
	local mycmakeargs=(
		-DBUILD_WEB_APP=$(usex webapp ON OFF)
		-DBUILD_TAURI_APP=OFF
		-DBUILD_APPIMAGE=OFF
	)
	cmake_src_configure
}
