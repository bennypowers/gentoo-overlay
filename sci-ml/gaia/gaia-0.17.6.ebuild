# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
#
# TODO: optional extras require packages not in any repo:
#   rag: faiss-cpu, pymupdf, sentence-transformers (nowhere)
#   ui: also needs faiss-cpu, pymupdf, sentence-transformers (nowhere)
#   api: also needs dev-python/fastapi (::guru only)
#   mcp: also needs dev-python/mcp (::guru only)

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..13} )

inherit distutils-r1

DESCRIPTION="AMD Gaia - AI agent framework"
HOMEPAGE="https://github.com/amd/gaia"
SRC_URI="https://github.com/amd/gaia/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
IUSE="api mcp rag ui"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/aiohttp[${PYTHON_USEDEP}]
	dev-python/openai[${PYTHON_USEDEP}]
	dev-python/pydantic[${PYTHON_USEDEP}]
	dev-python/python-dotenv[${PYTHON_USEDEP}]
	dev-python/rich[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
	dev-python/watchdog[${PYTHON_USEDEP}]
	dev-python/pillow[${PYTHON_USEDEP}]
	$(python_gen_cond_dep '
		sci-ml/accelerate[${PYTHON_SINGLE_USEDEP}]
	')
	dev-python/transformers[${PYTHON_USEDEP}]
	api? (
		# dev-python/fastapi (::guru only — TODO)
		dev-python/uvicorn[${PYTHON_USEDEP}]
		dev-python/python-multipart[${PYTHON_USEDEP}]
	)
	mcp? (
		# dev-python/mcp (::guru only — TODO)
		dev-python/starlette[${PYTHON_USEDEP}]
		dev-python/uvicorn[${PYTHON_USEDEP}]
	)
	rag? (
		# faiss-cpu, pymupdf, sentence-transformers (nowhere — TODO)
		dev-python/numpy[${PYTHON_USEDEP}]
		dev-python/pypdf[${PYTHON_USEDEP}]
	)
	ui? (
		# api deps: fastapi (::guru)
		dev-python/httpx[${PYTHON_USEDEP}]
		dev-python/psutil[${PYTHON_USEDEP}]
		dev-python/keyring[${PYTHON_USEDEP}]
		# rag deps: faiss-cpu, pymupdf, sentence-transformers (nowhere — TODO)
		dev-python/safetensors[${PYTHON_USEDEP}]
		$(python_gen_cond_dep '
			sci-ml/torch[${PYTHON_SINGLE_USEDEP}]
		')
	)
"
