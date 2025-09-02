# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} )

inherit distutils-r1

DESCRIPTION="A simple, lightweight GTK4-based GUI for NetworkManager using nmcli"
HOMEPAGE="https://github.com/s-adi-dev/nmgui"
SRC_URI="https://github.com/s-adi-dev/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="
	>=dev-lang/python-3.10
	dev-python/pygobject[${PYTHON_USEDEP}]
	gui-libs/gtk:4
	net-misc/networkmanager
"

RDEPEND="${DEPEND}
	dev-python/python-nmcli[${PYTHON_USEDEP}]
"

BDEPEND="
	dev-python/setuptools[${PYTHON_USEDEP}]
"

src_prepare() {
	default
	
	# Fix all relative imports to use absolute imports from the app package
	find app -name "*.py" -exec sed -i 's/^from network_service import/from app.network_service import/g' {} \;
	find app -name "*.py" -exec sed -i 's/^from models import/from app.models import/g' {} \;
	find app -name "*.py" -exec sed -i 's/^from ui\./from app.ui./g' {} \;
	find app -name "*.py" -exec sed -i 's/^import ui\./import app.ui./g' {} \;
	find app -name "*.py" -exec sed -i 's/^import models/import app.models/g' {} \;
	find app -name "*.py" -exec sed -i 's/^import network_service/import app.network_service/g' {} \;
	
	# Create a proper setup.py
	cat > setup.py << EOF
from setuptools import setup, find_packages

setup(
    name="nmgui",
    version="${PV}",
    packages=find_packages(),
    package_data={
        "app": ["*.py"],
        "app.ui": ["*.py", "*.ui", "*.glade", "*.xml"],
    },
    entry_points={
        "console_scripts": [
            "nmgui=app.main:main",
        ],
    },
    install_requires=[
        "pygobject",
        "nmcli",
    ],
)
EOF

	# Create __init__.py files
	touch app/__init__.py
	touch app/ui/__init__.py
}

src_install() {
	distutils-r1_src_install
	
	# Install desktop file if it exists
	if [[ -f "${S}/nmgui.desktop" ]]; then
		domenu "${S}/nmgui.desktop"
	fi
}

pkg_postinst() {
	elog "nmgui requires NetworkManager to be running to function properly."
	elog "Make sure you have NetworkManager enabled:"
	elog "  rc-update add NetworkManager default"
	elog "  systemctl enable NetworkManager"
}