BLAS and LAPACK Eclasses
========================

Eclasses are ways for reducing code-duplication inside Ebuilds.
They can be understood as libraries for Ebuild-writing, providing methods common to many Ebuilds.

The line
```
inherit <eclass>
```

Loads all definitions and functions from `<eclass>.eclass`, such that they can be used inside the Ebuild.

Motivation
----------

Currently, the main portage tree supports only one single system-wide BLAS
and LAPACK implementation, the reference implementations from netlib.
This is insufficient for high-performance use, since a well-tuned BLAS or
LAPACK implementation is important to optimally use cluster-resources.

Current non-mainline methods as provided by the [Gentoo Science project](https://wiki.gentoo.org/wiki/User_talk:Houseofsuns) require user interaction which can not easily be automated for the BuildServer specification.
We address this issue via the following proposal, which improves on the current Gentoo Science solution by transferring BLAS and LAPACK selection to the Portage dependency specification standard.

Specification
-------------

We propose a system providing two new eclasses, blas.eclass and lapack.eclass.
These eclasses define:

- a unique name for every BLAS or LAPACK implementation
- a new set of USE flags (`blas_<impl>` and `lapack_<impl>`)
  which provide a way for the end-user to select against which version of
  BLAS or LAPACK will be linked.

Every package Ebuild linking against either BLAS or LAPACK can set a 
variable `BLAS_COMPAT` or `LAPACK_COMPAT` to specify against which 
libraries the package can be linked (i.e. the compatibility with the
implementations) by adding their unique name to a space-separated list, or
an asterisk to specify compatibility with all implementations.
This has to be done before the eclass is inherited.
If unset, compatibility with all implementations is assumed.

Inheriting the eclasses will add:

- a USE flag for every compatible implementation to IUSE
- the dependency to the package providing the selected implementation to DEPEND and RDEPEND
- the constraint that only one single implementation USE flag may be set 
  to REQUIRED_USE. This variable holds boolean constraints for the USE flags. For example, `^^ (blas_a blas_b)` is an XOR constraint, evaluating to true if and only if either `blas_a` or `blas_b` are enabled.

The build-process will refer to the package-config program (`pkg-config`) to inquire the correct BLAS or LAPACK library. Therefore, we must ensure that any call to `pkg-config` returns the proper library.
Package-config is invoked `pkg-config --libs <name>`, and it returns the libraries needed to link against the package `<name>` (in this case, `<name>` is one of blas, cblas, lapack or lapacke).
This information is stored inside the file `/usr/lib/pkg-config/<name>.pc`

It is possible to provide package-config with additional paths to look for these `<name>.pc` files by adding a list of colon-separated paths to the environment variable `PKG_CONFIG_PATH`.
This is done in the pkg_setup functions exported by the eclasses.
They add create a package-config overlay `${T}/pkgconfig`, and add this path to the `PKG_CONFIG_PATH` environment variable.
Henceforth, this overlay directory takes precedence over every other directory, including the default one.

In the overlay directory the package-config file of the user-selected
implementation (e.g. `/usr/lib/pkg-config/openblas.pc`) will be linked to the generic name, (e.g. `blas.pc`).

### C Headers

Ebuilds can request that the C headers of the implementation be installed
by prepending `c:` to the `BLAS_COMPAT` or `LAPACK_COMPAT` variable.

### \*_COMPAT Variables


These variables have the following grammar:

	COMPAT <- HEADER_SPECIFIER " " IMPLEMENTATIONS | IMPLEMENTATIONS
	HEADER_SPECIFIER <- "fortran:" | "c:"
	IMPLEMENTATIONS <- IMPLEMENTATION | IMPLEMENTATIONS " " IMPLEMENTATIONS
	IMPLEMENTATION <- [a-zA-Z_\-]+ | "*"

### Conditional Dependency


Using `BLAS_CONDITIONAL_FLAG=(foo bar)` or `LAPACK_CONDITIONAL_FLAG=(foo bar)`,
the package will only depend on BLAS or LAPACK if foo and/or bar are set.

### USE Flags for Implementations

To specify a set of USE flags for an implementation, `BLAS_REQ_USE=foo`
or `LAPACK_REQ_USE=bar` can be used.
These will then be added to the dependencies in `DEPEND` and `RDEPEND`, 
e.g. `sci-libs/blas-reference[${BLAS_REQ_USE}]`

### Provider Ebuilds

The provider packages of BLAS or LAPACK implementations must install the package-config file `/usr/lib/pkgconfig/<unique implementation name>.pc`

Limitations
-----------

While appropriately addressing the currently most significant issues, the approach is not without limitations:

- Packages are not guaranteed to use the same BLAS or LAPACK implementation
  that they were linked against at run time, since we do not enforce a
  consistent implementation in all dependencies.
  Consider the figure below. The package P1 is dynamically linked against both D1 and D2, which pull a different BLAS implementation into the binary.
  The conflict is then carried out in the dynamic loader (ld.so).
  It traverses the dependency tree and first loads the functions (symbols) from B1 to satisfy the dependencies of D1, and then goes on to load the functions from B2 which have the same name than the ones in B1 and therefore overwrite them.
  Hence only one implementation is effectively loaded, but since all functions that should be present for P1 are present, the program P1 will still run.

![BLAS conflict](graph/BLAS_Conflict.png)

Backwards Compatibility
-----------------------

All Ebuilds depending on BLAS or LAPACK have to be adapted manually,
and implementation providers have to be rebuilt such that the proper
package-config files are installed
