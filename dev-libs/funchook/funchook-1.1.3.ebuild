# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Hook functions by binary rewriting; used by comfy-aimdo"
HOMEPAGE="https://github.com/kubo/funchook"
SRC_URI="https://github.com/kubo/funchook/releases/download/v${PV}/funchook-${PV}.tar.gz"

LICENSE="GPL-2+ BSD"
SLOT="0/1"
KEYWORDS="~amd64"

src_configure() {
	local mycmakeargs=(
		-DFUNCHOOK_BUILD_SHARED=ON
		-DFUNCHOOK_BUILD_STATIC=OFF
		-DFUNCHOOK_BUILD_TESTS=OFF
		# distorm is bundled in the release tarball; the capstone and zydis
		# backends fetch sources from the network at build time
		-DFUNCHOOK_DISASM=distorm
	)
	cmake_src_configure
}
