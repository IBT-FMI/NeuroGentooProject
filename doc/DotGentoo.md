.gentoo
=======

The .gentoo-directory is a new approach of distributing a Gentoo Ebuild (see the Package Manager Specification [PMS]) - together with the software.

Motivation
----------

Usually, Ebuilds are distributed in large sets, via overlays.
While this approach is reasonable for most cases, as it enforces some structure on the distribution of Ebuilds (usually combined with quality control), there are edge-cases where this approach does not fit well.
Namely, when distributing the Ebuild alongside the software.
The canonical approach to add a single Ebuild to the set of known packages is be to create a new directory, copy the Ebuild to the directory, and integrate the directory into the Gentoo system (as an overlay), by manually editing at least one system configuration file.

!!! You need to make the connection between implicit overlay handling and the fact that we are talking about very-life software, meaning that this no longer just fetched live stuff from upstream, but uses the livest stuff from the user/developer's computer

A more convenient model is to distribute an Ebuild and provide a way to install it with a single command, based on the current state of the projects working directory (including non-commited changes).
Since not all information needed to install the software is contained inside the Ebuild, it is necessary to:

* specify additional overlays needed to resolve additional Ebuild dependencies which are not included in the main portage tree (but rather in e.g. the Science Overlay, as FSL or AFNI are)
* specify package masks, keywords, USE flags and unmasks required for the Ebuild

This metadata, though contained, should not be added automatically to a users Gentoo Linux, since it has a large effect on the rest of the system.
Hence, the metadata handling in particular should not be done without the users explicit consent or without user interaction.
!!! Better separate what is done automatically and what is done manually.

Layout
------

The .gentoo format is a simple directory containing:
* A 99999-Ebuild in a valid portage tree structure as defined in the Package Manager Standard, i.e. `.gentoo/category-name/pkgname/pkgname-99999.ebuild`
* `package.mask/` `package.keywords/` `package.use/` and `package.unmask/`
* `overlays/`, which contains additionally required overlays in the same format as `/etc/portage/repos.conf/`

![.gentoo directory structure](graph/DotGentoo.png)

.gentoo ID
----------

The .gentoo IDs are meant to uniquely identify the .gentoo directory based on semantic (rather than syntactical) differences.

Hence, it is generated as the sha512-sum of the following UTF8 byte stream:

1. `#Ebuild\n`
2. The content of the 99999-Ebuild inside the .gentoo directory
3. `#overlays\n`
4. The _normalized_ content of all overlays in the `overlays/` directory.
	Normalized means that comments are removed, the options get sorted 
	in lexical order and are formatted according to the following model:
	```
	[overlayname]\n
	key1 = value1\n
	key2 = value2\n
	...
	[overlay2name]\n
	key1 = value1\n
	key2 = value2\n
	...
	```
5. The normalized package.* files in order: 
	1. keywords
	2. mask
	3. unmask
	4. use
	
	Prepended with `#keywords\n`, `#mask\n` etc. (even if they are empty or non-existent).
	
	Normalized, in the present context, refers to the comments being removed and the entries listed in lexical order.

This yields an ID which is reasonably robust to changes outside the Ebuild.
However, any slight (even syntactical) change to the Ebuild will affect the ID drastically.
This is a design choice as much as it is a design limitation, since the flexibility which has to be guaranteed in an Ebuild cannot be reconciled with standardized semantic parsing.

The install.sh Script
---------------------

The .gentoo directory includes an install.sh script.
The Ebuild has to be adapted slightly such that it does not install the software version given by the sources in `SRC_URI`, `EGIT_REPO_URI` or equivalent, but rather use the local files.
To achieve this, the `install.sh` script works in conjunction with Portage (as controlled by the Ebuild).
In the script, an environment variable (`DOTGENTOO_PACKAGE_ROOT`) is exported, and the Portage copies whatever is inside the directory specified by this variable to its working directory.

```bash
src_unpack() {
        cp -r -L "$DOTGENTOO_PACKAGE_ROOT" "$S"
}
```

The `install.sh` script additionally sets up a temporary overlay inside the .gentoo directory, builds the Ebuild manifest and executes emerge with the first Ebuild it finds under .gentoo.
The command line arguments passed to `install.sh` are forwarded to emerge.

The script does *not* install any overlay or package mask, use, keyword or unmask file. The user is required to do that manually, for the reasons mentioned under (!!! link to motiv section).

[PMS]: https://dev.gentoo.org/~ulm/pms/head/pms.html "Package Manager Specification"
