Build Server
============

Here we describe a build server infrastructure for gentoo Docker-images.

.gentoo
--------

Since gentoo is very versatile, we want to give the user the possibility
to receive a custom-made Docker-Image based on what he wants.
Therefore, we need a formal specification on how to define the customizations.
This is done via the .gentoo directory:

* .gentoo/
	* deps: A file with all the programs to build, one per line in the 
		package manager specification
	* overlays/: A directory containing special overlays
		* overlay.conf: A file in the syntax of `/etc/portage/repos.conf/`-files

We generate an ID from this directory by concatenating the content of all files
and doing an sha256sum. Prior to this, we have to normalize their contents.

* deps: The dependency-file we sort and remove multiple entries as well as empty or commented lines.
* overlays: 
