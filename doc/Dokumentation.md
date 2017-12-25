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

Build Server
============

Here we describe a build server infrastructure for gentoo images.
The BukldServer is a collection of shell-scripts that automate the creation, 
maintenance and formatchanges of a Gentoo System.

The BuildServer always does it's work relative to the current working directory of the parent process.
If you want to have the images in a specific directory, you should `cd` into them.

Each Gentoo-System is stored in a directory `$PWD/roots/<ID>/root/`.
`<ID>` is one of:
* `stemgentoo`
* An ID corresponding to the `.gentoo`-directory the image is based off

Prerequisites
-------------

* Bash version >=4.2
* [dracut](https://dracut.wiki.kernel.org/index.php/Main_Page) for openstack images
* Portage
* Python

Initialization
--------------

To initialize a BuildServer, you need to run `./exec.sh stemgentoo initialize`.
This command builds the `stemgentoo` and sets up all the necessary variables.

To update the stemgentoo, use the command `exec.sh stemgentoo update`

Machine Types
-------------

There are two machine types:
* stemgentoo
* default

The latter get based off the stemgentoo when initializing them.

Commands
--------

Commands are defined in `scripts/`. If we want to execute `command` for
a machine of type `machinetype`,
all scripts in `scripts/command/machinetype/` are executed in lexical order.

Scripts
-------

Scripts are executable files stored in `scripts/command/machinetype/`.
If their name ends in `.chroot`, the BuildServer will chroot to the specific root
before executing the commands.
If it is a directory (or even a symlink to a directory), all executable files contained
therein will be executed.

Error Handling
--------------

Error handling is provided with the shell.
We track whether a command fails with `trap <func> ERR`.
This means that as soon as any command ends with a non-zero exit status, we jump to `<func>`

Inside this functions we do certain cleanup tasks and exit with a non-zero status afterwords.
The cleanup-tasks get defined by the script. 

Configuration
-------------

Configuration files are shell-scripts that end in `.conf`.
They get sourced just before executing the command scripts.
The following directories are searched for `.conf` files.
* `config/` in the build-server root
* `roots/<ID>/config/`

### Chroot-configuration


If you want to use these configuration parameters inside a chrootet script, 
make sure to export them into the environment variables first!

Hooks
-----

The images allow for configuration inside their directories.

There are two types of hooks:

* pre and post command hooks: these are additional scripts executed in a command
* command chains: these allow executing another command after one has finished 

![Hooks and Command-Chains](graph/Scripts.png)

### Pre and Post Hooks


Images can hook into the commands via `roots/<ID>/hooks/<command>/pre`
and `post`.
Everything in `pre` gets executed before the scripts in `hooks/<command>/<machinetype>`, 
everything in `post` afterwords.

### Command-Chaining

If you wish to execute a command after another command has finished, you can specify that via `roots/<ID>/hooks/<command>/chain`
which is a file containing all the commands that should be executed after `command`.
Every command should stand in its own line (`\n`-separated)


Logging
-------

Logging is done in the directory specified in the config files
By default, this has the form `roots/<ID>/logs/<command>/`

Every script of that command that gets executed writes to a new log-file
called `<script>.log` (for example `00-setup.sh.log`)

BLAS and Lapack Eclasses
========================

Eclasses are ways for reducing code-duplication inside ebuilds.
They can be understood as libraries for ebuild-writing, providing methods common to many ebuilds.

The line
```
inherit <eclass>
```

Loads all definitions and functions from `<eclass>.eclass`, such that they can be used inside the ebuild.

Motivation
----------

Currently, the main portage tree supports only one single system-wide BLAS
and Lapack implementation, the reference implementations from netlib.
This is insufficient for high-performance use, since a well-tuned BLAS or
Lapack implementation is important to optimally use cluster-resources.


Specification
-------------

We propose a system providing two eclasses, blas.eclass and lapack.eclass.
These eclasses define:

- a unique name for every BLAS or Lapack implementation
- a new set of USE flags (`blas_<impl>` and `lapack_<impl>`)
  which provide a way for the end-user to select against which version of
  BLAS or Lapack will be linked.

Every package ebuild linking against either BLAS or Lapack can set a 
variable `BLAS_COMPAT` or `LAPACK_COMPAT` to specify against which 
libraries the package can be linked (i.e. the compatibility with the
implementations) by adding their unique name the space-separated list, or
an asterisk to specify compatibility with all implementations.
This has to be done before the eclass is inherited.
If unset, compatibility with all implementations is assumed.

Inheriting the eclasses will add:

- a USE flag for every compatible implementation to IUSE
- the dependencies for the package providing the implementation to DEPEND
  and RDEPEND
- the constraint that only one single implementation USE flag may be set 
  to REQUIRED_USE.

The eclasses export the pkg_setup function, in which they add an overlay
for package-config in `${T}/pkgconfig`, that will be prepended to the
package-config environment variable `PKG_CONFIG_PATH`.
This variable will then in turn be exported globally.
In the overlay directory the package-config file of the user-selected
implementation will be linked to the generic name, i.e. `blas.pc` or
`lapack.pc`.
Hence, whenever `pkg-config` gets called to resolve blas or lapack during
build, the correct library and include paths will be used.

### C Headers

Ebuilds can request that the C headers of the implementation to be installed
by prepending `c:` to the `BLAS_COMPAT` or `LAPACK_COMPAT` variable.

### \*_COMPAT Variables


These variables have the following grammar:

	COMPAT <- HEADER_SPECIFIER " " IMPLEMENTATIONS | IMPLEMENTATIONS
	HEADER_SPECIFIER <- "fortran:" | "c:"
	IMPLEMENTATIONS <- IMPLEMENTATION | IMPLEMENTATIONS " " IMPLEMENTATIONS
	IMPLEMENTATION <- [a-zA-Z_\-]+ | "*"

### Conditional Dependency


Using `BLAS_CONDITIONAL_FLAG=(foo bar)` or `LAPACK_CONDITIONAL_FLAG=(foo bar)`,
the package will only depend on BLAS or Lapack if foo (logical-)or bar are set.

### USE Flags for Implementations

To specify a set of USE flags for an implementation, `BLAS_REQ_USE=foo`
or `LAPACK_REQ_USE=bar` can be used.
These will then be added to the dependencies in `DEPEND` and `RDEPEND`, 
e.g. `sci-libs/blas-reference[${BLAS_REQ_USE}]`

### Provider Ebuilds

The providers of BLAS or Lapack implementations must install a package-config
file in `/usr/lib/pkgconfig/<unique implementation name>.pc`

Limitations
-----------

Limitations of the approach do exist:

- Packages are not guaranteed to use the same BLAS or Lapack implementation
  that they were linked against at runtime, since we do not enforce a
  consistent implementation in all dependencies.
  Consider the figure below. The package P1 is dynamically linked against both BLAS B1 and B2.
  When we start the binary of P1, B1 will overwrite B2 or vice versa.

![BLAS conflict](graph/BLAS_Conflict.png)

Backwards Compatibility
-----------------------

All ebuilds depending on BLAS or Lapack have to be adapted manually,
and implementation providers have to be rebuilt such that the proper
package-config files are installed

