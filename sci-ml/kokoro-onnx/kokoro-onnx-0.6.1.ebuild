# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..13} )
DISTUTILS_USE_PEP517=hatchling

inherit distutils-r1 pypi

DESCRIPTION="TTS with kokoro and ONNX runtime"
HOMEPAGE="https://github.com/thewh1teagle/kokoro-onnx"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	app-accessibility/espeak-ng
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/phonemizer-fork[${PYTHON_USEDEP}]
	sci-libs/onnxruntime[python]
"
DEPEND="${RDEPEND}"

PATCHES=(
	"${FILESDIR}/${P}-system-espeak.patch"
)

src_prepare() {
	distutils-r1_src_prepare

	# Remove bundled espeak-ng loader dep; we use system espeak-ng
	sed -i '/"espeakng-loader/d' pyproject.toml || die
}

pkg_postinst() {
	elog "kokoro-onnx requires model files to run."
	elog "Download them from the GitHub release:"
	elog ""
	elog "  wget https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx"
	elog "  wget https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin"
	elog ""
	elog "Or via huggingface_hub:"
	elog "  huggingface-cli download hexgrad/Kokoro-82M"
	elog ""
	elog "For GPU acceleration with ROCm, set:"
	elog "  export ONNX_PROVIDER=MIGraphXExecutionProvider"
}
