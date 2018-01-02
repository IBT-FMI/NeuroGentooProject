Use Cases
=========

A way to distribute build instructions alongside the software was discussed in the previous section, but it relies on an existing Gentoo Linux installation.

To make Gentoo available on many machine types, three installation methods are explored:

* Bare-Metal: A classical installation on a hard-disk partition
* [Gentoo Prefix](https://wiki.gentoo.org/wiki/Project:Prefix): An installation inside the home-directory of a different UNIX system.
* Virtual Machine Images.

![A tree of the different machine categories (ellipses), machine types (rectangles) and Gentoo installation methods (diamonds)](graph/UseCases.png)

Bare-Metal Installations
------------------------

This method only applies for Personal Computers, since they provide the most choice.

It is only necessary to follow the [Gentoo Installation Handbook](https://wiki.gentoo.org/wiki/Handbook:Main_Page),
pull the repository and execute the `install.sh` script inside the .gentoo directory, maybe with prior installation of the metadata.

### Installation of the Metadata

In the .gentoo-directory, do the following: 

1. Copy the package files:
	```bash
	for dir in keywords use mask unmask; do [ -e "package.${dir}" ] && rsync -av "package.${dir}" "/etc/portage/"; done
	```
2. Copy the additional overlays:
	```bash
	mkdir -p /etc/portage/repos.conf
	cp -n -t overlays/* /etc/portage/repos.conf
	```
3. Sync the additional overlays
	```bash
	emaint sync -a
	```
Now one can safely execute the `./install.sh` script.

Gentoo Prefix Installations
---------------------------

Prefix installations are full Gentoo Linux installations, that reside somewhere in the users home-directory, and do not affect the host system.
It can be understood as a kind of virtual machine *without* the strict encapsulation from guest to host, but also without the usual virtualization overhead.

Gentoo Prefix is installed with a script that leads the user through the whole process and requires only minimal interaction at the beginning.
This script can be downloaded from the Gentoo developer page at <https://dev.gentoo.org/~heroxbd/bootstrap-rap.sh>

Usage of the .gentoo directory is simliar to Bare-Metal installations, except that the Portage configuration no longer resides in `/etc`, but in the prefix directory, which is usually `$HOME/gentoo/etc/portage/`

### EULER

Gentoo Prefix is the only way of using Gentoo Linux on the EULER Cluster, but it has some quirks:

* The number of files in the home-directory is limited to a too small number for Gentoo Prefix. One either has to use `$SCRATCH`, which is slow and sometimes unstable, or ask the technical support for a higher inode quota.
* The normal Bash environment has a environment variable set that prefix does not like. It has to be unset in `$HOME/.bashrc`:
	```bash
	export -n LD_LIBRARY_PATH
	unset LD_LIBRARY_PATH
	```
* The user- and group-id do not exist locally but on a remote server. Prefix has to be told about the non-standard user and group database:
	```bash
		for b in 32 64
		do
			dir="${EPREFIX}/lib${b}/"
			mkdir -p "${dir}"
			ln -s -t "${dir}" /usr/lib${b}/libnss_sss.so*
		done
		mkdir "${EPREFIX}/etc"
		cp -L /etc/nsswitch.conf "${EPREFIX}/etc/"
	```

A fully integrated way to prepare *and* install Gentoo Prefix on EULER is distributed on the [IBT-FMI GitHub page](https://raw.githubusercontent.com/IBT-FMI/NeuroGentooProject/master/Euler/euler.sh)

Virtual Machine Images
----------------------

Virtual Machine Images usually have to be reasonably recent and ideally would bring the required software with them.
To achieve these goals a BuildServer infrastructure is presented in the next chapter, that can periodically build ready to use images for Docker and OpenStack Cloud providers based on a specific .gentoo directory.
