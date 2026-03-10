# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..13} )

inherit python-single-r1 systemd

DESCRIPTION="The most powerful and modular diffusion model GUI and backend"
HOMEPAGE="https://www.comfy.org/"
SRC_URI="https://github.com/Comfy-Org/ComfyUI/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/ComfyUI-${PV}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="rocm cuda migraphx"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		>=dev-python/numpy-1.25.0[${PYTHON_USEDEP}]
		dev-python/einops[${PYTHON_USEDEP}]
		>=dev-python/transformers-5.0.0[${PYTHON_USEDEP}]
		>=dev-python/tokenizers-0.22.0[${PYTHON_USEDEP}]
		>=dev-python/safetensors-0.4.2[${PYTHON_USEDEP}]
		>=dev-python/aiohttp-3.11.8[${PYTHON_USEDEP}]
		>=dev-python/yarl-1.18.0[${PYTHON_USEDEP}]
		dev-python/pyyaml[${PYTHON_USEDEP}]
		dev-python/pillow[${PYTHON_USEDEP}]
		dev-python/scipy[${PYTHON_USEDEP}]
		dev-python/tqdm[${PYTHON_USEDEP}]
		dev-python/psutil[${PYTHON_USEDEP}]
		dev-python/alembic[${PYTHON_USEDEP}]
		dev-python/sqlalchemy[${PYTHON_USEDEP}]
		dev-python/requests[${PYTHON_USEDEP}]
		>=dev-python/av-14.2.0[${PYTHON_USEDEP}]
		>=dev-python/comfy-kitchen-0.2.7[${PYTHON_USEDEP}]
		>=dev-python/kornia-0.7.1[${PYTHON_USEDEP}]
		dev-python/spandrel[${PYTHON_USEDEP}]
		dev-python/soundfile[${PYTHON_USEDEP}]
		dev-python/pydantic[${PYTHON_USEDEP}]
		dev-python/pydantic-settings[${PYTHON_USEDEP}]
		dev-python/pyopengl[${PYTHON_USEDEP}]
		dev-python/glfw[${PYTHON_USEDEP}]
		sci-ml/sentencepiece[${PYTHON_USEDEP}]
		dev-python/torchsde[${PYTHON_USEDEP}]
		~dev-python/comfyui-frontend-package-1.39.19[${PYTHON_USEDEP}]
		~dev-python/comfyui-workflow-templates-0.9.10[${PYTHON_USEDEP}]
		~dev-python/comfyui-embedded-docs-0.4.3[${PYTHON_USEDEP}]
	')
	sci-ml/pytorch[${PYTHON_SINGLE_USEDEP}]
	sci-ml/torchvision[${PYTHON_SINGLE_USEDEP}]
	rocm? ( sci-ml/torchvision[rocm] )
	cuda? ( sci-ml/torchvision[cuda] )
	cuda? ( $(python_gen_cond_dep '>=dev-python/comfy-aimdo-0.2.7[${PYTHON_USEDEP}]') )
	migraphx? ( dev-libs/migraphx[python] )
"

DEPEND="${RDEPEND}"

src_compile() {
	:
}

src_install() {
	local instdir="/usr/share/${PN}"

	insinto "${instdir}"
	doins -r comfy comfy_api comfy_api_nodes comfy_config comfy_execution comfy_extras
	doins -r api_server app blueprints middleware utils alembic_db
	doins *.py alembic.ini extra_model_paths.yaml.example requirements.txt

	# comfy_aimdo is imported unconditionally but requires CUDA to build.
	# Install a no-op stub so imports succeed on non-CUDA systems.
	if ! use cuda; then
		insinto "${instdir}/comfy_aimdo"
		doins "${FILESDIR}"/comfy_aimdo_stub/*.py
	fi

	insinto "${instdir}/models"
	doins -r models/.

	insinto "${instdir}/input"
	doins -r input/.

	# Launcher script
	cat > "${T}"/comfyui <<-EOF
		#!/bin/bash
		export PYTHONPATH="/usr/share/${PN}\${PYTHONPATH:+:\$PYTHONPATH}"
		export PYTHONDONTWRITEBYTECODE=1
		cd "/usr/share/${PN}"
		exec ${PYTHON} main.py "\$@"
	EOF
	dobin "${T}"/comfyui

	systemd_dounit "${FILESDIR}"/comfyui.service
	systemd_newuserunit "${FILESDIR}"/comfyui.user.service comfyui.service
}

pkg_postinst() {
	elog "ComfyUI has been installed."
	elog "You can run ComfyUI with: comfyui"
	elog ""
	elog "Systemd services are provided:"
	elog "  System:  systemctl enable --now comfyui"
	elog "           State in /var/lib/comfyui"
	elog "  User:    systemctl --user enable --now comfyui"
	elog "           State in ~/.local/state/comfyui"
	elog ""
	elog "For standalone use, pass --base-directory to set writable paths:"
	elog "  comfyui --base-directory ~/comfyui-data"
	elog ""
	if use rocm; then
		elog "ROCm support enabled via sci-ml/pytorch[rocm]."
	fi
	if use migraphx; then
		elog "MIGraphX support enabled."
	fi
}
