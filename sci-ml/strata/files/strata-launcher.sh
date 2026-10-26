#!/bin/sh
# Gentoo launcher for the Strata terminal (sci-ml/strata).
#
# The engine component package installed by the ebuild lives in the system component folder.
# STRATA_COMPONENTS_DIR is only a default: a user who wants a per-user engine folder (for example to
# run `strata update`) can export their own value.
set -eu

: "${STRATA_COMPONENTS_DIR:=/usr/lib/strata/components}"
export STRATA_COMPONENTS_DIR

exec python3 /usr/lib/strata/strata.py "$@"
