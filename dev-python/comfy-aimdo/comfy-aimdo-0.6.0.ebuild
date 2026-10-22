# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..14} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1 toolchain-funcs

DESCRIPTION="AI Model Dynamic Offloader for ComfyUI"
HOMEPAGE="https://github.com/Comfy-Org/comfy-aimdo"
SRC_URI="https://github.com/Comfy-Org/comfy-aimdo/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="cuda rocm"
# No REQUIRED_USE: a no-flag build installs the python package only, with
# no native library. ComfyUI detects the missing library at runtime and
# falls back to the legacy ModelPatcher.

# The native library is linkless: driver APIs are duck-typed in src/gpu_abi.h
# and resolved with dlopen at runtime, so neither an NVIDIA nor an AMD SDK is
# needed at build time. funchook is required for the CUDA allocator hooks.
DEPEND="dev-libs/funchook:="
RDEPEND="${DEPEND}"

BDEPEND="dev-python/setuptools-scm[${PYTHON_USEDEP}]"

export SETUPTOOLS_SCM_PRETEND_VERSION="${PV}"

src_compile() {
	# Mirror scripts/build-linux-aimdo.sh from the upstream tarball
	if use cuda; then
		$(tc-getCC) -shared -fPIC -pthread -DAIMDO_CUDA \
			${CFLAGS} \
			src/*.c src-cuda/dispatch.c src-posix/*.c -Isrc \
			${LDFLAGS} -lfunchook -ldl \
			-o comfy_aimdo/aimdo.so || die "failed to compile aimdo.so"
	fi

	if use rocm; then
		$(tc-getCC) -shared -fPIC -pthread -D__HIP_PLATFORM_AMD__ \
			${CFLAGS} \
			src/*.c src-hip/dispatch.c src-posix/*.c -Isrc \
			${LDFLAGS} -lfunchook -ldl \
			-o comfy_aimdo/aimdo_rocm.so || die "failed to compile aimdo_rocm.so"
	fi

	distutils-r1_src_compile
}
