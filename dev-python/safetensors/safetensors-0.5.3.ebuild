# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	autocfg@1.4.0
	cfg-if@1.0.0
	heck@0.5.0
	indoc@2.0.5
	itoa@1.0.14
	libc@0.2.170
	memchr@2.7.4
	memmap2@0.9.5
	memoffset@0.9.1
	once_cell@1.20.3
	portable-atomic@1.11.0
	proc-macro2@1.0.93
	pyo3@0.23.5
	pyo3-build-config@0.23.5
	pyo3-ffi@0.23.5
	pyo3-macros@0.23.5
	pyo3-macros-backend@0.23.5
	quote@1.0.38
	ryu@1.0.19
	serde@1.0.218
	serde_derive@1.0.218
	serde_json@1.0.139
	syn@2.0.98
	target-lexicon@0.12.16
	unicode-ident@1.0.17
	unindent@0.2.3
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
