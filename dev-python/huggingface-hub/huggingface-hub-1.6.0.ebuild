# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..13} )

inherit distutils-r1

MY_PN="huggingface_hub"

DESCRIPTION="Client library for the Hugging Face Hub"
HOMEPAGE="https://github.com/huggingface/huggingface_hub"
SRC_URI="https://github.com/huggingface/huggingface_hub/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${MY_PN}-${PV}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/filelock-3.10.0[${PYTHON_USEDEP}]
	>=dev-python/fsspec-2023.5.0[${PYTHON_USEDEP}]
	>=dev-python/httpx-0.23.0[${PYTHON_USEDEP}]
	>=dev-python/packaging-20.9[${PYTHON_USEDEP}]
	>=dev-python/pyyaml-5.1[${PYTHON_USEDEP}]
	>=dev-python/tqdm-4.42.1[${PYTHON_USEDEP}]
	dev-python/typer[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-4.1.0[${PYTHON_USEDEP}]
	>=dev-python/hf-xet-1.3.2[${PYTHON_USEDEP}]
"

DEPEND="${RDEPEND}"
