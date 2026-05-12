# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Local LLM server orchestrating backend inference processes"
HOMEPAGE="https://github.com/lemonade-sdk/lemonade"
SRC_URI="https://github.com/lemonade-sdk/lemonade/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/lemonade-${PV}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+webapp"

RDEPEND="
	>=net-misc/curl-8.5.0
	>=app-arch/zstd-1.5.5
	>=net-libs/libwebsockets-4.3.3
"
DEPEND="${RDEPEND}
	>=dev-cpp/nlohmann_json-3.11.3
	>=dev-cpp/cli11-2.4.2
	>=dev-cpp/cpp-httplib-0.26.0
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
