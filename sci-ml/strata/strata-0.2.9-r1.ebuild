# Copyright 2026 Benny Powers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_SKIP_GLOBALS=1
# upstream builds the engine with CMAKE_BUILD_TYPE=Release (-O3, no -g); RelWithDebInfo (the eclass default)
# would halve the speed flags and double the installed size of a binary that portage cannot strip.
CMAKE_BUILD_TYPE=Release
inherit cmake multiprocessing rocm

# llama.cpp is taken from a pinned commit, not from a release: Strata builds its own prompt kernels and the
# ggml CPU experts from that exact tree (third_party/ggml/VERSION.txt upstream).
LLAMA_COMMIT="3cf03257f219afbe7334045ff7c6a06ac68c627d"
LLAMA_P="llama.cpp-${LLAMA_COMMIT}"

DESCRIPTION="Local inference engine and terminal for Qwen3.8-Flash-Next"
HOMEPAGE="https://github.com/Niko1221/Strata"
SRC_URI="
	https://github.com/Niko1221/Strata/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/ggml-org/llama.cpp/archive/${LLAMA_COMMIT}.tar.gz -> ${LLAMA_P}.tar.gz
"
S="${WORKDIR}/Strata-${PV}"
LLAMA_S="${WORKDIR}/${LLAMA_P}"

# tools/vision is a CMake project of its own: the engine build does not add it, and upstream ships both readers in
# its Linux HIP package (the portable CPU one, plus the HIP one for the packaged gfx targets).
VISION_S="${S}/tools/vision"
VISION_BUILD="${WORKDIR}/vision-build"
VISION_HIP_BUILD="${WORKDIR}/vision-hip-build"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# Strata's HIP backend refuses architectures it does not know (cmake/hip_backend.cmake); keep this list in sync.
IUSE_TARGETS=(
	gfx1010 gfx1011 gfx1012
	gfx1030 gfx1031 gfx1032 gfx1034
	gfx1100 gfx1101 gfx1102 gfx1103
	gfx1150 gfx1151 gfx1152 gfx1153
	gfx1200 gfx1201
)
IUSE_TARGETS=( "${IUSE_TARGETS[@]/#/amdgpu_targets_}" )
ROCM_USEDEP_OPTFLAGS=${IUSE_TARGETS[*]/%/(-)?}
ROCM_USEDEP=${ROCM_USEDEP_OPTFLAGS// /,}
ROCM_REQUIRED_USE=" || ( ${IUSE_TARGETS[*]} )"

IUSE="+vision ${IUSE_TARGETS[*]}"
REQUIRED_USE="${ROCM_REQUIRED_USE}"

# The engine component manifest records the SHA-256 of every file and the terminal verifies it at every
# start. Anything that rewrites the binaries after src_install (strip, splitdebug) would break that check.
RESTRICT="strip"

RDEPEND="
	>=dev-lang/python-3.10
	dev-python/jinja2
	dev-python/numpy
	dev-python/pillow
	dev-python/psutil
	dev-python/pyyaml
	dev-python/regex
	dev-python/requests
	dev-python/rich
	dev-python/textual
	dev-python/truststore
	dev-util/hip
	dev-util/rocminfo
	sci-libs/hipBLAS[${ROCM_USEDEP}]
	sci-libs/hipBLASLt[${ROCM_USEDEP}]
	sci-libs/rocBLAS[${ROCM_USEDEP}]
"
DEPEND="${RDEPEND}"
BDEPEND="
	dev-build/cmake
	dev-build/ninja
	>=dev-lang/python-3.10
	sys-devel/binutils
"

src_prepare() {
	cmake_src_prepare

	# Newer ROCm clang changed the gfx11/gfx12 bf16 WMMA builtins to take a short vector; upstream llama.cpp
	# made the same change in mma.cuh. Without it the prompt MMQ kernels do not compile for RDNA.
	pushd "${LLAMA_S}" >/dev/null || die
	eapply "${FILESDIR}/llama-cpp-rdna-bf16-wmma-vector.patch"
	popd >/dev/null || die

	# Under a portage install, portage — not strata's self-updater — owns engine updates. The
	# launcher sets STRATA_PACKAGE_MANAGED=1; this makes the installed strata_cli honor it.
	eapply "${FILESDIR}/strata-portage-managed.patch"
}

engine_version() {
	sed -n 's/^project(strata VERSION \([0-9][0-9.]*\).*/\1/p' "${S}/CMakeLists.txt" | head -n 1
}

src_configure() {
	# hipcc/CMake probe the GPUs unless a target list is given; the build host's cards are not the target's.
	export ROCM_TARGET_LST="${T}/rocm-targets.lst"
	printf '%s\n' "${AMDGPU_TARGETS[@]}" > "${ROCM_TARGET_LST}" || die
	rocm_add_sandbox

	local mycmakeargs=(
		-DSTRATA_ENABLE_CUDA=OFF
		-DSTRATA_ENABLE_HIP=ON
		-DSTRATA_BUILD_TESTS=OFF
		-DSTRATA_PREFILL_MMQ=ON
		# portable (AVX2 baseline) like the upstream release build: the binary is not tied to the build host CPU
		-DSTRATA_PORTABLE=ON
		-DSTRATA_GGML_DIR="${LLAMA_S}"
		-DCMAKE_HIP_ARCHITECTURES="${AMDGPU_TARGETS[*]}"
	)
	cmake_src_configure
}

build_vision_reader() {
	local build_dir=${1}
	shift
	cmake -G Ninja -S "${VISION_S}" -B "${build_dir}" \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLAMA_DIR="${LLAMA_S}" \
		-DSTRATA_PORTABLE=ON \
		"$@" || die
	cmake --build "${build_dir}" --target strata-vision \
		--parallel "$(get_makeopts_jobs)" || die
}

src_compile() {
	# `all` carries the parity and benchmark executables; only the programs the terminal starts are needed.
	cmake_build strata strata-device

	if use vision; then
		local hip_archs
		printf -v hip_archs '%s;' "${AMDGPU_TARGETS[@]}"
		hip_archs=${hip_archs%;}

		# the portable CPU reader: the fallback that needs nothing from the GPU runtime
		build_vision_reader "${VISION_BUILD}" \
			-DSTRATA_VISION_CUDA=OFF \
			-DSTRATA_VISION_HIP=OFF \
			-DSTRATA_VISION_SYCL=OFF
		# the HIP reader for the same gfx targets as the engine
		build_vision_reader "${VISION_HIP_BUILD}" \
			-DSTRATA_VISION_CUDA=OFF \
			-DSTRATA_VISION_HIP=ON \
			-DSTRATA_VISION_HIP_ARCHS="${hip_archs}" \
			-DCMAKE_HIP_ARCHITECTURES="${hip_archs}"
	fi
}

src_install() {
	local engine_pv
	engine_pv=$(engine_version)
	[[ -n ${engine_pv} ]] || die "could not read the engine version from CMakeLists.txt"

	# ---- the terminal (Python application; the engine is a separate component) ----
	insinto /usr/lib/strata
	doins strata.py setup.py requirements.txt requirements-monitor.txt
	doins -r strata_cli strata_control serve tools ref data
	insinto /usr/lib/strata/bench
	doins -r bench/prompts
	insinto /usr/lib/strata/docs
	doins docs/MANAGEMENT_PROTOCOL.md docs/TERMINAL_LAUNCH.md

	# read by strata_cli.version(); the terminal archive ships the engine build number, not the product version
	echo "${engine_pv}" > "${T}/VERSION" || die
	echo "4b9e05a2a806a3fe24f7b2560d98626c37dade35" > "${T}/COMMIT" || die
	insinto /usr/lib/strata
	doins "${T}/VERSION" "${T}/COMMIT"

	exeinto /usr/bin
	newexe "${FILESDIR}/strata-launcher.sh" strata

	# ---- the engine component package the terminal resolves and starts ----
	local stage="${T}/engine-stage"
	mkdir -p "${stage}" || die
	cp "${BUILD_DIR}/strata" "${BUILD_DIR}/strata-device" "${stage}/" || die
	if use vision; then
		cp "${VISION_BUILD}/bin/strata-vision" \
			"${VISION_HIP_BUILD}/bin/strata-vision-hip" "${stage}/" || die
	fi

	local arch_json
	arch_json=$(printf '"%s", ' "${AMDGPU_TARGETS[@]}")
	arch_json=${arch_json%, }
	{
		printf '{\n'
		printf ' "version": "%s",\n' "${engine_pv}"
		printf ' "source": "Gentoo sci-ml/%s",\n' "${PF}"
		printf ' "portable": true,\n'
		if use vision; then
			printf ' "vision": "gpu",\n'
			printf ' "vision_cpu": "strata-vision",\n'
			printf ' "vision_gpu": "strata-vision-hip",\n'
			printf ' "vision_archs": [%s],\n' "${arch_json}"
		fi
		printf ' "archs": [%s]\n' "${arch_json}"
		printf '}\n'
	} > "${stage}/BUILD.json" || die

	# records the system hipBLASLt version (needed by the package check) and copies matching tuning tables, if any
	python3 -I packaging/stage_tuning.py \
		--stage "${stage}" \
		--archs "${AMDGPU_TARGETS[*]}" \
		--rocm "${EPREFIX}/usr" || die

	# The ROCm libraries are provided by the RDEPEND packages, not bundled: name them as system libraries.
	local -a staged_bins=( "${stage}/strata" "${stage}/strata-device" )
	use vision && staged_bins+=( "${stage}/strata-vision" "${stage}/strata-vision-hip" )
	local -a allow=()
	local lib
	for lib in $(readelf -d "${staged_bins[@]}" |
			sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p' | sort -u); do
		case ${lib} in
			libamdhip64.so.*|libhipblas.so.*|libhipblaslt.so.*|librocblas.so.*|libamd_comgr.so.*|libhiprtc.so.*)
				allow+=( --allow-lib "${lib}" )
				;;
		esac
	done

	local -a archargs=()
	local arch
	for arch in "${AMDGPU_TARGETS[@]}"; do
		archargs+=( --arch "${arch}" )
	done

	python3 -I packaging/package_engine.py \
		--src "${stage}" \
		--backend hip \
		--version "${engine_pv}" \
		--platform linux-x86_64 \
		--out "${ED}/usr/lib/strata/components/engine" \
		--build-id "gentoo-${PF}" \
		--include strata-device \
		"${archargs[@]}" "${allow[@]}" || die
}

pkg_postinst() {
	elog "Strata was built for: ${AMDGPU_TARGETS[*]}"
	elog
	elog "Run 'strata launch' to pick and download a model. Models and run configs"
	elog "live in the calling user's ~/.local/share/strata; STRATA_INSTALL_DIR and"
	elog "STRATA_DATA_DIR can point them elsewhere."
	elog
	elog "The engine is a system component under /usr/lib/strata/components, upgraded with"
	elog "portage. 'strata install' and 'strata update' (including --check) are disabled in a"
	elog "portage install and point you back to portage; 'strata components rollback' and"
	elog "'install-file' need a user-owned --components-dir. To self-manage the engine, export"
	elog "STRATA_COMPONENTS_DIR to a per-user folder and set STRATA_PACKAGE_MANAGED=0."
	elog
	if use vision; then
		elog "Pictures are read by the portable CPU reader (strata-vision) or the HIP"
		elog "reader (strata-vision-hip) for: ${AMDGPU_TARGETS[*]}."
	else
		elog "Built with USE=-vision: no picture reader (text-only)."
	fi
}
