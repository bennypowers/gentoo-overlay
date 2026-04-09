# Gentoo overlay test container
# Provides a clean-room emerge environment with ROCm GPU passthrough.
#
# Build:
#   podman build -t larry-test .
#
# The overlay, distfiles, and binpkgs are mounted at runtime, not baked in.
# This image just sets up portage config to match the host enough for testing.

FROM docker.io/gentoo/stage3:amd64-openrc

# Accept ~amd64 for overlay packages and their deps
RUN echo 'ACCEPT_KEYWORDS="~amd64"' >> /etc/portage/make.conf

# ROCm GPU target matching host
RUN echo 'VIDEO_CARDS="amdgpu"' >> /etc/portage/make.conf \
 && echo 'AMDGPU_TARGETS="gfx1201"' >> /etc/portage/make.conf

# Parallel builds
RUN echo 'MAKEOPTS="-j$(nproc) -l$(nproc)"' >> /etc/portage/make.conf \
 && echo 'EMERGE_DEFAULT_OPTS="--jobs=4 --load-average=$(nproc)"' >> /etc/portage/make.conf

# Features: use binpkgs when available, don't block on missing
RUN echo 'FEATURES="binpkg-multi-instance getbinpkg"' >> /etc/portage/make.conf

# Point DISTDIR and PKGDIR to mount points
RUN echo 'DISTDIR="/var/cache/distfiles"' >> /etc/portage/make.conf \
 && echo 'PKGDIR="/var/cache/binpkgs"' >> /etc/portage/make.conf

# Set up overlay repo config (mounted at runtime)
RUN mkdir -p /etc/portage/repos.conf \
 && printf '[bennypowers]\nlocation = /var/db/repos/bennypowers\n' \
    > /etc/portage/repos.conf/bennypowers.conf

# Guru overlay (many of our packages depend on it)
RUN printf '[guru]\nlocation = /var/db/repos/guru\nsync-type = git\nsync-uri = https://github.com/gentoo-mirror/guru.git\n' \
    > /etc/portage/repos.conf/guru.conf

# Sync portage tree (baked into image, refresh by rebuilding)
RUN emerge --sync

# Sync guru
RUN emerge -1q dev-vcs/git && emaint sync -r guru

WORKDIR /var/db/repos/bennypowers
