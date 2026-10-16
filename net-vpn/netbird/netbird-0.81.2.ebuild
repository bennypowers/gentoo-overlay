# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop go-module systemd xdg-utils

DESCRIPTION="An Open Source Zero Trust Networking platform"
HOMEPAGE="https://netbird.io/ https://github.com/netbirdio/netbird"
SRC_URI="https://github.com/netbirdio/netbird/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI+=" https://github.com/bennypowers/gentoo-overlay/releases/download/${PN}/${P}-deps.tar.xz"
SRC_URI+="
	gui? (
		https://github.com/bennypowers/gentoo-overlay/releases/download/${PN}/${P}-node-modules.tar.xz
		https://github.com/bennypowers/gentoo-overlay/releases/download/${PN}/${P}-frontend-bindings.tar.xz
	)"

# Tarball generation: .larry/prepare.sh handles deps, frontend-bindings,
# and node-modules. Run it after bumping the version.

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~loong ~riscv ~x86"
IUSE="gui"
RESTRICT="test" # fails with network-sandbox

BDEPEND="
	>=dev-lang/go-1.26.0
	gui? ( >=net-libs/nodejs-20 )
"
# wails v3 GUI links against GTK4 and WebKitGTK 6 via cgo; X11 is
# required unconditionally by wails' global shortcut and tray support
DEPEND="
	gui? (
		gui-libs/gtk:4
		net-libs/webkit-gtk:6
		x11-libs/libX11
	)
"
RDEPEND="
	${DEPEND}
	gui? ( x11-misc/xdg-utils )
"

src_compile() {
	mkdir build || die
	ego build -o build -ldflags="
		-X 'github.com/netbirdio/netbird/version.version=${PV}'
		-extldflags '${LDFLAGS}'
		" ./client

	if use gui; then
		# Wails v3 desktop client. Frontend deps are vendored as a hoisted
		# node_modules tarball and the wails3 TS bindings are pre-generated,
		# so no pnpm and no network access are needed at build time.
		local fe=client/ui/frontend
		(
			cd ${fe} || die
			./node_modules/.bin/tsc || die "tsc failed"
			./node_modules/.bin/vite build --mode production || die "vite build failed"
		) || die "frontend build failed"

		# CGO required for the GTK4/WebKitGTK bindings
		local -x CGO_ENABLED=1
		ego build -tags production -trimpath -ldflags="
			-X 'github.com/netbirdio/netbird/version.version=${PV}'
			-extldflags '${LDFLAGS}'
		" -o build/netbird-ui ./client/ui || die "GUI build failed"
	fi
}

src_install() {
	# single binary for both CLI and daemon (upstream layout); the daemon
	# runs as root via the service manager, the CLI is a normal user tool
	# talking to it over the /var/run/netbird socket
	newbin build/client netbird

	systemd_dounit "release_files/systemd/netbird@.service"
	# initd points at /usr/bin/netbird (upstream layout); the unversioned
	# netbird.initd with the /usr/sbin path is kept for the 0.80.0 ebuild
	newinitd "${FILESDIR}"/${PN}-${PV}-r1.initd netbird

	einstalldocs

	if use gui; then
		newbin build/netbird-ui netbird-ui
		domenu client/ui/build/linux/netbird-ui.desktop
		newicon -s 1024 client/ui/build/appicon.png netbird-ui.png
	fi
}

pkg_postinst() {
	if use gui; then
		xdg_desktop_database_update
		xdg_icon_cache_update
	fi
}

pkg_postrm() {
	if use gui; then
		xdg_desktop_database_update
		xdg_icon_cache_update
	fi
}
