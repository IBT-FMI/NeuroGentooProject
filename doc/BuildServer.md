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
=============

Configuration files are shell-scripts that end in `.conf`.
They get sourced just before executing the command scripts.
The following directories are searched for `.conf` files.
* `config/` in the build-server root
* `roots/<ID>/config/`

Chroot
------

If you want to use these configuration parameters inside a chrootet script, 
make sure to export them into the environment variables first!

Hooks
=====

The images allow for configuration inside their directories.

There are two types of hooks:

* pre and post command hooks: these are additional scripts executed in a command
* command chains: these allow executing another command after one has finished 

Pre and Post Hooks
------------------

Images can hook into the commands via `roots/<ID>/hooks/<command>/pre`
and `post`.
Everything in `pre` gets executed before the scripts in `hooks/<command>/<machinetype>`, 
everything in `post` afterwords.

Command-Chaining
----------------

If you wish to execute a command after another command has finished, you can specify that via `roots/<ID>/hooks/<command>/chain`
which is a file containing all the commands that should be executed after `command`.
Every command should stand in its own line (`\n`-separated)


Logging
=======

Logging is done in the directory specified in the config files
By default, this has the form `roots/<ID>/logs/<command>/`

Every script of that command that gets executed writes to a new log-file
called `<script>.log` (for example `00-setup.sh.log`)
