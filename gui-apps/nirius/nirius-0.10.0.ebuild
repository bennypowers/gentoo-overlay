# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	aho-corasick@1.1.5
	anstream@1.0.0
	anstyle-parse@1.0.0
	anstyle-query@1.1.5
	anstyle-wincon@3.0.11
	anstyle@1.0.14
	bitflags@1.3.2
	bitflags@2.13.2
	clap@4.6.7
	clap_builder@4.6.7
	clap_derive@4.6.7
	clap_lex@1.1.1
	colorchoice@1.0.5
	defmt-macros@1.1.1
	defmt-parser@1.0.0
	defmt@1.1.1
	env_filter@2.0.0
	env_logger@0.11.11
	errno@0.3.14
	heck@0.5.0
	is_terminal_polyfill@1.70.2
	itoa@1.0.18
	jiff-core@0.1.1
	jiff-static@0.2.37
	jiff@0.2.37
	libc@0.2.189
	linux-raw-sys@0.12.1
	log@0.4.34
	memchr@2.8.3
	niri-ipc@26.4.0
	once_cell_polyfill@1.70.2
	portable-atomic-util@0.2.8
	portable-atomic@1.15.0
	proc-macro2@1.0.107
	quote@1.0.47
	regex-automata@0.4.18
	regex-syntax@0.8.11
	regex@1.13.1
	rustix@1.1.4
	serde@1.0.229
	serde_core@1.0.229
	serde_derive@1.0.229
	serde_json@1.0.151
	strsim@0.11.1
	syn@2.0.119
	syn@3.0.6
	terminal_size@0.4.4
	thiserror-impl@2.0.21
	thiserror@2.0.21
	unicode-ident@1.0.26
	utf8parse@0.2.2
	windows-link@0.2.1
	windows-sys@0.61.2
	zmij@1.0.23
"
inherit cargo

MY_P="${PN}-${PN}-${PV}"

DESCRIPTION="Utility commands for the niri wayland compositor"
HOMEPAGE="https://sr.ht/~tsdh/nirius/"
SRC_URI="
	https://git.sr.ht/~tsdh/${PN}/archive/${PN}-${PV}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"
S="${WORKDIR}/${MY_P}"

LICENSE="GPL-3+"
LICENSE+=" Apache-2.0 MIT Unicode-3.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="gui-wm/niri"

QA_FLAGS_IGNORED="
	usr/bin/nirius
	usr/bin/niriusd
"

src_install() {
	cargo_src_install
	dodoc README.md
}
