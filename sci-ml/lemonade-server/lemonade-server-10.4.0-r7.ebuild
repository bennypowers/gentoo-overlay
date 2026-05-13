# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Local LLM server orchestrating backend inference processes"
HOMEPAGE="https://github.com/lemonade-sdk/lemonade"
SRC_URI="
	https://github.com/lemonade-sdk/lemonade/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/bennypowers/gentoo-overlay/releases/download/${P}/lemonade-server-${PV}-npm-deps.tar.xz -> lemonade-server-${PV}-npm-deps.tar.xz
"
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

src_prepare() {
	cmake_src_prepare
	# npm 11.x audit triggers "Exit handler never called!" bug
	# https://github.com/npm/cli/issues/7766
	echo -e "audit=false\nfund=false" > src/web-app/.npmrc
	if use webapp; then
		# Vendor npm deps into source tree. cmake copies src/web-app/ to staging
		# (including node_modules), then runs npm ci which requires network.
		# Skip npm ci since node_modules is already vendored.
		tar -xf "${DISTDIR}/lemonade-server-${PV}-npm-deps.tar.xz" \
			-C src/web-app/ node_modules
		# Replace "npm ci" with a no-op (deps already vendored)
		sed -i 's|COMMAND "${NPM_EXECUTABLE}" ci --ignore-scripts|COMMAND echo "Using vendored node_modules"|' \
			src/web-app/BuildWebApp.cmake
	fi
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_WEB_APP=$(usex webapp ON OFF)
		-DBUILD_TAURI_APP=OFF
		-DBUILD_APPIMAGE=OFF
		-DFETCHCONTENT_FULLY_DISCONNECTED=ON
		# cpp-httplib has no .pc file on Gentoo; upstream checks pkg-config
		# but the header is installed, so force system detection
		-DUSE_SYSTEM_HTTPLIB=ON
	)
	cmake_src_configure
}
