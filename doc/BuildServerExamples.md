BuildServer Case Examples
=========================

Setting up a Continuous Integration Testing Image
-------------------------------------------------

Software is often thoroughly tested after any change has been made to its source code (Continuous Integration, CI).
There are numerous methods of testing, but a popular method are test-suites:
a collection of small test-cases that check whether the software fulfills certain demands.

Increasingly, these test-cases do not get executed on the developers' computers but on a
single-purpose virtual machine instantiated for the sole purpose of testing new source code versions.
A popular infrastructure doing this is Travis CI (which seamlessly integrates wit GitHub).

![The usual Travis CI and GitHub workflow](graph/TravisCI.png)

Prerequisites:

* A repository with a .gentoo directory compliant with the aforementioned specification placed in the root of the repository .
* A BuildServer instance.
* A continuous integration platform supporting custom image submission (the current example uses Travis CI, which supports custom docker images via a Docker-in-Docker infrastructure) 
* An image storage infrastructure (the current example uses Docker Hub, the foremost storage infrastructure for Docker images)

### Docker Hub

First of all, a repository has to be created for the Docker image.
This is usually done on Docker Hub, but can be adapted to any other storage method.

Henceforth only Docker Hub is considered.
A Docker Hub account is required, and a new repository has to be added there. It will have the naming-scheme someuser/reponame 


### Travis CI

On the Travis side, we need to set-up the .travis.yml in the right way, such that the Travis CI machine first fetches the Docker image from Docker Hub, starts the image, updates it and then installs the actual software and runs tests on it.

```
before_install:
  - docker pull someuser/reponame
  - docker create --name "reponame" --rm -ti -v "${PWD}":/home/reponame someuser/reponame
  - docker start reponame
  - docker exec reponame emaint sync -a
  - docker exec reponame /home/reponame/.gentoo/install.sh -o
install:
  - docker exec reponame sh -c 'FEATURES="-test" /home/reponame/.gentoo/install.sh'
script:
  - docker exec reponame sh -c 'FEATURES="test" /home/reponame/.gentoo/install.sh'
```

### BuildServer

On the BuildServer the single-purpose image has to be instantiated first:

* `cd /path/to/build/server/roots/../`
* `exec.sh /path/to/repository/.gentoo/ initialize`

This creates a new root with id `$ID`

Then the hooks need to be set-up, such that after every update the BuildServer builds a Docker image and uploads it to Docker Hub.

* `mkdir roots/$ID/hooks/docker_image/post/ roots/$ID/hooks/update/`
* `echo docker_image >> roots/$ID/hooks/update/chain`
* 
	```
	cp example_hooks/docker_image/post/30-upload_dockerimage.sh roots/$ID/hooks/docker_image/post/
	```
* Adapt the variables in `roots/$ID/hooks/docker_image/post/30-upload_dockerimage.sh`

Now the command `docker login dockerhub.com` has to be manually executed from the command line, in order to add the Docker Hub account credentials to the BuildServers Docker service.

To upload this image for the first time, either `exec.sh /path/to/repository/.gentoo update` or `exec.sh /path/to/repository/.gentoo docker_image` can be called
If all goes well, a new image should be uploaded to the Docker Hub account.

### Periodic Builds

To periodically upload a new image, refer to the Periodic Updates section in the BuildServer chapter.

Generating and uploading OpenStack images
-----------------------------------------

The BuildServer includes a command to generate OpenStack images, but uploading has to be done with hooks again.

### Prerequisites

* An account at a OpenStack host.
* An instantiated BuildServer

### BuildServer

First, the image has to be instantiated (alternatively, the stemgentoo can be used)

* `cd /path/to/build/server/roots/../`
* `exec.sh /path/to/repository/.gentoo/ initialize`

Then the hooks need to be set-up, such that after every update the BuildServer builds an OpenStack image and uploads it to the OpenStack server.

* `mkdir roots/$ID/hooks/docker_image/post/ roots/$ID/hooks/update/`
* `echo openstack_image >> roots/$ID/hooks/update/chain`
* 
	```
	cp example_hooks/openstack_image/60-upload_image.sh roots/$ID/hooks/openstack_image/post/
	```
* Adapt the variables in `roots/$ID/hooks/openstack_image/post/60-upload_image.sh`

### Periodic Builds

To periodically upload a new image, refer to the Periodic Updates section in the BuildServer chapter.

### Configuration
With the variable `OPENSTACK_FILESYSTEM=<FS>` the file system used by the OpenStack images can be configured.
Note: `mkfs.<FS>` has to exist, and extlinux must work with it, since it is used as a bootloader on the image.

Additionally `OPENSTACK_FILESYSTEM_OPTS` can be set to pass parameters to `mkfs.<FS>`

Other parameters include the root password and the name of the generated OpenStack image.
