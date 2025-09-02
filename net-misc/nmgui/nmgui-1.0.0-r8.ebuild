# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )

inherit python-single-r1

DESCRIPTION="A simple, lightweight GTK4-based GUI for NetworkManager using nmcli"
HOMEPAGE="https://github.com/s-adi-dev/nmgui"
SRC_URI="https://github.com/s-adi-dev/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/pygobject[${PYTHON_USEDEP}]
		dev-python/python-nmcli[${PYTHON_USEDEP}]
	')
	gui-libs/gtk:4
	net-misc/networkmanager
"

RDEPEND="${DEPEND}"

src_prepare() {
	default
	
	# Fix all relative imports to absolute imports
	find app -name "*.py" -exec sed -i \
		-e 's/^from network_service import/from app.network_service import/g' \
		-e 's/^from models import/from app.models import/g' \
		-e 's/^from ui\./from app.ui./g' \
		-e 's/^import ui\./import app.ui./g' \
		-e 's/^import models$/import app.models/g' \
		-e 's/^import network_service$/import app.network_service/g' \
		{} \;
	
	# Create __init__.py files to make it a proper Python package
	touch app/__init__.py
	find app -type d -exec touch {}/__init__.py \;
}

src_install() {
	# Install the app directory as a Python module
	python_domodule app
	
	# Create a wrapper script
	cat > "${T}/nmgui" << EOF
#!/usr/bin/env python3
import sys
import os

# Add the installation directory to Python path
sys.path.insert(0, '${EPREFIX}/usr/lib/${EPYTHON}/site-packages')

try:
	# Import and run the app
	from app.main import parse_arguments, NetworkManagerApp
	import gi
	gi.require_version('Gtk', '4.0')
	from gi.repository import Gtk, GLib
	import nmcli
	
	# Run the main logic
	args = parse_arguments()
	
	if not nmcli.connection():
		print("NetworkManager is not running. Please start NetworkManager and try again.")
		sys.exit(1)
	
	app = NetworkManagerApp()
	try:
		exit_code = app.run(sys.argv)
		sys.exit(exit_code)
	except KeyboardInterrupt:
		print("\\nApplication interrupted by user.")
		sys.exit(0)
	except SystemExit:
		sys.exit(0)
except Exception as e:
	print(f"Error running nmgui: {e}")
	import traceback
	traceback.print_exc()
	sys.exit(1)
EOF
	
	python_doscript "${T}/nmgui"
	
	# Create and install desktop file
	cat > "${T}/nmgui.desktop" << EOF
[Desktop Entry]
Name=Network Manager GUI
Comment=A simple, lightweight GTK4-based GUI for NetworkManager
Exec=nmgui
Icon=network-manager
Terminal=false
Type=Application
Categories=Network;System;Settings;
Keywords=network;wifi;ethernet;connection;manager;
StartupNotify=true
EOF
	
	domenu "${T}/nmgui.desktop"
}

pkg_postinst() {
	elog "nmgui requires NetworkManager to be running to function properly."
	elog "Make sure you have NetworkManager enabled:"
	elog "  rc-update add NetworkManager default"
	elog "  systemctl enable NetworkManager"
}