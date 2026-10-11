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

# NOTE: to regenerate the dependency tarballs:
#       go mod vendor
#       tar -cJf ${P}-deps.tar.xz ${P}/vendor
#       cd client/ui
#       go run github.com/wailsapp/wails/v3/cmd/wails3@<fork-tag> \
#           generate bindings -clean=true -ts
#       (via a wrapper module with:
#           replace github.com/wailsapp/wails/v3 => github.com/netbirdio/wails/v3 <fork-tag>)
#       tar -cJf ${P}-frontend-bindings.tar.xz ${P}/client/ui/frontend/bindings
#       cd client/ui/frontend
#       pnpm install --node-linker=hoisted --frozen-lockfile --ignore-scripts
#       tar -cJf ${P}-node-modules.tar.xz ${P}/client/ui/frontend/node_modules
#       where <fork-tag> is the netbirdio/wails/v3 version from the replace
#       directive in the netbird go.mod

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

PATCHES=( "${FILESDIR}"/${PN}-${PV}-systemd-service-sbin.patch )

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
	newsbin build/client netbird
	fperms 0700 /usr/sbin/netbird

	systemd_dounit "release_files/systemd/netbird@.service"
	newinitd "${FILESDIR}"/netbird.initd netbird

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
