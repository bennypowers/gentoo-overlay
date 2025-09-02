# Copyright 2025 Benny Powers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="SDDM configuration for Hyprland compositor"
HOMEPAGE="https://github.com/HyDE-Project/sddm-hyprland"
EGIT_REPO_URI="https://github.com/HyDE-Project/sddm-hyprland.git"
EGIT_COMMIT="v${PV}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
  x11-misc/sddm
  gui-wm/hyprland
  kde-plasma/layer-shell-qt
"

src_compile() {
	# Skip the clean target which tries to remove files from /usr
	:
}

src_install() {
	# Manually install files to avoid Makefile's problematic clean target
	insinto /usr/share/hypr/sddm
	doins src/hyprland.conf

	insinto /etc/sddm.conf.d
	doins src/sddm-hyprland.conf

	# Install any additional config files if they exist
	if [[ -f hyprprefs.conf ]]; then
	  insinto /usr/share/hypr/sddm
	  doins hyprprefs.conf
	fi
}
