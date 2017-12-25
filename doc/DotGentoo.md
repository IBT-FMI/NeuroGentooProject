.gentoo
=======

The .gentoo-folder is a new approach of bundling a Gentoo ebuild (see the Package Manager Specification [PMS]) with your software.

Motivation
----------

Usually, ebuilds are distributed within a central overlay.
While this approach is usually reasonable, since it enforces some structure on the distribution of ebuilds, there are some edge-cases where it does not fit well.
Namely, if we want to distribute a single piece of development software with build-instructions, but without the overhead of adding it to a larger overlay and distributing it.

Additionally, if we just distribute the ebuild with our software sources, we may:

* want to specify additional overlays for dependencies in our ebuild (for example the science overlay for scientific software)
* want to install not only the live-sources, but the dirty software directory with our not-commited changes

Layout
------

It is a simple directory containing:
* A 99999-ebuild in a valid portage tree structure, i.e. `.gentoo/category-name/pkgname/pkgname-99999.ebuild`
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

[PMS]: https://dev.gentoo.org/~ulm/pms/head/pms.html "Package Manager Specification"
