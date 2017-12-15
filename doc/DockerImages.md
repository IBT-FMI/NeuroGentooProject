Docker Images
=============

Setting up Docker images for TravisCI testing.

Prerequisites: You need a repository with a .gentoo folder, and we assume
it is placed in the root of the repository.


DockerHub
---------

First of all, we need to provide a repository for the Docker image.
This is usually DockerHub, but can be adapted to any other storage method.

To do this, you need a DockerHub account, and create a repository there.
It will be named with the scheme youruser/reponame 


TravisCI
--------

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

BuildServer
-----------

We need to instantiate the BuildServer image first:

* `cd /path/to/build/server`
* `./exec.sh /path/to/repository/.gentoo/ initialize`

This creates a new root with id `$ID`

Then we need to set-up that after every update the BuildServer must build
a Docker image and upload it to DockerHub.

* `mkdir roots/$ID/scripts/docker_image/post/ roots/<ID>/actionchain/post/`
* `echo docker_image >> roots/$ID/actionchain/post/update`
* `cp example_hooks/docker_image/post/30-upload_dockerimage.sh roots/$ID/scripts/docker_image/post/`
* Adapt the necessary variables in `roots/$ID/actionchain/post/30-upload_dockerimage.sh`

Now you have to provide the credentials to the local Docker commands with `docker login dockerhub.com`

To upload this image for the first time now, execute
* `./exec.sh /path/to/repository/.gentoo update`
If all goes well, you should have a brand-new image uploaded to your DockerHub
