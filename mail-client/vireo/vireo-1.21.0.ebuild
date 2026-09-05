# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	adler2@2.0.1 	aes@0.8.4 	ahash@0.8.12 	aho-corasick@1.1.4 	allocator-api2@0.2.21 	ammonia@4.1.4 	android_system_properties@0.1.5 	ar_archive_writer@0.5.2 	async-broadcast@0.7.2 	async-channel@1.9.0 	async-channel@2.5.0 	async-compression@0.4.42 	async-executor@1.14.0 	async-fs@2.2.0 	async-imap@0.10.4 	async-io@2.6.0 	async-lock@3.4.2 	async-native-tls@0.5.0 	async-process@2.5.0 	async-recursion@1.1.1 	async-signal@0.2.14 	async-task@4.7.1 	async-trait@0.1.89 	atomic-waker@1.1.2 	autocfg@1.5.1 	base64@0.22.1 	bitflags@2.13.0 	block-buffer@0.10.4 	blocking@1.6.2 	block-padding@0.3.3 	bumpalo@3.20.3 	bytes@1.12.0 	cairo-rs@0.20.12 	cairo-sys-rs@0.20.10 	cbc@0.1.2 	cc@1.2.65 	cfg_aliases@0.2.1 	cfg-expr@0.20.8 	cfg-if@1.0.4 	charset@0.1.5 	chrono@0.4.45 	chumsky@0.13.0 	cipher@0.4.4 	compression-codecs@0.4.38 	compression-core@0.4.32 	concurrent-queue@2.5.0 	core-foundation@0.10.1 	core-foundation-sys@0.8.7 	cpufeatures@0.2.17 	crc32fast@1.5.0 	crossbeam-utils@0.8.21 	crypto-common@0.1.7 	cssparser@0.37.0 	dbus@0.9.11 	dbus-secret-service@4.1.0 	digest@0.10.7 	dirs@5.0.1 	dirs-sys@0.4.1 	displaydoc@0.2.6 	dtoa@1.0.11 	dtoa-short@0.3.5 	email_address@0.2.9 	email-encoding@0.4.1 	encoding_rs@0.8.35 	endi@1.1.1 	enumflags2@0.7.12 	enumflags2_derive@0.7.12 	equivalent@1.0.2 	errno@0.3.14 	event-listener@2.5.3 	event-listener@5.4.1 	event-listener-strategy@0.5.4 	fallible-iterator@0.3.0 	fallible-streaming-iterator@0.1.9 	fastrand@2.4.1 	field-offset@0.3.6 	find-msvc-tools@0.1.9 	flate2@1.1.9 	flume@0.11.1 	foldhash@0.1.5 	foreign-types@0.3.2 	foreign-types-shared@0.1.1 	form_urlencoded@1.2.2 	fragile@2.1.0 	futures@0.3.32 	futures-channel@0.3.32 	futures-core@0.3.32 	futures-executor@0.3.32 	futures-io@0.3.32 	futures-lite@2.6.1 	futures-macro@0.3.32 	futures-sink@0.3.32 	futures-task@0.3.32 	futures-util@0.3.32 	gdk4@0.9.6 	gdk4-sys@0.9.6 	gdk-pixbuf@0.20.10 	gdk-pixbuf-sys@0.20.10 	generic-array@0.14.7 	getrandom@0.2.17 	getrandom@0.4.3 	gio@0.20.12 	gio-sys@0.20.10 	glib@0.20.12 	glib-build-tools@0.20.0 	glib-macros@0.20.12 	glib-sys@0.20.10 	gobject-sys@0.20.10 	graphene-rs@0.20.10 	graphene-sys@0.20.10 	gsk4@0.9.6 	gsk4-sys@0.9.6 	gtk4@0.9.7 	gtk4-macros@0.9.5 	gtk4-sys@0.9.6 	hashbrown@0.14.5 	hashbrown@0.15.5 	hashbrown@0.17.1 	hashlink@0.9.1 	heck@0.5.0 	hermit-abi@0.5.2 	hex@0.4.3 	hkdf@0.12.4 	hmac@0.12.1 	html5ever@0.39.0 	httpdate@1.0.3 	iana-time-zone@0.1.65 	iana-time-zone-haiku@0.1.2 	icu_collections@2.2.0 	icu_locale_core@2.2.0 	icu_normalizer@2.2.0 	icu_normalizer_data@2.2.0 	icu_properties@2.2.0 	icu_properties_data@2.2.0 	icu_provider@2.2.0 	idna@1.1.0 	idna_adapter@1.2.2 	imap-proto@0.16.7 	indexmap@2.14.0 	inout@0.1.4 	itoa@1.0.18 	javascriptcore6@0.4.0 	javascriptcore6-sys@0.4.0 	js-sys@0.3.103 	keyring@3.6.3 	ksni@0.3.6 	lazy_static@1.5.0 	lettre@0.11.22 	libadwaita@0.7.2 	libadwaita-sys@0.7.2 	libc@0.2.186 	libdbus-sys@0.2.7 	libredox@0.1.17 	libsqlite3-sys@0.30.1 	linux-raw-sys@0.12.1 	litemap@0.8.2 	lock_api@0.4.14 	log@0.4.33 	mail-parser@0.9.4 	maplit@1.0.2 	markup5ever@0.39.0 	matchers@0.2.0 	memchr@2.8.2 	memoffset@0.9.1 	mime@0.3.17 	minimal-lexical@0.2.1 	miniz_oxide@0.8.9 	mio@1.2.1 	nanorand@0.7.0 	native-tls@0.2.18 	new_debug_unreachable@1.0.6 	nix@0.29.0 	nom@7.1.3 	nom@8.0.0 	nu-ansi-term@0.50.3 	num@0.4.3 	num-bigint@0.4.6 	num-complex@0.4.6 	num-integer@0.1.46 	num-iter@0.1.45 	num-rational@0.4.2 	num-traits@0.2.19 	object@0.37.3 	once_cell@1.21.4 	openssl@0.10.81 	openssl-macros@0.1.1 	openssl-probe@0.2.1 	openssl-sys@0.9.117 	option-ext@0.2.0 	ordered-stream@0.2.0 	pango@0.20.12 	pango-sys@0.20.10 	parking@2.2.1 	parking_lot@0.12.5 	parking_lot_core@0.9.12 	pastey@0.2.3 	percent-encoding@2.3.2 	phf@0.13.1 	phf_codegen@0.13.1 	phf_generator@0.13.1 	phf_shared@0.13.1 	pin-project@1.1.13 	pin-project-internal@1.1.13 	pin-project-lite@0.2.17 	pin-utils@0.1.0 	piper@0.2.5 	pkg-config@0.3.33 	polling@3.11.0 	poppler-rs@0.24.1 	poppler-sys-rs@0.24.0 	potential_utf@0.1.5 	ppv-lite86@0.2.21 	precomputed-hash@0.1.1 	proc-macro2@1.0.106 	proc-macro-crate@3.5.0 	psm@0.1.31 	quote@1.0.46 	quoted_printable@0.5.2 	rand@0.8.6 	rand_chacha@0.3.1 	rand_core@0.6.4 	redox_syscall@0.5.18 	redox_users@0.4.6 	r-efi@6.0.0 	regex-automata@0.4.14 	regex-syntax@0.8.11 	relm4@0.9.1 	relm4-components@0.9.1 	relm4-css@0.9.0 	relm4-macros@0.9.1 	rfc2047-decoder@1.1.2 	ring@0.17.14 	rusqlite@0.32.1 	rustc_version@0.4.1 	rustix@1.1.4 	rustls@0.23.41 	rustls-pki-types@1.14.1 	rustls-webpki@0.103.13 	rustversion@1.0.22 	schannel@0.1.29 	scopeguard@1.2.0 	secret-service@4.0.0 	security-framework@3.7.0 	security-framework-sys@2.17.0 	self_cell@1.2.2 	semver@1.0.28 	serde@1.0.228 	serde_core@1.0.228 	serde_derive@1.0.228 	serde_json@1.0.150 	serde_repr@0.1.20 	serde_spanned@0.6.9 	serde_spanned@1.1.1 	sha1@0.10.6 	sha2@0.10.9 	sharded-slab@0.1.7 	shlex@2.0.1 	signal-hook-registry@1.4.8 	simd-adler32@0.3.9 	siphasher@1.0.3 	slab@0.4.12 	smallvec@1.15.2 	socket2@0.6.4 	soup3@0.7.0 	soup3-sys@0.7.0 	spin@0.9.8 	stable_deref_trait@1.2.1 	stacker@0.1.24 	static_assertions@1.1.0 	stop-token@0.7.0 	string_cache@0.9.0 	string_cache_codegen@0.6.1 	subtle@2.6.1 	syn@2.0.118 	syn@3.0.4 	synstructure@0.13.2 	system-deps@7.0.8 	target-lexicon@0.13.5 	tempfile@3.27.0 	tendril@0.5.1 	thiserror@1.0.69 	thiserror@2.0.18 	thiserror-impl@1.0.69 	thiserror-impl@2.0.18 	thread_local@1.1.9 	tinystr@0.8.3 	tokio@1.52.3 	tokio-macros@2.7.0 	tokio-native-tls@0.3.1 	toml@0.8.23 	toml@1.1.2+spec-1.1.0 	toml_datetime@0.6.11 	toml_datetime@1.1.1+spec-1.1.0 	toml_edit@0.22.27 	toml_edit@0.25.12+spec-1.1.0 	toml_parser@1.1.2+spec-1.1.0 	toml_write@0.1.2 	toml_writer@1.1.1+spec-1.1.0 	tracing@0.1.44 	tracing-attributes@0.1.31 	tracing-core@0.1.36 	tracing-log@0.2.0 	tracing-subscriber@0.3.23 	tracker@0.2.2 	tracker-macros@0.2.2 	typenum@1.20.1 	uds_windows@1.2.1 	unicode-ident@1.0.24 	unicode-segmentation@1.13.3 	untrusted@0.9.0 	ureq@2.12.1 	url@2.5.8 	utf8_iter@1.0.4 	uuid@1.26.0 	valuable@0.1.1 	vcpkg@0.2.15 	version_check@0.9.5 	version-compare@0.2.1 	wasi@0.11.1+wasi-snapshot-preview1 	wasm-bindgen@0.2.126 	wasm-bindgen-macro@0.2.126 	wasm-bindgen-macro-support@0.2.126 	wasm-bindgen-shared@0.2.126 	web_atoms@0.2.6 	webkit6@0.4.0 	webkit6-sys@0.4.0 	webpki-roots@0.26.11 	webpki-roots@1.0.8 	windows_aarch64_gnullvm@0.48.5 	windows_aarch64_gnullvm@0.52.6 	windows_aarch64_msvc@0.48.5 	windows_aarch64_msvc@0.52.6 	windows-core@0.62.2 	windows_i686_gnu@0.48.5 	windows_i686_gnu@0.52.6 	windows_i686_gnullvm@0.52.6 	windows_i686_msvc@0.48.5 	windows_i686_msvc@0.52.6 	windows-implement@0.60.2 	windows-interface@0.59.3 	windows-link@0.2.1 	windows-result@0.4.1 	windows-strings@0.5.1 	windows-sys@0.48.0 	windows-sys@0.52.0 	windows-sys@0.59.0 	windows-sys@0.61.2 	windows-targets@0.48.5 	windows-targets@0.52.6 	windows_x86_64_gnu@0.48.5 	windows_x86_64_gnu@0.52.6 	windows_x86_64_gnullvm@0.48.5 	windows_x86_64_gnullvm@0.52.6 	windows_x86_64_msvc@0.48.5 	windows_x86_64_msvc@0.52.6 	winnow@0.7.15 	winnow@1.0.3 	writeable@0.6.3 	xdg-home@1.3.0 	yoke@0.8.3 	yoke-derive@0.8.2 	zbus@4.4.0 	zbus@5.19.0 	zbus_macros@4.4.0 	zbus_macros@5.19.0 	zbus_names@3.0.0 	zbus_names@4.3.4 	zcheapstr@1.1.0 	zerocopy@0.8.52 	zerocopy-derive@0.8.52 	zerofrom@0.1.8 	zerofrom-derive@0.1.7 	zeroize@1.9.0 	zeroize_derive@1.5.0 	zerotrie@0.2.4 	zerovec@0.11.6 	zerovec-derive@0.11.3 	zmij@1.0.21 	zvariant@4.2.0 	zvariant@5.15.0 	zvariant_derive@4.2.0 	zvariant_derive@5.15.0 	zvariant_utils@2.1.0 	zvariant_utils@4.2.0
"

inherit cargo desktop xdg

DESCRIPTION="Clean, fast, GNOME-native email client"
HOMEPAGE="https://vireo.hyprlab.co/"
SRC_URI="
	https://github.com/hyprlab/vireo/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"

LICENSE="
	AGPL-3+
	0BSD Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD
	CDLA-Permissive-2.0 ISC MIT MPL-2.0 Unicode-3.0 ZLIB
"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	dev-db/sqlite:3
	dev-libs/openssl:=
	>=gui-libs/gtk-4.10.0:4
	>=gui-libs/libadwaita-1.4.0:1
	net-libs/libsoup:3.0
	net-libs/webkit-gtk:6
	sys-apps/dbus
"
RDEPEND="
	${DEPEND}
	virtual/secret-service
"
BDEPEND="
	dev-libs/glib:2
	virtual/pkgconfig
"

src_prepare() {
	default
	# Use system sqlite instead of bundled
	sed -i 's/features = \["bundled"\]/features = []/' Cargo.toml || die
}

src_install() {
	cargo_src_install

	insinto /usr/share
	doins -r data/icons

	domenu data/co.hyprlab.Vireo.desktop

	insinto /usr/share/metainfo
	doins data/co.hyprlab.Vireo.metainfo.xml
}
