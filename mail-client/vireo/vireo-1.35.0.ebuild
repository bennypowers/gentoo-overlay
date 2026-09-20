# mail-client/vireo/vireo-1.0-r1.ebuild
EAPI=8

DESCRIPTION="Transition package: mail-client/vireo renamed to mail-client/hylki"
HOMEPAGE="https://wiki.gentoo.org/wiki/No_homepage"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="amd64 ~x86" # Match your target architectures

RDEPEND="mail-client/hylki"
