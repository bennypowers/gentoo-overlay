# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..13} )

inherit distutils-r1

DESCRIPTION="State-of-the-art Machine Learning for PyTorch, TensorFlow, and JAX"
HOMEPAGE="https://github.com/huggingface/transformers"
SRC_URI="https://github.com/huggingface/transformers/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/filelock[${PYTHON_USEDEP}]
	>=dev-python/huggingface-hub-1.3.0[${PYTHON_USEDEP}]
	>=dev-python/numpy-1.17[${PYTHON_USEDEP}]
	>=dev-python/packaging-20.0[${PYTHON_USEDEP}]
	>=dev-python/pyyaml-5.1[${PYTHON_USEDEP}]
	dev-python/regex[${PYTHON_USEDEP}]
	>=dev-python/tokenizers-0.22.0[${PYTHON_USEDEP}]
	dev-python/typer[${PYTHON_USEDEP}]
	>=dev-python/safetensors-0.4.3[${PYTHON_USEDEP}]
	>=dev-python/tqdm-4.27[${PYTHON_USEDEP}]
"

DEPEND="${RDEPEND}"
