.gentoo
=======

The .gentoo-folder is a new approach of bundling a Gentoo Ebuild (see the Package Manager Specification [PMS]) together with the software.

Motivation
----------

Usually, Ebuilds are distributed within a central overlay.
While this approach is reasonable for most cases since it enforces some structure on the distribution of Ebuilds (usually combined with quality control), there are some edge-cases where it does not fit well.
Namely, if we want to distribute a single piece of development software and bundle the Ebuild inside the repository without the overhead of adding a whole overlay into the Gentoo system.
The more convenient approach distributes an Ebuild and provides a way to install it with a single command, based on the current (maybe dirty, i.e. including non-commited changes) state of the projects working directory.

Additionally, to be able to distribute the Ebuild with our software sources, it is important to:

* specify additional overlays for dependencies in our Ebuild, that are not included in the main portage tree (for example the science overlay for scientific software like FSL or AFNI)
* specify package masks, keywords, USE flags and unmasks required for the Ebuild

Layout
------

The .gentoo format is a simple directory containing:
* A 99999-Ebuild in a valid portage tree structure as defined in the Package Manager Standard, i.e. `.gentoo/category-name/pkgname/pkgname-99999.Ebuild`
* `package.mask/` `package.keywords/` `package.use/` and `package.unmask/`
* `overlays/`, which contains additionally required overlays in the same format as `/etc/portage/repos.conf/`

![.gentoo folder structure](graph/DotGentoo.png)

.gentoo ID
----------

The .gentoo IDs are meant to uniquely identify the .gentoo folder based on semantic differences (and not on syntactical differences)

Hence, it is generated as the sha512-sum of the following UTF8 byte stream:

1. `#Ebuild\n`
2. The content of the 99999-Ebuild inside the .gentoo directory
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
	
	Prepended with `#keywords\n`, `#mask\n` etc. (even if they are empty or non-existent).
	
	Normalized means the comments are removed and the entries are listed
	in lexical order.

This yields a reasonably robust ID to any change outside the Ebuilds.
But as can be seen a slight (syntactical) change to the Ebuild will affect the ID drastically.

The install.sh Script
---------------------

In the template .gentoo there is a install.sh script included.
This script works in conjunction with the Ebuild by passing an environment variable that contains the directory of the project root, allowing the Ebuild to copy over the current directory when installing it.
Additionally, it sets up a temporary overlay inside the .gentoo, builds the Ebuild manifest and executes emerge with the first Ebuild it finds inside the .gentoo, and passes its command line arguments to it.

The script does *not* install any overlay or package mask, use, keyword or unmask file. The user is required to do that manually.

[PMS]: https://dev.gentoo.org/~ulm/pms/head/pms.html "Package Manager Specification"
