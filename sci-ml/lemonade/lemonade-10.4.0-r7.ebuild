# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_OPTIONAL=1

inherit cmake rust systemd

DESCRIPTION="Local LLM inference platform with server, CLI, and web interface"
HOMEPAGE="https://github.com/lemonade-sdk/lemonade"
SRC_URI="
	https://github.com/lemonade-sdk/lemonade/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	webapp? (
		https://github.com/bennypowers/gentoo-overlay/releases/download/${PN}/${P}-npm-deps.tar.xz
	)
	gui? (
		https://github.com/bennypowers/gentoo-overlay/releases/download/${PN}/${P}-app-npm-deps.tar.xz
		https://github.com/bennypowers/gentoo-overlay/releases/download/${PN}/${P}-cargo-deps.tar.xz
	)
"

S="${WORKDIR}/${P}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="gui +webapp systemd"

RDEPEND="
	>=net-misc/curl-8.5.0
	>=app-arch/zstd-1.5.5
	>=net-libs/libwebsockets-4.3.3
	gui? (
		net-libs/webkit-gtk:4.1
		x11-libs/gtk+:3
	)
	systemd? (
		acct-group/lemonade
		acct-user/lemonade
		sys-apps/systemd:=
	)
"
DEPEND="${RDEPEND}"
BDEPEND="
	>=dev-cpp/nlohmann_json-3.11.3
	>=dev-cpp/cli11-2.4.2
	>=dev-cpp/cpp-httplib-0.26.0
	gui? (
		${RUST_DEPEND}
		net-libs/nodejs
	)
	webapp? (
		net-libs/nodejs
	)
"

pkg_setup() {
	use gui && rust_pkg_setup
}

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

	if use gui; then
		echo -e "audit=false\nfund=false" > src/app/.npmrc

		tar -xf "${DISTDIR}/${P}-app-npm-deps.tar.xz" \
			-C src/app/ node_modules

		tar -xf "${DISTDIR}/${P}-cargo-deps.tar.xz" \
			-C src/app/src-tauri/

		mkdir -p src/app/src-tauri/.cargo || die
		cat > src/app/src-tauri/.cargo/config.toml <<-EOF
			[source.crates-io]
			replace-with = "vendored-sources"

			[source.vendored-sources]
			directory = "vendor"
		EOF

		# Skip npm ci in Tauri build -- we vendored node_modules
		sed -i '/NPM_COMMAND}.*ci.*--ignore-scripts/d' CMakeLists.txt || die
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

src_compile() {
	cmake_src_compile
	if use gui; then
		cmake_build tauri-app
	fi
}

src_install() {
	cmake_src_install

	if use systemd; then
		keepdir /var/lib/lemonade
		fowners lemonade:lemonade /var/lib/lemonade

		# Upstream installs to ${CMAKE_INSTALL_PREFIX}/lib/systemd/system/
		# which is correct for prefix=/usr, but reinstall via eclass for
		# consistent path handling
		rm "${ED}/usr/lib/systemd/system/lemond.service" || die
		systemd_dounit "${BUILD_DIR}/lemond.service"
	else
		rm -f "${ED}/usr/lib/systemd/system/lemond.service"
		rmdir -p "${ED}/usr/lib/systemd/system" 2>/dev/null
	fi

	if use gui; then
		dobin "${BUILD_DIR}/app/lemonade-app"
	fi

	insinto /usr/share/fish/vendor_completions.d
	doins "${FILESDIR}"/lemonade.fish
}
