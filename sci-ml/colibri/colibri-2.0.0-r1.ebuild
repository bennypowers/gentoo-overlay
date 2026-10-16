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
IUSE="bench cuda +python rocm vulkan"
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
		$(python_gen_cond_dep '
			sci-ml/safetensors[${PYTHON_USEDEP}]
			dev-python/numpy[${PYTHON_USEDEP}]
			sci-ml/tokenizers[${PYTHON_USEDEP}]
		')
		bench? (
			sci-ml/datasets[${PYTHON_SINGLE_USEDEP}]
		)
	)
	cuda? ( dev-util/nvidia-cuda-toolkit )
	rocm? ( dev-util/hip )
	vulkan? ( media-libs/vulkan-loader )
"
DEPEND="${RDEPEND}"
BDEPEND="
	cuda? ( dev-util/nvidia-cuda-toolkit )
	rocm? ( dev-util/hip )
	vulkan? (
		dev-util/vulkan-headers
		media-libs/shaderc
	)
"

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_prepare() {
	default
	# The release tarball ships prebuilt SPIR-V; rebuild from .comp with the
	# system glslc so VK=1 binaries run our own shaders, not upstream's.
	find c/shaders -name '*.spv' -delete || die
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

	if use vulkan; then
		# Independent of CUDA/HIP: any Vulkan 1.2 driver (Mesa/RADV, NVK, ...).
		# Nothing links the loader at build time; backend_vulkan.c dlopens it.
		makeargs+=( VK=1 )
	fi

	# The `colibri` alias exists only where EXE is non-empty (Windows); on
	# POSIX the real target is `glm`.
	emake -C c glm \
		"${makeargs[@]}" \
		CFLAGS="${mycflags}" \
		LDFLAGS="${myldflags}"
}

src_install() {
	exeinto /usr/libexec/${PN}
	doexe c/colibri

	if use vulkan; then
		# backend_vulkan.c looks for shaders/ next to the binary
		# (COLI_VK_SHADERS can override).
		insinto /usr/libexec/${PN}/shaders
		doins c/shaders/*.spv
	fi

	if use python; then
		python_fix_shebang c/coli
		dobin c/coli

		insinto /usr/libexec/${PN}/tools
		doins c/tools/*.py
		doins c/tools/iq3xxs_grid.json

		insinto /usr/libexec/${PN}
		doins c/*.py
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
	if use vulkan; then
		elog ""
		elog "Vulkan expert tier enabled (any Vulkan 1.2 driver, also on"
		elog "GPUs ROCm does not support). COLI_VK_SHADERS overrides the"
		elog "shader directory."
	fi
}
