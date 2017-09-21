How to generate images
======================


OpenStack / Science Cloud
-------------------------

Both can handle qcow2 as image, so we probably resort to these
<https://docs.openstack.org/image-guide/introduction.html>

### Requirements

* Disk partitions and resize root partition on boot (cloud-init)
* No hard-coded MAC address information
* SSH server running
* Disable firewall
* Access instance using ssh public key (cloud-init)
* Process user data and other metadata (cloud-init)
* Paravirtualized Xen support in Linux kernel (Xen hypervisor only with Linux kernel version < 3.0)

<https://docs.openstack.org/image-guide/openstack-images.html>


### Specialities

* Only one partition formatted with ext4
* Install `cloud-init` package
* Boot kernel with `console=tty0 console=ttyS0,115200n8`
* No metadata-file??


Docker
------

Generation via a Dockerfile:
<https://github.com/gentoo/gentoo-docker-images/blob/master/stage3.Dockerfile>

* `docker build` builds images from Dockerfiles.

### Dockerfile

* `FROM scratch` in our case
* `WORKDIR /`
* `ADD imageroot/ /`
* `RUN some_additional_setuptasks`
* `CMD ["/bin/bash"]`

### Build

```
docker build -f /path/to/dockerfile path/to/build/root
```

Prefix
------

To-Do
