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

src_install() {
	# Install the app directory as-is to preserve the original structure
	python_domodule app
	
	# Create a simple wrapper script that runs the app in its original form
	cat > "${T}/nmgui" << EOF
#!/usr/bin/env python3
import sys
import os

# Add the installation directory to Python path
sys.path.insert(0, '${EPREFIX}/usr/lib/${EPYTHON}/site-packages')

# Change to a temp directory to avoid import conflicts
import tempfile
with tempfile.TemporaryDirectory() as tmpdir:
    os.chdir(tmpdir)
    
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
	
	# Install desktop file if it exists
	if [[ -f nmgui.desktop ]]; then
		domenu nmgui.desktop
	fi
}

pkg_postinst() {
	elog "nmgui requires NetworkManager to be running to function properly."
	elog "Make sure you have NetworkManager enabled:"
	elog "  rc-update add NetworkManager default"
	elog "  systemctl enable NetworkManager"
}