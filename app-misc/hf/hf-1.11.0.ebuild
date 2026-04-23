# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..13} )

inherit distutils-r1 pypi

DESCRIPTION="CLI for the Hugging Face Hub"
HOMEPAGE="https://github.com/huggingface/huggingface_hub"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="=dev-python/huggingface-hub-${PV}[${PYTHON_USEDEP}]"

src_prepare() {
	# setup.py tries to read version from the monorepo's huggingface_hub source
	sed -i '/^def get_version/,/^$/c\def get_version() -> str:\n    return "'"${PV}"'"' setup.py || die
	distutils-r1_src_prepare
}
