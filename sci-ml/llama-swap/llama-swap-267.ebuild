# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Hot-swap between multiple local AI model servers on demand"
HOMEPAGE="https://github.com/mostlygeek/llama-swap"
SRC_URI="
	https://github.com/mostlygeek/llama-swap/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/bennypowers/gentoo-overlay/releases/download/${PN}/${PN}-${PV}-deps.tar.xz
	https://github.com/bennypowers/gentoo-overlay/releases/download/${PN}/${PN}-${PV}-ui-node-modules.tar.xz
"

# Tarball generation: .larry/prepare.sh handles the go vendor tree and the
# UI node_modules. Run it after bumping the version.

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="
	>=dev-lang/go-1.27.3
	>=net-libs/nodejs-20.19
"

src_compile() {
	# Build the Svelte UI into internal/server/ui_dist for the `embed_ui`
	# build tag. node_modules is vendored as a tarball, so no npm install
	# (and no network) is needed.
	(
		cd ui || die
		./node_modules/.bin/vite build --emptyOutDir || die "vite build failed"
	) || die "UI build failed"

	# Copy the Go and TypeScript source, without tests, into
	# internal/mcptools/sourcecode/_src for the `embed_src` build tag
	# (the upstream Makefile `src` target, minus git). node_modules and
	# vendor are gitignored upstream, so prune them here.
	local srcdir=internal/mcptools/sourcecode/_src
	rm -rf "${srcdir}" || die
	mkdir -p "${srcdir}" || die
	find . \( -path './ui/node_modules' -o -path './vendor' \) -prune -o \
		\( -name '*.go' ! -name '*_test.go' -o \
			\( -path './ui/*' \( -name '*.ts' ! -name '*.test.ts' -o -name '*.svelte' \) \) \
		\) -print0 \
		| tar --null -T - -cf - \
		| tar -xf - -C "${srcdir}" || die
	[ -n "$(find "${srcdir}" -type f -print -quit)" ] || die "no source copied into ${srcdir}"

	# Pure Go build (modernc.org/sqlite), no cgo.
	local -x CGO_ENABLED=0
	ego build -tags embed_ui,embed_src -trimpath \
		-ldflags="-X main.version=v${PV} -extldflags '${LDFLAGS}'" \
		-o build/llama-swap . || die
}

src_install() {
	dobin build/llama-swap

	insinto /etc/llama-swap
	newins config.example.yaml config.example.yaml

	einstalldocs README.md
}

pkg_postinst() {
	elog "Create a config file from /etc/llama-swap/config.example.yaml,"
	elog "then start with:"
	elog "  llama-swap -config /etc/llama-swap/config.yaml"
	elog ""
	elog "The proxy itself is dependency-free; it just manages the model"
	elog "servers (llama-server, vllm, etc.) you point it at in the config."
}
