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
IUSE="+python"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

RDEPEND="
	python? (
		${PYTHON_DEPS}
		sci-ml/pytorch[${PYTHON_SINGLE_USEDEP}]
		sci-ml/huggingface_hub[${PYTHON_SINGLE_USEDEP}]
		$(python_gen_cond_dep '
			sci-ml/safetensors[${PYTHON_USEDEP}]
			dev-python/numpy[${PYTHON_USEDEP}]
		')
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
	dobin c/glm

	if use python; then
		python_fix_shebang c/coli
		dobin c/coli

		insinto /usr/share/${PN}/tools
		doins c/tools/*.py

		insinto /usr/share/${PN}
		doins c/openai_server.py
	fi

	dodoc README.md
}

pkg_postinst() {
	elog "Pre-converted int4 weights available at:"
	elog "  https://huggingface.co/jlnsrk/GLM-5.2-colibri-int4"
	elog ""
	elog "Alternatively, convert from FP8: coli convert"
	elog ""
	elog "Requires ~370GB disk and >=16GB RAM for the int4 model."
}
