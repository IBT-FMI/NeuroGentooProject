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
