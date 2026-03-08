# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..13} )

inherit distutils-r1

DESCRIPTION="PyTorch architecture support for AI Super-Resolution and restoration"
HOMEPAGE="https://github.com/chaiNNer-org/spandrel"
SRC_URI="https://github.com/chaiNNer-org/spandrel/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	sci-ml/pytorch[${PYTHON_USEDEP}]
	sci-ml/torchvision[${PYTHON_USEDEP}]
	dev-python/safetensors[${PYTHON_USEDEP}]
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/einops[${PYTHON_USEDEP}]
	dev-python/typing-extensions[${PYTHON_USEDEP}]
"

DEPEND="${RDEPEND}"
