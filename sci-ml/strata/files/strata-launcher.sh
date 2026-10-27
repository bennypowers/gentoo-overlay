#!/bin/sh
# Gentoo launcher for the Strata terminal (sci-ml/strata).
#
# The engine component package installed by the ebuild lives in the system component folder.
# STRATA_COMPONENTS_DIR is only a default: a user who wants a per-user engine folder (for example to
# run `strata update`) can export their own value.
#
# Run configs and models go to the calling user's XDG data folder. Without STRATA_INSTALL_DIR,
# Strata defaults to <components>/../install, which is root-owned under /usr/lib/strata.
# Portage owns this package; `strata install`/`strata update` are not supported here. If you need
# them, override STRATA_INSTALL_DIR=/usr/lib/strata and run with the required permissions.
set -eu

: "${STRATA_COMPONENTS_DIR:=/usr/lib/strata/components}"
: "${XDG_DATA_HOME:=${HOME}/.local/share}"
: "${STRATA_INSTALL_DIR:=${XDG_DATA_HOME}/strata}"
: "${STRATA_DATA_DIR:=${XDG_DATA_HOME}/strata}"
# Mark the install as portage-managed. The ebuild patches strata_cli to honor this: with it set,
# `strata install` and `strata update` (incl. --check) are refused and point at portage, and
# `strata components rollback`/`install-file` need a user-owned --components-dir. To self-manage
# the engine, set STRATA_PACKAGE_MANAGED=0 and point STRATA_COMPONENTS_DIR at a per-user folder.
: "${STRATA_PACKAGE_MANAGED:=1}"
export STRATA_COMPONENTS_DIR STRATA_INSTALL_DIR STRATA_DATA_DIR STRATA_PACKAGE_MANAGED

exec python3 /usr/lib/strata/strata.py "$@"
