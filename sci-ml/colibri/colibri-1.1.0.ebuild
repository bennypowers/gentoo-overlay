# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )

inherit python-single-r1 toolchain-funcs

DESCRIPTION="Run GLM-5.2 (744B MoE) on consumer hardware with expert streaming"
HOMEPAGE="https://github.com/JustVugg/colibri"
SRC_URI="https://github.com/JustVugg/colibri/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="bench cuda +python rocm"
REQUIRED_USE="
	python? ( ${PYTHON_REQUIRED_USE} )
	bench? ( python )
	?? ( cuda rocm )
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
	cuda? ( dev-util/nvidia-cuda-toolkit )
	rocm? ( dev-libs/hip-runtime-amd )
"
DEPEND="${RDEPEND}"
BDEPEND="
	cuda? ( dev-util/nvidia-cuda-toolkit )
	rocm? ( dev-util/hip )
"

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_compile() {
	local mycflags="${CFLAGS} -fopenmp -pthread"
	local myldflags="${LDFLAGS} -fopenmp -pthread -lm -ldl"
	local makeargs=(
		CC="$(tc-getCC)"
	)

	if use cuda; then
		mycflags+=" -DCOLI_CUDA"
		myldflags+=" -L/opt/cuda/lib64 -Wl,-rpath,/opt/cuda/lib64 -lcudart -lstdc++"
		makeargs+=( CUDA=1 CUDA_HOME=/opt/cuda )
	elif use rocm; then
		mycflags+=" -DCOLI_CUDA"
		myldflags+=" -lamdhip64 -lstdc++"
		makeargs+=( HIP=1 ROCM_HOME=/usr )
	fi

	emake -C c colibri \
		"${makeargs[@]}" \
		CFLAGS="${mycflags}" \
		LDFLAGS="${myldflags}"
}

src_install() {
	exeinto /usr/libexec/${PN}
	doexe c/colibri

	if use python; then
		python_fix_shebang c/coli
		dobin c/coli

		insinto /usr/libexec/${PN}/tools
		doins c/tools/*.py

		insinto /usr/libexec/${PN}
		doins c/openai_server.py c/resource_plan.py c/doctor.py
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
	elog ""
	elog "Context length defaults to 4096. Coding clients and tool-calling"
	elog "need larger contexts: CTX=32768 coli serve"
	if use cuda; then
		elog ""
		elog "CUDA GPU offloading enabled. Set CUDA_EXPERT_GB to control"
		elog "how many GB of experts to keep resident in GPU VRAM."
	fi
	if use rocm; then
		elog ""
		elog "ROCm/HIP GPU offloading enabled. Set CUDA_EXPERT_GB to control"
		elog "how many GB of experts to keep resident in GPU VRAM."
	fi
}
