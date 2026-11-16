# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Live ebuild tracking upstream main. Crates are fetched and vendored
# during src_unpack (cargo_live_src_unpack), so there are no distfiles
# and no Manifest entries to maintain.

EAPI=8

inherit cargo desktop git-r3 systemd xdg

EGIT_REPO_URI="https://github.com/feschber/lan-mouse.git"
EGIT_BRANCH="main"

RUST_MIN_VER="1.88.0"

DESCRIPTION="Software KVM Switch / mouse & keyboard sharing software for Local Area Networks"
HOMEPAGE="https://github.com/feschber/lan-mouse"

LICENSE="GPL-3+"
# Dependent crate licenses (crates are fetched at unpack time)
LICENSE+="
	Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD CC0-1.0 ISC MIT
	Unicode-3.0 Unlicense ZLIB
"
SLOT="0"
KEYWORDS="~amd64"

IUSE="debug"
DEPEND="
	dev-libs/glib:2
	gui-libs/gtk:4
	gui-libs/libadwaita:1
	x11-libs/libX11
	x11-libs/libXtst
	x11-themes/hicolor-icon-theme
	debug? (
		x11-libs/cairo
		x11-libs/pango
		x11-libs/gdk-pixbuf:2
		media-libs/graphene
		dev-libs/libgit2:=
	)
"
RDEPEND="${DEPEND}"
BDEPEND="
	sys-devel/patch
	virtual/pkgconfig
"

RESTRICT="mirror"

QA_FLAGS_IGNORED="usr/bin/lan-mouse"

src_unpack() {
	git-r3_src_unpack
	cd "${S}"

	# User patches from /etc/portage/patches/${CATEGORY}/${P}/ must be in
	# place before cargo_live_src_unpack so any crates they add are
	# included in the fetch. eapply_user can't be used here: it only runs
	# in the prepare phase, which is too late for the fetch.
	local userpatchdir="${PORTAGE_CONFIGROOT%/}/etc/portage/patches/${CATEGORY}/${P}"
	if [[ -d ${userpatchdir} ]]; then
		local p
		for p in "${userpatchdir}"/*.patch; do
			[[ -e ${p} ]] || continue
			eapply -- "${p}"
		done
	fi

	cargo_live_src_unpack
}

src_prepare() {
	# User patches were already applied in src_unpack; satisfy the
	# post-prepare check that expects eapply_user to have run.
	>> "${T}/.portage_user_patches_applied"
}

src_install() {
	cargo_src_install
	doicon -s scalable lan-mouse-gtk/resources/de.feschber.LanMouse.svg
	domenu de.feschber.LanMouse.desktop
	systemd_douserunit service/lan-mouse.service
}
