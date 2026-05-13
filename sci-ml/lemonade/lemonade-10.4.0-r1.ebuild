# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake systemd user

DESCRIPTION="Local LLM inference platform with server, CLI, and web interface"
HOMEPAGE="https://github.com/lemonade-sdk/lemonade"
SRC_URI="
	https://github.com/lemonade-sdk/lemonade/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	webapp? (
		https://github.com/bennypowers/gentoo-overlay/releases/download/${PN}/${P}-npm-deps.tar.xz
	)
"

S="${WORKDIR}/${P}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+webapp systemd"

RDEPEND="
	>=net-misc/curl-8.5.0
	>=app-arch/zstd-1.5.5
	>=net-libs/libwebsockets-4.3.3
	systemd? ( sys-apps/systemd:= )
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

	if ! use systemd; then
		# Prevent linking against libsystemd (journal support)
		sed -e 's/pkg_check_modules(SYSTEMD QUIET libsystemd)/#&/' \
			-i CMakeLists.txt || die
	fi

	if use webapp; then
		# npm 11.x audit triggers "Exit handler never called!" bug
		# https://github.com/npm/cli/issues/7766
		echo -e "audit=false\nfund=false" > src/web-app/.npmrc

		tar -xf "${DISTDIR}/${P}-npm-deps.tar.xz" \
			-C src/web-app/ node_modules
		sed -i 's|COMMAND "${NPM_EXECUTABLE}" ci --ignore-scripts|COMMAND echo "Using vendored node_modules"|' \
			src/web-app/BuildWebApp.cmake || die
	fi
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_WEB_APP=$(usex webapp ON OFF)
		-DBUILD_TAURI_APP=OFF
		-DBUILD_APPIMAGE=OFF
		-DFETCHCONTENT_FULLY_DISCONNECTED=ON
		-DUSE_SYSTEM_HTTPLIB=ON
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install

	if use systemd; then
		do_user lemonade "" "Lemonade server" /dev/null
		do_group lemonade

		# Upstream installs to ${CMAKE_INSTALL_PREFIX}/lib/systemd/system/
		# which is correct for prefix=/usr, but reinstall via eclass for
		# consistent path handling
		rm "${ED}/usr/lib/systemd/system/lemond.service" || die
		systemd_dounit "${BUILD_DIR}/lemond.service"
	else
		rm -f "${ED}/usr/lib/systemd/system/lemond.service"
		rmdir -p "${ED}/usr/lib/systemd/system" 2>/dev/null
	fi
}
