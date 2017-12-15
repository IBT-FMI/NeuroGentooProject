.gentoo Layout
==============

The .gentoo-folder is a new approach of bundling a Gentoo ebuild (see the Package Manager Specification [PMS]) with your software.
It is a simple directory containing:
* A 99999-ebuild in a valid Portage Tree structure, i.e. `.gentoo/cate-gory/pkgname/pkgname-99999.ebuild`
* `package.mask/` `package.keywords/` `package.use/` and `package.unmask/`
* `overlays/`, which contains additionally required overlays in the same format as `/etc/portage/repos.conf/`

.gentoo ID
----------

The .gentoo-ID is generated as the sha512-sum of the following UTF8 bytestream:

1. `#ebuild\n`
2. The content of the 99999-ebuild inside the .gentoo directory
3. `#overlays\n`
4. The _normalized_ content of all overlays in the `overlays/` directory.
	Normalized means that comments are removed, the options get sorted 
	alphabetically and are formatted like this:
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
	alphabetically.

[PMS]: https://dev.gentoo.org/~ulm/pms/head/pms.html "Package Manager Specification"
