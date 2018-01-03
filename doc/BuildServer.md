Build Server
============

![The layout of the BuildServer. The user starts exec.sh with parameters, which executes all scripts within the corresponding scripts folder. These scripts work on the image in roots/<ID>](graph/BuildServer.png)
!!! Please explain/reference (since you already explained it) what getID is, and why it gets its own node shape.

The BuildServer is an infrastructure that generates Gentoo Linux images, based on a collection of shell-scripts that automate the creation, maintenance and format changes of these systems.
!!! what do you mean by format changes?

The functionality of the BuildServer is accessed via the `exec.sh` script, which parses the command-line parameters `exec.sh </path/to/.gentoo or stemgentoo> <command> [machinetype]`

Files required for the generation or formatting of a new Gentoo Image are always stored relative to the current working directory.
!!! Where relative to the current wd?
If you want to have the images in a specific directory, you have to `cd` into them.
!!! less “you”

Each Gentoo-System is stored in a directory `$PWD/roots/<ID>/root/`.
`<ID>` is one of:
* `stemgentoo`
* An ID corresponding to the `.gentoo`-directory the image is based off
!!! PErhaps mention that this is the checksum ID you previously mentioned, also explain what stemgentoo is and why we opt to treat it differently.§

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
* It is widely understood, so that many people can write shell-scripts at least to a certain degree.
* It provides error-handling primitives which can stop the execution of scripts when any subprogram fails.

!!! When you create an item list, there has to be a significant degree of similarity between the items:

* If the list is about the advantages of Bash all items should be explicitly referring to bash.
* If one item is capitalized and is a sentence and ends in a period al should.


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
before executing the commands.
!!! Otherwise?
If it is a directory (or a symlink to a directory), all executable files contained
therein will be executed.
!!! An executable bash script cannot be a directory, please restructure your if statements

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

Cleanup tasks can be added to this error-handler with the shell-function `on_error "<str>"`.
This function adds the string `<str>` to a stack, and in case of an error they get popped from the stack and evaluated in reverse order, i.e. the command that was added to the stack the latest gets executed first.
!!! this needs a lengthier explanation

Cleanup
-------

Cleanup works exactly the same as error-handling, but it gets executed always before exiting the shell,
and functions are added with `on_exit "<str>"`

In case of an error, first the cleanup-stack and then the error-stack get processed.
!!! this needs a lengthier explanation, e.g. functions are added to what?

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
!!! no “you”

Hooks
-----

The images allow for configuration inside their directories.
!!!wasn't configuration the previous point? if you mean something different here, change the wording.

There are two types of hooks:

* pre and post command hooks: these are additional scripts executed in a command
* command chains: these allow executing another command after one has finished 

### Pre and Post Hooks

Image building commands is extended by prepending or appending additional scripts placed in the relevant “hooks” directories: `roots/<ID>/hooks/<command>/pre`
and `roots/<ID>/hooks/<command>/post`.
Everything in `pre` gets executed before the scripts in `hooks/<command>/<machinetype>`, 
everything in `post` afterwords.

### Command Chaining

To execute a command after another command has finished, one can specify multiple commands in `roots/<ID>/hooks/<command>/chain`
that then get executed after command`, with a completely new environment (i.e. global variables are lost, and the cleanup-routines have been executed).
Each chained command has its own line (they are newline-separated)
!!! This needs to be better explained, I only understood what you meant after looking at the figure.

![A flowchart of all configuration files, hooks and command chains](graph/Scripts.png)
!!!Isn't `$PWD/roots/<ID>` also on the buildserver? if you want to make a distinction between the BuildServer system and the eponympus directory, please refer to them with unambiguous formulations.

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
!!! Please formulate the description in a more context-aware fashion (this isn't just a presentation where you list possible-to do statements). Writing a web interface would improve outreach/usability/accessibility/etc
This might be as simple as a file-upload for an Ebuild and adding additional meta-information and hooks.

### Security Improvements

Provide the BuildServer as a service for untrusted users, i.e. make it secure such that users can not break out of the context of their images.

### Efficiency improvement

Try to reduce the calculation overhead. Many programs will be compiled multiple times with identical parameters (USE flags, dependencies, etc), even across images.
This overhead could be reduced, e.g. by using ccache (avoids recompiling individual .c-files) or some work on Portage binary packages (saves all files generated by an individual package inside a compressed archive)
