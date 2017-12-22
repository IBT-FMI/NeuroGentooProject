Build Server
============

Here we describe a build server infrastructure for gentoo images.
The BukldServer is a collection of shell-scripts that automate the creation, 
maintenance and formatchanges of a Gentoo System.

The BuildServer always does it's work relative to the current working directory of the parent process.
If you want to have the images in a specific directory, you should `cd` into them.

Each Gentoo-System is stored in a directory `$PWD/roots/<ID>/root/`.
The ID is one of:
* `stemgentoo`
* An ID corresponding to the `.gentoo`-directory the image is based off

To initialize a BuildServer, you need to run `initialize.sh`.
This command builds the `stemgentoo`

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
therein shall be executed.

Image configuration
===================

The images allow for configuration inside their directories.

Hooks
-----

Images can hook into the commands via `roots/<ID>/scripts/<command>/pre`
and `post`.
Everything in `pre` gets executed before the scripts in `scripts/<command>/<machinetype>`, 
everything in `post` afterwords.

Command-Chaining
----------------

If you wish to execute a command after another command has finished, you can specify that via `roots/<ID>/actionchain/post/<command>`
which is a file containing all the commands that should be executed after `command`.
Every command should stand in its own line (`\n`-separated)
