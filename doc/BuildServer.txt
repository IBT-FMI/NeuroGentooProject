Build Server
============

![The layout of the BuildServer. The user starts exec.sh with parameters, which executes all scripts within the corresponding scripts folder. These scripts work on the image in roots/<ID>](graph/BuildServer.png)

The BuildServer is a infrastructure that generates Gentoo Linux images, based on a collection of shell-scripts that automate the creation, maintenance and format changes of these systems.

Its user-interface resides in the script `exec.sh`, which parses the command-line parameters `exec.sh </path/to/.gentoo or stemgentoo> <command> [machinetype]`

The work is always done relative to the current working directory.
If you want to have the images in a specific directory, you have to `cd` into them.

Each Gentoo-System is stored in a directory `$PWD/roots/<ID>/root/`.
`<ID>` is one of:
* `stemgentoo`
* An ID corresponding to the `.gentoo`-directory the image is based off


Prerequisites
-------------

* Bash version >=4.2
* [dracut](https://dracut.wiki.kernel.org/index.php/Main_Page) for openstack images
* [syslinux](http://www.syslinux.org/) for openstack images
* Portage
* Python

Why Bash?
---------

Bash has some properties that make it useful for the context of building images:

* It is easy to create processes and redirect their input/output streams to different sources/sinks. This is especially useful since image-building is a very process-heavy (i.e. most of the tasks are solely: execute program A, then program B, etc.).
* Many people can write shell-scripts at least to a certain degree.
* There are error-handling primitives in place to stop the execution of the scripts when any subprogram fails.

Roots Directory
---------------

The `$PWD/roots` directory contains all the images tracked by the buildserver inside a directory named after their .gentoo ID, i.e. `$PWD/roots/<ID>`.
These image directories have the following contents:

* `root/`: The actual image-files
* `hooks/`: Hooks for adding image-specific steps to the build process
* `config/`: Configuration to alter the behaviour of the BuildServer for a specific image
* `logs/`: The standard output and standard error of the command-steps
* `openstack_images`: The generated openstack images
* `registry`: Usually used for preserving some state for the images, for example the latest docker image corresponding to this image. 

Initialization
--------------

The call `./exec.sh stemgentoo initialize` initializes the BuildServer.
This command builds the `stemgentoo` based on the most recent stage3 provided by <https://gentoo.org> and sets up all the necessary prerequisites (for example a cache for commonly used files).

Machine Types
-------------

The machine-type decides which set of scripts get executed.
Currently, there are two machine types defined:
* stemgentoo
* default

The default machines get based off the stemgentoo when initializing them, and stemgentoos get based off the most current amd64 stage3 tarball provided on <https://gentoo.org>

Commands
--------

The commands are defined in the `scripts/` directory. To execute `command` for
a machine of type `machinetype` `exec.sh </path/to/.gentoo> <command> <machinetype>` is invoked.
This results in all scripts in `scripts/command/machinetype/` being executed in lexical order.

Scripts
-------

Scripts are executable bash scripts stored in `scripts/command/machinetype/`.
If their name ends in `.chroot`, the BuildServer will chroot to the corresponding image
before executing the commands.
If it is a directory (or a symlink to a directory), all executable files contained
therein will be executed.

### Variables

The scripts have access to certain environment and global variables:

* `STAGE`: The current command executed, e.g. `update`
* `MACHINE`: The image ID currently worked on
* `MACHINETYPE`: The machine type of the current image, e.g. `stemgentoo`
* `ROOT`: The absolute directory to the image root
* Anything exported (or for non-chrooted scripts globally defined) variables in the configuration files.
* Global or exported variables from previously executed scripts.

Note that chrooted scripts loose all global variables and can only access exported ones.

Error Handling
--------------

Error handling is provided within the shell.
Command failures are tracked with `trap <func> ERR`, meaning that as soon as any command ends with a non-zero exit status, the shell jumps to the function `<func>`

Cleanup tasks can be added to this error-handler with the shell-function `on_error "<str>"`.
This function adds the string `<str>` to a stack, and in case of an error they get popped from the stack and evaluated in reverse order, i.e. the command that was added to the stack the latest gets executed first.

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

### Configuration inside Chroot Scripts

If you want to use these configuration parameters inside a chrooted script, 
make sure to export them into the environment variables first, since chrooting opens a new shell and therefore loses all local variables.

Hooks
-----

The images allow for configuration inside their directories.

There are two types of hooks:

* pre and post command hooks: these are additional scripts executed in a command
* command chains: these allow executing another command after one has finished 

### Pre and Post Hooks

Images can hook into the commands via `roots/<ID>/hooks/<command>/pre`
and `post`.
Everything in `pre` gets executed before the scripts in `hooks/<command>/<machinetype>`, 
everything in `post` afterwords.

### Command Chaining

To execute a command after another command has finished, one can specify multiple commands in `roots/<ID>/hooks/<command>/chain`
that then get executed after command`, with a completely new environment (i.e. global variables are lost, and the cleanup-routines have been executed).
Each chained command has its own line (they are newline-separated)

![A flowchart of all configuration files, hooks and command chains](graph/Scripts.png)

Logging
-------

Logging is done in the directory specified in the config files.
This is `roots/<ID>/logs/<command>/` by default, but may be changed globally or on a per-image basis.

Every script that is executed generates its own log-file, into which its stdout and stderr are piped.
For example, if a command contains a script called `00-setup.sh`, its output will be written to the file `roots/<ID>/logs/<command>/00-setup.sh.log`.

Periodic Updates
----------------

A periodic update is a periodic call to `exec.sh /path/to/.gentoo update` for every .gentoo inside the `roots/` folder.
This can be and is usually done with a cronjob, a short shell-script that gets executed at certain times by a system daemon.
A reference implementation of such a script is provided in the BuildServer under `example_scripts/cronjob.sh`

Limitations
--------

### Security

The BuildServer has no security considerations.
Therefore, one should *not* run it on any untrusted .gentoo directories.
A possible attack vector is a malicious Ebuild inside the .gentoo that could for example write to `/dev/sda`, resulting in the changes propagating to the host system. Hence, not only the image but also the host system can be compromised.

### Cross Architecture Build

Cross-building for another architecture is not supported, since some scripts are chrooted to the image root.
If the bash-executable of this image is in a binary format that the host machine can not execute, this chrooting will fail.

This is not a severe limitation, since nearly all recent machines run on the X86_64 architecture ([ScienceCloud](https://s3itwiki.uzh.ch/display/clouddoc/Science+Cloud+Hardware), [Amazone AWS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#instance-hardware-specs), and [Travis CI](https://docs.travis-ci.com/user/reference/precise/) all run on X86_64).

Further Work
------------

While the BuildServer is designed to be as flexible as possible to adapt to non-anticipated scenarios, there are some possibilities for extending the work:

### Web-Interface

Write a Web-interface to make adding new .gentoo directories easier.
This might be as simple as a file-upload for an Ebuild and adding additional meta-information and hooks.

### Security Improvements

Provide the BuildServer as a service for untrusted users, i.e. make it secure such that users can not break out of the context of their images.

### Efficiency improvement

Try to reduce the calculation overhead. Many programs will be compiled multiple times with identical parameters (USE flags, dependencies, etc), even across images.
This overhead could be reduced, e.g. by using ccache (avoids recompiling individual .c-files) or some work on Portage binary packages (saves all files generated by an individual package inside a compressed archive)
