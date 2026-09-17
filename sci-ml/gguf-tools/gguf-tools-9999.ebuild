# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3 toolchain-funcs

DESCRIPTION="GGUF file manipulation tools and library"
HOMEPAGE="https://github.com/antirez/gguf-tools"
EGIT_REPO_URI="https://github.com/antirez/gguf-tools.git"
EGIT_BRANCH="main"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

src_compile() {
	emake \
		CC="$(tc-getCC)" \
		CFLAGS="${CFLAGS//\-march=native/}" \
		LDFLAGS="${LDFLAGS}" \
		gguf-tools
}

src_install() {
	dobin gguf-tools
	dodoc README.md
}
