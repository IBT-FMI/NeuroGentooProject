.gentoo
=======

The .gentoo-folder is a new approach of bundling a Gentoo Ebuild (see the Package Manager Specification [PMS]) with your software.

Motivation
----------

Usually, ebuilds are distributed within a central overlay.
While this approach is reasonable for most cases since it enforces some structure on the distribution of ebuilds (usually combined with quality control), there are some edge-cases where it does not fit well.
Namely, if we want to distribute a single piece of development software and bundle the Ebuild within, but do not want the overhead of adding a whole overlay into our system.
A more convenient approach just distributed an ebuild and some way to install it with a single command, base it off the current working directory.

Additionally, if we just distribute the ebuild with our software sources, we may want to:

* specify additional overlays for dependencies in our ebuild, that are not included in the main portage tree (for example the science overlay for scientific software like FSL or AFNI)
* specify package masks, keywords, USE flags and unmasks required for the ebuild

Layout
------

The .gentoo format is a simple directory containing:
* A 99999-ebuild in a valid portage tree structure as defined in the Package Manager Standard, i.e. `.gentoo/category-name/pkgname/pkgname-99999.ebuild`
* `package.mask/` `package.keywords/` `package.use/` and `package.unmask/`
* `overlays/`, which contains additionally required overlays in the same format as `/etc/portage/repos.conf/`

![.gentoo folder structure](graph/DotGentoo.png)

.gentoo ID
----------

The .gentoo IDs are meant to uniquely identify the .gentoo folder based on semantic differences (and not on syntactical differences)

Hence, it is generated as the sha512-sum of the following UTF8 bytestream:

1. `#ebuild\n`
2. The content of the 99999-ebuild inside the .gentoo directory
3. `#overlays\n`
4. The _normalized_ content of all overlays in the `overlays/` directory.
	Normalized means that comments are removed, the options get sorted 
	in lexical order and are formatted like this:
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
	
	Prepended with `#keywords\n`, `#mask\n` etc. (even if they are empty or non-existant).
	
	Normalized means the comments are removed and the entries are listed
	in lexical order.

This yields a reasonably robust ID to any change outside the ebuilds.
But a slight change to the ebuild will affect the ID.

The install.sh Script
---------------------

In the template .gentoo there is a install.sh script included.
This script works in conjunction with the ebuild by passing an environment variable that contains the directory of the project root, allowing the ebuild to copy over the current directory when installing it.
Additionally, it sets up a temporary overlay inside the .gentoo, builds the ebuild manifest and executes emerge with the first ebuild it finds inside the .gentoo, and passing its commandline arguments to it.

The script does *not* install any overlay or package mask, use, keyword or unmask file.

[PMS]: https://dev.gentoo.org/~ulm/pms/head/pms.html "Package Manager Specification"
