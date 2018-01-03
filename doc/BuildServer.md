Build Server
============

![The layout of the BuildServer. The user starts exec.sh with parameters, which first asks an utility function getID (in diamond shape) for the .gentoo-ID corresponding to the folder, executes all scripts within the corresponding scripts folder. These scripts work on the image in roots/<ID>](graph/BuildServer.png)

The BuildServer is an infrastructure that generates Gentoo Linux images, based on a collection of shell-scripts that automate the creation, maintenance and format changes (e.g. to Docker or OpenStack formats) of these systems.

The functionality of the BuildServer is accessed via the `exec.sh` script, which parses the command-line parameters `exec.sh </path/to/.gentoo or stemgentoo> <command> [machinetype]`

The image roots and metadata for the images are always stored in the folder `roots` relative to the current working directory.
To store them in a specific directory, a directory change (`cd`) is required prior to running `exec.sh`.

Each Gentoo-System is stored in a directory `$PWD/roots/<ID>/root/`.
`<ID>` is one of:
* `stemgentoo`
* The .gentoo-ID corresponding to the `.gentoo`-directory the image is based off

The stemgentoo is not based on a .gentoo-directory, hence it does not have a regular ID.

Prerequisites
-------------

* Bash version >=4.2
* [dracut](https://dracut.wiki.kernel.org/index.php/Main_Page) for openstack images
* [syslinux](http://www.syslinux.org/) for openstack images
* Portage
* Python

Why Bash?
---------

Bash has some properties that make it useful in the context of building images:

* It allows easy creation of processes and redirection of their input/output streams to different sources/sinks. This is especially useful since image-building is very process-heavy (i.e. most of the tasks are solely: execute program A, then program B, etc.).
* It is widely understood; many people can write shell-scripts at least to a certain degree.
* It provides error-handling primitives which can stop the execution of scripts when any subprogram fails.


Roots Directory
---------------

The `$PWD/roots` directory contains all the images tracked by the BuildServer inside a directory named after their .gentoo ID, i.e. `$PWD/roots/<ID>`.
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

The machine type decides which set of scripts get executed.
Currently, there are two machine types defined:
* stemgentoo
* default

The default machine type images are based off the stemgentoo image available when initializing them, and stemgentoo images are based off the most current amd64 stage3 tarball provided on <https://gentoo.org>

Commands
--------

The commands are defined in the `scripts/` directory. To execute `command` for
a machine of type `machinetype` `exec.sh </path/to/.gentoo> <command> <machinetype>` is invoked.
This results in all scripts in `scripts/command/machinetype/` being executed in lexical order.

Scripts
-------

Scripts are executable bash scripts stored in `scripts/command/machinetype/`.
If their name ends in `.chroot`, the BuildServer will chroot to the corresponding image
before executing the commands, otherwise the BuildServer will source them and execute the command in the host machines context

The script directory may also contain other directories (or a symlink to a directory).
If execution reaches this directory, all executable files contained therein will be executed.

### Variables

The scripts have access to certain environment and global variables:

* `STAGE`: The current command executed, e.g. `update`
* `MACHINE`: The image ID currently being processed
* `MACHINETYPE`: The machine type of the current image, e.g. `stemgentoo`
* `ROOT`: The absolute directory to the image root
* Anything exported (or for non-chrooted scripts globally defined) variables in the configuration files.
* Global or exported variables from previously executed scripts.

Note that chrooted scripts lose access to all global variables and can only access exported ones.

Error Handling
--------------

Error handling is provided within the shell.
Command failures are tracked with `trap <func> ERR`, meaning that as soon as any command ends with a non-zero exit status, the shell jumps to the function `<func>`

The BuildServer sets up such a function (`error_exit`), that evaluates and executes strings stored inside a stack datastructure.
If for example a file should be deleted on error, one can add the string `"rm ${FILE}"` to this stack.
This can be done with a convenience function `on_error "<str>"`, that pushes the string `<str>` to the error-handling stack.
By using a stack, it is ensured that the last pushed command will be executed first.

![The error handling stack, where the function on_error pushes a new string and error_exit pops and evaluates all the strings.](graph/Error_Stack.png)

Cleanup
-------

Cleanup works exactly the same as error-handling, but it gets executed always before exiting the shell,
and cleanup are added with `on_exit "<str>"` to their own stack.

In case of an error, first the cleanup-stack and then the error-stack get processed.

Configuration
-------------

Configuration files are shell-scripts that end in `.conf`.
They get sourced just before executing the command scripts.
The following directories are searched for `.conf` files.
* `config/` in the build-server root
* `roots/<ID>/config/`

### Configuration inside Chroot Scripts

To access configuration variables inside chrooted scripts (i.e. scripts that end in `.chroot`) they should be exported into the environment variables, since chrooting opens a new shell and therefore loses all local variables.

Hooks
-----

There are two types of hooks:

* pre and post command hooks: these are additional scripts executed in a command
* command chains: these allow executing another command after one has finished 

### Pre and Post Hooks

Image building commands can be extended by prepending or appending additional scripts placed in the relevant "hooks" directories: `roots/<ID>/hooks/<command>/pre`
and `roots/<ID>/hooks/<command>/post`.
Everything in `pre` gets executed before the scripts in `hooks/<command>/<machinetype>`, 
everything in `post` afterwords.

### Command Chaining

To link commands together (e.g. to execute `openstack_image` after `update`), one can specify multiple follow-up commands in `roots/<ID>/hooks/<command>/chain`
that then get executed after `command` has finished, with a completely new environment (i.e. global variables are lost, and the cleanup-routines have been executed. This differentiates chaining from pre and post hooks).
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

Write a Web-interface to make adding new .gentoo directories easier and implementing a multi-user setup, where users can sign up and manage their own images, transforming the BuildServer into a service provider.
With this improved usability the accessibility for non-developers is enhanced, opening the BuildServer to a broader user base.

### Security Improvements

Provide the BuildServer as a service for untrusted users, i.e. make it secure such that users can not break out of the context of their images.
This is a necessary step to operate the BuildServer as a service to multiple users, s.t. a malicious user can not disrupt the service.

### Efficiency improvement

Try to reduce the calculation overhead. Many programs will be compiled multiple times with identical parameters (USE flags, dependencies, etc), even across images.
This overhead could be reduced, e.g. by using ccache (avoids recompiling individual .c-files) or some work on Portage binary packages (saves all files generated by an individual package inside a compressed archive)

For operation of the BuildServer at a large scale, reducing unnecessary compile time is crucial to enhance resource-efficiency and thereby reduce operational costs.
