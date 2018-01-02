BuildServer Case Examples
=========================

Setting up a Docker Image Build Server
--------------------------------------

Software is often thoroughly tested after any change has been made to its source code (Continuous Integration, CI).
There are numerous methods of testing, but a popular method are test-suites:
a collection of small test-cases that check whether the software fulfills certain demands.

Increasingly, these test-cases do not get executed on the developers computer but on a
single-purpose virtual machine instanciated for the sole purpose of testing new source code versions.
A popular infrastructure doing this is Travis CI and GitHub.

![The usual TravisCI and GitHub workflow](graph/TravisCI.png)

Prerequisites:

* A repository with a .gentoo folder, and we assume it is placed in the root of the repository.
* A BuildServer instance.


### DockerHub

First of all, we need to provide a repository for the Docker image.
This is usually DockerHub, but can be adapted to any other storage method.

To do this, you need a DockerHub account, and create a repository there.
It will be named with the scheme youruser/reponame 


### TravisCI

On the Travis side, we need to set-up the .travis.yml in the right way.

```
before_install:
  - docker pull buffepva/repositorg
  - docker create --name "repositorg" --rm -ti -v "${PWD}":/home/repositorg buffepva/repositorg
  - docker start repositorg
  - docker exec repositorg emaint sync -a
  - docker exec repositorg /home/repositorg/.gentoo/install.sh -o
install:
  - docker exec repositorg sh -c 'FEATURES="-test" /home/repositorg/.gentoo/install.sh'
script:
  - docker exec repositorg sh -c 'FEATURES="test" /home/repositorg/.gentoo/install.sh'
```

### BuildServer

We need to instantiate the BuildServer image first:

* `cd /path/to/build/server`
* `./exec.sh /path/to/repository/.gentoo/ initialize`

This creates a new root with id `$ID`

Then we need to set-up that after every update the BuildServer must build
a Docker image and upload it to DockerHub.

* `mkdir roots/$ID/hooks/docker_image/post/ roots/$ID/hooks/update/`
* `echo docker_image >> roots/$ID/hooks/update/chain`
* `cp example_hooks/docker_image/post/30-upload_dockerimage.sh roots/$ID/hooks/docker_image/post/`
* Adapt the variables in `roots/$ID/hooks/docker_image/post/30-upload_dockerimage.sh`

Now the command `docker login dockerhub.com` has to be used to add the DockerHub account credentials to the local Docker server

To upload this image for the first time now, execute
`./exec.sh /path/to/repository/.gentoo update`
If all goes well, a new image should be uploaded to the DockerHub account.

Generating and uploading OpenStack images
-----------------------------------------

The BuildServer includes a command to generate OpenStack images, but uploading has to be done with hooks again.

### Prerequisites

* An account at a OpenStack host
* An instantiated BuildServer

### BuildServer

* Instantiate the image with `exec.sh </path/to/.gentoo> initialize`
* Copy the example hook for openstack upload from `example_hooks/openstack_image/60-upload_image.sh` to the newly generated `roots/<ID>/hooks/openstack_image/post/`
* Adapt the necessary variables in `60-upload_image.sh`
* Add the `openstack_image` to the update-chain, i.e.
	```
	echo openstack_image >> roots/<ID>/hooks/update/chain
	```

### Configuration
With the variable `OPENSTACK_FILESYSTEM=<FS>` one can configure the filesystem used by the openstack images.

Note: `mkfs.<FS>` has to exist, and extlinux must work with it, since it is used as a bootloader on the image.

Additionally `OPENSTACK_FILESYSTEM_OPTS` can be set to pass parameters to `mkfs.<FS>`

Other parameters include the root password and the name of the generated openstack image.
