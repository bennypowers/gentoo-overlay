# Copyright 2026 Benny Powers
# SPDX-License-Identifier: Apache-2.0

# Live ebuild tracking upstream main; upstream has no release tags.
# Sources are cloned at fetch time, so there are no distfiles or
# Manifest entries to maintain.

EAPI=8

inherit git-r3 meson

EGIT_REPO_URI="https://github.com/noctalia-dev/luciole.git"
EGIT_BRANCH="main"

DESCRIPTION="A native Wayland file manager using Noctalia rendering and controls"
HOMEPAGE="https://github.com/noctalia-dev/luciole"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

IUSE="+network +samba zeroconf test"

RDEPEND="
	>=dev-libs/glib-2.76
	dev-cpp/nlohmann_json
	dev-cpp/tomlplusplus
	dev-libs/stb
	dev-libs/wayland
	dev-libs/libxml2
	net-misc/curl
	x11-libs/gdk-pixbuf
	app-arch/libarchive
	app-arch/xz-utils
	sys-apps/acl
	media-libs/libpng
	gnome-base/librsvg
	media-libs/freetype
	media-libs/fontconfig
	x11-libs/cairo
	x11-libs/pango
	media-libs/harfbuzz
	x11-libs/libxkbcommon
	virtual/opengl
	samba? ( gnome-base/gvfs[samba] )
	network? ( gnome-base/gvfs[sftp,http] )
	zeroconf? ( gnome-base/gvfs[zeroconf] )
	network? ( net-libs/glib-networking )
	media-video/ffmpeg
	media-libs/ffmpegthumbnailer
	app-text/poppler
	app-arch/7zip
	sys-apps/xdg-desktop-portal
	x11-misc/shared-mime-info
	gnome-base/gsettings-desktop-schemas
	gnome-base/dconf
"
DEPEND="${RDEPEND}
	test? ( dev-libs/wayland )
"
BDEPEND="
	>=dev-libs/wayland-protocols-1.49
	dev-util/wayland-scanner
"

RESTRICT="mirror"

src_prepare() {
	default

	# C++23 std::print/std::expected/std::move_only_function need GCC 14+.
	if tc-is-gcc && [ "$(gcc-major-version)" -lt 14 ]; then
		ewarn "Luciole requires a C++23 toolchain with std::print; GCC 14+ is expected."
	fi
}

src_configure() {
	local emesonargs=(
		-Dtests=$(usex test enabled disabled)
		-Dnative_optimizations=false
	)
	meson_src_configure
}

pkg_postinst() {
	einfo "Luciole registers a FileChooser xdg-desktop-portal backend"
	einfo "(org.freedesktop.impl.portal.FileChooser=luciole). To make"
	einfo "xdg-desktop-portal prefer it, add to /etc/xdg/xdg-desktop-portal/portals.conf:"
	einfo ""
	einfo "\t[preferred]"
	einfo "\torg.freedesktop.impl.portal.FileChooser=luciole;gtk"
	einfo ""
	einfo "and restart the xdg-desktop-portal frontend."
}
