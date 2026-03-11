# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..13} )
PYPI_PN="${PN/-/_}"

inherit distutils-r1 pypi

DESCRIPTION="ONNX IR - Python intermediate representation for ONNX"
HOMEPAGE="https://github.com/onnx/ir-py"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/numpy[${PYTHON_USEDEP}]
	>=dev-python/onnx-1.16[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-4.10[${PYTHON_USEDEP}]
	>=dev-python/ml-dtypes-0.5.0[${PYTHON_USEDEP}]
	>=dev-python/sympy-1.13[${PYTHON_USEDEP}]
"
