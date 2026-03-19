# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	allocator-api2@0.2.21
	autocfg@1.5.0
	equivalent@1.0.2
	foldhash@0.2.0
	hashbrown@0.16.0
	heck@0.5.0
	indoc@2.0.7
	itoa@1.0.15
	libc@0.2.177
	memchr@2.7.6
	memmap2@0.9.9
	memoffset@0.9.1
	once_cell@1.21.3
	portable-atomic@1.11.1
	proc-macro2@1.0.103
	pyo3-build-config@0.25.1
	pyo3-ffi@0.25.1
	pyo3-macros-backend@0.25.1
	pyo3-macros@0.25.1
	pyo3@0.25.1
	quote@1.0.42
	rustversion@1.0.22
	ryu@1.0.20
	serde@1.0.228
	serde_core@1.0.228
	serde_derive@1.0.228
	serde_json@1.0.145
	syn@2.0.110
	target-lexicon@0.13.3
	unicode-ident@1.0.22
	unindent@0.2.4
"

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=maturin
PYTHON_COMPAT=( python3_{11..13} )

inherit cargo distutils-r1

DESCRIPTION="Simple and safe way to store and distribute tensors"
HOMEPAGE="https://github.com/huggingface/safetensors"
SRC_URI="
	https://files.pythonhosted.org/packages/source/s/safetensors/safetensors-${PV}.tar.gz
	${CARGO_CRATE_URIS}
"

LICENSE="Apache-2.0"
LICENSE+=" Apache-2.0 MIT Unicode-3.0"
SLOT="0"
KEYWORDS="~amd64"

QA_FLAGS_IGNORED="usr/lib.*/py.*/site-packages/safetensors/.*\.so"
