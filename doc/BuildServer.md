Build Server
============

Here we describe a build server infrastructure for gentoo images.
The BuildServer is a collection of shell-scripts that automate the creation, 
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


The machine-type decides which set of scripts get executed.
Currently, there are two machine types defined:
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

We can add cleanup-tasks to this error-handler with the shell-function
`on_error "<str>"`.
This function adds the string `<str>` to a stack.
In the case of an error these strings get popped from the stack and evaluated.

Cleanup
-------

Cleanup works exactly the same as error-handling, but it gets executed always before exiting the shell, 
and functions are added with `on_exit "<str>"`

In case of an error, first the cleanup-stack and then the error-stack get processed.

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

Every script that is executed generates its own log-file, into which the script stdout and stderr are piped.
For example, if a command contains a script called `00-setup.sh`, its output will be written to the file `00-setup.sh.log`.
