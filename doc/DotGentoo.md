.gentoo
=======

The .gentoo-directory is a new approach of distributing a Gentoo Ebuild (see the Package Manager Specification [PMS]) together with the software.
!!! Bundling is a bad word, and folder is Windows/GUI terminology

Motivation
----------

Usually, Ebuilds are distributed in large sets in overlays.
While this approach is reasonable for most cases, as it enforces some structure on the distribution of Ebuilds (usually combined with quality control), there are some edge-cases where this approach does not fit well.
Namely, if we want to distribute a single piece of development software and bundle the Ebuild inside the repository without the overhead of adding a whole overlay into the Gentoo system.
The more convenient approach distributes an Ebuild and provides a way to install it with a single command, based on the current (maybe dirty, i.e. including non-commited changes) state of the projects working directory.
!!! You should break all of this up in shorter sentences, even knowing what you are talking about, this is still confusing. Also the expression “maybe dirty” is too informal for the context 

Additionally, to be able to distribute the Ebuild alongside the software sources, it is important to:

* specify additional overlays for dependencies in our Ebuild, that are not included in the main portage tree (for example the science overlay for scientific software like FSL or AFNI)
* specify package masks, keywords, USE flags and unmasks required for the Ebuild

Layout
------

The .gentoo format is a simple directory containing:
* A 99999-Ebuild in a valid portage tree structure as defined in the Package Manager Standard, i.e. `.gentoo/category-name/pkgname/pkgname-99999.ebuild`
* `package.mask/` `package.keywords/` `package.use/` and `package.unmask/`
* `overlays/`, which contains additionally required overlays in the same format as `/etc/portage/repos.conf/`

![.gentoo folder structure](graph/DotGentoo.png)

.gentoo ID
----------

The .gentoo IDs are meant to uniquely identify the .gentoo directory based on semantic differences (and not on syntactical differences)

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
	
	Normalized means the comments are removed and the entries are listed
	in lexical order.

This yields an ID which is reasonably robust to changes outside the Ebuild.
However, any slight (even syntactical) change to the Ebuild will affect the ID drastically.
This is a design choice as much as it is a design limitation, since the flexibility which has to be guaranteed in an ebuild cannot be reconciled with standardized semantic parsing.

The install.sh Script
---------------------

!!! I understand that there is good reason for not shipping the install.sh script with the .gentoo standard information (simply because the install.sh is a standard utility and not part of the varibale space covered by the standard) but it seems to me that we curretnly lack a seamless avenue for distribution of this file (i.e. the Buildserver assumes it can find it in the .gentoo directory). So maybe this script needs to be included in the layout overview as well.

The .gentoo directory includes an install.sh script.
This script works in conjunction with the Ebuild by passing an environment variable that contains the directory of the project root, allowing the Ebuild to copy over the current directory when installing it.
!!! This needs to be explained better
Additionally, it sets up a temporary overlay inside the .gentoo directory, builds the Ebuild manifest and executes emerge with the first Ebuild it finds uner .gentoo, and passes its command line arguments to it.

The script does *not* install any overlay or package mask, use, keyword or unmask file. The user is required to do that manually.
!!! How then do the settings specified in these files take effect, and prevent e.g. dependency breakage via system updates?

[PMS]: https://dev.gentoo.org/~ulm/pms/head/pms.html "Package Manager Specification"
