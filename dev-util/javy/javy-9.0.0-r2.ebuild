# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.85.0"

inherit cargo

DESCRIPTION="JavaScript to WebAssembly toolchain"
HOMEPAGE="https://github.com/bytecodealliance/javy"
WHAMM_COMMIT="666984d3465ae8b981db2f46a1e38f8b843d02b4"

SRC_URI="
	https://github.com/bytecodealliance/javy/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/saulecabrera/whamm/archive/${WHAMM_COMMIT}.tar.gz -> whamm-${WHAMM_COMMIT::8}.tar.gz
	https://github.com/bennypowers/gentoo-overlay/releases/download/${PN}/${P}-crates.tar.xz
"

LICENSE="Apache-2.0-with-LLVM-exceptions"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 BSD ISC MIT MPL-2.0 Unicode-3.0 ZLIB
	|| ( Apache-2.0 MIT )
"
SLOT="0"
KEYWORDS="~amd64"

# clang is needed for cross-compiling C code to wasm32-wasip1 (QuickJS in
# rquickjs-sys) and for building binaryen C++ via wasm-opt-sys/cxx.
# rust-bin is needed because Gentoo's dev-lang/rust patches the compiler
# identity (adding "(gentoo)"), making prebuilt wasm32-wasip1 stdlib
# ABI-incompatible. rust-bin uses upstream rustc which is compatible.
BDEPEND="
	llvm-core/clang
	dev-lang/rust-bin
"

QA_FLAGS_IGNORED="usr/bin/javy"

# Download wasm32-wasip1 stdlib at build time since the URL depends on
# the installed rust-bin version.
RESTRICT="network-sandbox"

src_unpack() {
	unpack ${P}.tar.gz whamm-${WHAMM_COMMIT::8}.tar.gz
	tar -xf "${DISTDIR}/${P}-crates.tar.xz" -C "${S}" || die

	# Find rust-bin installation and download matching wasm32-wasip1 stdlib.
	# Gentoo's dev-lang/rust cannot use prebuilt wasm targets due to ABI
	# mismatch (the "(gentoo)" compiler identity). rust-bin is upstream
	# rustc and IS compatible with the prebuilt stdlib.
	local rustbin_dir
	rustbin_dir=$(find /opt -maxdepth 1 -name "rust-bin-*" -type d | sort -V | tail -1) \
		|| die "Could not find rust-bin installation"
	[[ -n "${rustbin_dir}" ]] || die "dev-lang/rust-bin not found in /opt"

	local rustbin_ver="${rustbin_dir##*rust-bin-}"
	local rustbin_sysroot="${rustbin_dir}"

	if [[ ! -d "${rustbin_sysroot}/lib/rustlib/wasm32-wasip1" ]]; then
		einfo "Downloading wasm32-wasip1 stdlib for rust-bin ${rustbin_ver}..."
		wget -q "https://static.rust-lang.org/dist/rust-std-${rustbin_ver}-wasm32-wasip1.tar.xz" \
			-O "${T}/rust-std-wasm32-wasip1.tar.xz" \
			|| die "Failed to download wasm32-wasip1 stdlib"
		tar -xf "${T}/rust-std-wasm32-wasip1.tar.xz" -C "${T}" || die
		cp -a "${T}/rust-std-${rustbin_ver}-wasm32-wasip1/rust-std-wasm32-wasip1/lib/rustlib/wasm32-wasip1" \
			"${WORKDIR}/wasm32-wasip1-libs" || die
	else
		cp -a "${rustbin_sysroot}/lib/rustlib/wasm32-wasip1" \
			"${WORKDIR}/wasm32-wasip1-libs" || die
	fi

	# Build a local sysroot overlay using rust-bin as the base, with the
	# downloaded wasm32-wasip1 target added.
	local wasi_sysroot="${WORKDIR}/wasi-sysroot"
	mkdir -p "${wasi_sysroot}/lib/rustlib" || die
	local f
	for f in "${rustbin_sysroot}/lib/rustlib"/*; do
		ln -snf "${f}" "${wasi_sysroot}/lib/rustlib/${f##*/}" || die
	done
	for f in "${rustbin_sysroot}/lib/"*.so; do
		[[ -e "${f}" ]] || continue
		ln -snf "${f}" "${wasi_sysroot}/lib/" || die
	done
	rm -f "${wasi_sysroot}/lib/rustlib/wasm32-wasip1"
	cp -a "${WORKDIR}/wasm32-wasip1-libs" \
		"${wasi_sysroot}/lib/rustlib/wasm32-wasip1" || die
}

src_prepare() {
	default

	# Remove profiler crates from workspace -- they depend on whamm (git dep)
	# and are not needed for the CLI or plugin builds
	sed -i \
		-e '/"crates\/profiler-lib"/d' \
		-e '/"crates\/profiler"/d' \
		Cargo.toml || die

	# Redirect whamm git dep to vendored source
	cat >> Cargo.toml <<-EOF

		[patch."https://github.com/saulecabrera/whamm"]
		whamm = { path = "${WORKDIR}/whamm-${WHAMM_COMMIT}" }
	EOF

	# Point cargo at vendored crates
	mkdir -p .cargo || die
	cat > .cargo/config.toml <<-EOF
		[source.crates-io]
		replace-with = "vendored-sources"

		[source.vendored-sources]
		directory = "vendor"
	EOF
}

src_compile() {
	local wasi_sysroot="${WORKDIR}/wasi-sysroot"

	# Build the default plugin for wasm32-wasip1.
	# Uses rust-bin's rustc (via --sysroot) because Gentoo's patched rustc
	# is ABI-incompatible with the prebuilt wasm32-wasip1 stdlib.
	(
		unset CARGO_BUILD_RUSTFLAGS CARGO_ENCODED_RUSTFLAGS RUSTFLAGS
		unset CARGO_BUILD_TARGET
		export CARGO_PROFILE_RELEASE_LTO=false
		export CARGO_PROFILE_RELEASE_STRIP=none
		export CC_wasm32_wasip1=clang
		local rustbin_dir
		rustbin_dir=$(find /opt -maxdepth 1 -name "rust-bin-*" -type d | sort -V | tail -1)
		export RUSTC="${rustbin_dir}/bin/rustc"
		export CARGO="${rustbin_dir}/bin/cargo"
		export CARGO_TARGET_WASM32_WASIP1_RUSTFLAGS="--sysroot ${wasi_sysroot} -C target-feature=+simd128"
		"${CARGO}" build -p javy-plugin --target wasm32-wasip1 --release
	) || die "plugin build failed"

	# Build the CLI binary with the system Rust (Gentoo's dev-lang/rust).
	local -x CARGO_PROFILE_RELEASE_LTO=off
	cargo_src_compile -p javy-cli
}

src_install() {
	dobin "$(cargo_target_dir)/javy"
	dodoc README.md
}
