---
GLEP: XXX
Title: Build-Time Selection of BLAS and Lapack
Author: Dominik Schmidt <domischmidt@swissonline.ch>
Type: Standards Track
Status: Draft
Version: 1
Created: 2017-11-20
Last-Modified: 2017-11-20
Post-History: 
Content-Type: text/x-rst
---

Abstract
========

This GLEP proposes a solution to manage the selection of BLAS and Lapack
implementations at build time.

Motivation
==========

Currently, the main portage tree supports only one single system-wide BLAS
and Lapack implementation, the reference implementations from netlib.
This is insufficient for high-performance use, since a well-tuned BLAS or
Lapack implementation is important to save cluster-resources.

Requirements
============

The following constraints should be satisfied:

Compatibility Specification
	Packages should be able to specify which implementations of BLAS or
	Lapack they support in their ebuilds.

Dynamic Linking Consistency
	If a package links against BLAS or Lapack as well as other packages
	the whole dependency graph should agree on one single BLAS or Lapack
	implementation.


Specification
=============

We propose a system providing two eclasses, blas.eclass and lapack.eclass.
These eclasses define:

- a unique name for every BLAS or Lapack implementation
- a new set of USE flags (``blas_<impl>`` and ``lapack_<impl>``)
  which provide a way for the end-user to select against which version of
  BLAS or Lapack will be linked.
- the variables ``BLAS_USEDEP`` or ``LAPACK_USEDEP`` which must be included
  in the USE dependencies on all atoms also inheriting the blas or lapack
  eclass in DEPEND or RDEPEND. This will enforce the dynamic linking
  consistency.

Every package ebuild linking against either BLAS or Lapack can set a 
variable ``BLAS_COMPAT`` or ``LAPACK_COMPAT`` to specify against which 
libraries the package can be linked (i.e. the compatibility with the
implementations), before inheriting the eclass. If unset, compatibility
with all implementations is assumed.

Inheriting the eclasses will add:

- a USE flag for every compatible implementation to IUSE
- the dependencies for the package providing the implementation to DEPEND
  and RDEPEND
- the constraint that only one single implementation USE flag may be set 
  to REQUIRED_USE.

The eclasses export the pkg_setup function, in which they add an overlay
for package-config in ``${T}/pkgconfig``, that will be prepended to the
package-config environment variable ``PKG_CONFIG_PATH``, which then will
be exported.
In this directory the package-config file of the user-selected implementation
will be linked to a generic name, i.e. ``blas.pc`` or ``lapack.pc``.
Hence, whenever ``pkg-config`` gets called to resolve blas or lapack during
build, the correct library and include paths will be used.

C Headers
---------

Ebuilds can request that the C headers of the implementation to be installed
via the variables ``BLAS_USE_CBLAS=1`` or ``LAPACK_USE_LAPACKE=1``

Provider Ebuilds
----------------

The providers of BLAS or Lapack implementations must install a package-config
file in 

- `/usr/lib/pkgconfig/<unique implementation name>.pc`

Backwards Compatibility
=======================

All ebuilds depending on BLAS or Lapack have to be adapted manually,
and implementation providers have to be rebuilt such that the proper
package-config files are installed

Copyright
=========

This work is licensed under the Creative Commons Attribution-ShareAlike 3.0
Unported License.  To view a copy of this license, visit
http://creativecommons.org/licenses/by-sa/3.0/.
