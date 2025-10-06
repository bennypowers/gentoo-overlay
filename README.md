![Larry the Cow](https://wiki.gentoo.org/images/thumb/b/b8/Larry-nefarius-v2.svg/600px-Larry-nefarius-v2.svg.png)

Install Gentoo. Do a Linux.

This repo is developed in a subdirectory of ~. Changes are pushed to GitHub, and picked up from there with emaint sync. When creating manifests, tools will have to fetch source tarballs themselves, since they often don't exist on upstream mirrors.

When making changes to ebuilds, copy them into a new revision first

## Generating Manifests

To generate manifests without sudo access to `/var/cache/distfiles`, use a custom DISTDIR:

```bash
mkdir -p /tmp/distfiles
DISTDIR=/tmp/distfiles ebuild package-version.ebuild digest
```
