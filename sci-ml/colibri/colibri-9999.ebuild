# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )

inherit git-r3 python-single-r1 toolchain-funcs

DESCRIPTION="Run GLM-5.2 (744B MoE) on consumer hardware with expert streaming"
HOMEPAGE="https://github.com/JustVugg/colibri"
EGIT_REPO_URI="https://github.com/JustVugg/colibri.git"

LICENSE="Apache-2.0"
SLOT="0"
IUSE="bench +python"
REQUIRED_USE="
	python? ( ${PYTHON_REQUIRED_USE} )
	bench? ( python )
"

RDEPEND="
	python? (
		${PYTHON_DEPS}
		sci-ml/pytorch[${PYTHON_SINGLE_USEDEP}]
		sci-ml/huggingface_hub[${PYTHON_SINGLE_USEDEP}]
		sci-ml/tokenizers[${PYTHON_SINGLE_USEDEP}]
		$(python_gen_cond_dep '
			sci-ml/safetensors[${PYTHON_USEDEP}]
			dev-python/numpy[${PYTHON_USEDEP}]
		')
		bench? (
			sci-ml/datasets[${PYTHON_SINGLE_USEDEP}]
		)
	)
"
DEPEND="${RDEPEND}"

pkg_setup() {
	use python && python-single-r1_pkg_setup
}


src_compile() {
	emake -C c glm \
		CC="$(tc-getCC)" \
		CFLAGS="${CFLAGS} -fopenmp" \
		LDFLAGS="${LDFLAGS} -fopenmp -lm -lpthread -ldl"
}

src_install() {
	# Install engine + tools to libexec, matching upstream's installed layout
	# (coli resolves ../libexec/colibri/ relative to its own bin/ location)
	exeinto /usr/libexec/${PN}
	doexe c/glm

	if use python; then
		python_fix_shebang c/coli
		dobin c/coli

		insinto /usr/libexec/${PN}/tools
		doins c/tools/*.py

		insinto /usr/libexec/${PN}
		doins c/openai_server.py
	fi

	dodoc README.md
}

pkg_postinst() {
	elog "Pre-converted int4 weights (with int8 MTP for speculative decoding):"
	elog "  huggingface-cli download mateogrgic/GLM-5.2-colibri-int4-with-int8-mtp"
	elog ""
	elog "Then set COLI_MODEL to the HuggingFace snapshot directory, e.g.:"
	elog "  export COLI_MODEL=~/.cache/huggingface/hub/models--mateogrgic--GLM-5.2-colibri-int4-with-int8-mtp/snapshots/<hash>"
	elog ""
	elog "Alternatively, convert from FP8: coli convert"
	elog ""
	elog "Requires ~370GB disk and >=16GB RAM for the int4 model."
}
