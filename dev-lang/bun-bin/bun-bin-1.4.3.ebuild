# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="Extremely fast JavaScript runtime and package manager"
HOMEPAGE="https://bun.sh https://github.com/oven-sh/bun"
SRC_URI="
	amd64? (
		https://github.com/oven-sh/bun/releases/download/bun-v${PV}/bun-linux-x64.zip
			-> ${P}-amd64.zip
	)
	arm64? (
		https://github.com/oven-sh/bun/releases/download/bun-v${PV}/bun-linux-aarch64.zip
			-> ${P}-arm64.zip
	)
"
S=${WORKDIR}

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"

RDEPEND="
	|| (
		llvm-runtimes/libgcc
		sys-devel/gcc:*
	)
	sys-libs/glibc
"
BDEPEND="
	app-arch/unzip
"

QA_PREBUILT="usr/bin/bun"

src_install() {
	# The zip extracts to bun-linux-x64/bun or bun-linux-aarch64/bun
	if use amd64; then
		dobin bun-linux-x64/bun
	else
		dobin bun-linux-aarch64/bun
	fi
}
