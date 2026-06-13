# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
#
# Optional extras not yet packagable:
#   rag, ui: faiss-cpu, pymupdf, sentence-transformers (no ebuild anywhere)
#   api, mcp: fastapi, mcp (::guru only)

EAPI=8

DISTUTILS_SINGLE_IMPL=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..13} )

inherit distutils-r1

DESCRIPTION="AMD Gaia - AI agent framework"
HOMEPAGE="https://github.com/amd/gaia"
SRC_URI="https://github.com/amd/gaia/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="api mcp rag ui"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/aiohttp[${PYTHON_USEDEP}]
		dev-python/openai[${PYTHON_USEDEP}]
		dev-python/pillow[${PYTHON_USEDEP}]
		dev-python/pydantic[${PYTHON_USEDEP}]
		dev-python/python-dotenv[${PYTHON_USEDEP}]
		dev-python/requests[${PYTHON_USEDEP}]
		dev-python/rich[${PYTHON_USEDEP}]
		dev-python/watchdog[${PYTHON_USEDEP}]
	')
	sci-ml/transformers[${PYTHON_SINGLE_USEDEP}]
	sci-ml/accelerate[${PYTHON_SINGLE_USEDEP}]
	api? (
		$(python_gen_cond_dep '
			dev-python/python-multipart[${PYTHON_USEDEP}]
			dev-python/uvicorn[${PYTHON_USEDEP}]
		')
	)
	mcp? (
		$(python_gen_cond_dep '
			dev-python/starlette[${PYTHON_USEDEP}]
			dev-python/uvicorn[${PYTHON_USEDEP}]
		')
	)
	rag? (
		$(python_gen_cond_dep '
			dev-python/numpy[${PYTHON_USEDEP}]
			dev-python/pypdf[${PYTHON_USEDEP}]
		')
	)
	ui? (
		$(python_gen_cond_dep '
			dev-python/httpx[${PYTHON_USEDEP}]
			dev-python/keyring[${PYTHON_USEDEP}]
			dev-python/psutil[${PYTHON_USEDEP}]
			sci-ml/safetensors[${PYTHON_USEDEP}]
		')
		sci-ml/pytorch[${PYTHON_SINGLE_USEDEP}]
	)
"
