Generating OpenStack from Stage3
================================

Here we generate a raw .img file for OpenStack.

Problems
--------

1. We have to chroot into the new directory. If we used the host `emerge`, 
	we would get difficulties with e.g. libtool, since it uses absolute paths to reference the dynamic libraries it generates
	To do that, we generate an extra script-file `gentoo/script.sh`, which we execute with `chroot gentoo /script.sh`
2. We need a kernel suitable for booting in KVM or XEN VServers. 
	* for KVM-disks: 
		```
		CONFIG_SATA_PMP=y
		CONFIG_SATA_AHCI=y
		```
	* for serial console: 
		```
		CONFIG_SERIAL_8250=y 
		CONFIG_SERIAL_8250_CONSOLE=y
		CONFIG_SERIAL_8250_PCI=y
		```
	* Virtio-Drivers
		```
		CONFIG_BLK_MQ_VIRTIO=y
		CONFIG_VIRTIO_BLK=y
		CONFIG_VIRTIO_BLK_SCSI=y
		CONFIG_SCSI_VIRTIO=y
		CONFIG_VIRTIO_NET=y
		CONFIG_VIRTIO_CONSOLE=y
		CONFIG_HW_RANDOM_VIRTIO=y
		CONFIG_VIRTIO=y
		CONFIG_VIRTIO_PCI=y
		CONFIG_VIRTIO_PCI_LEGACY=y
		CONFIG_VIRTIO_BALLOON=y
		# CONFIG_VIRTIO_INPUT is not set
		CONFIG_VIRTIO_MMIO=y
		# CONFIG_VIRTIO_MMIO_CMDLINE_DEVICES is not set
		CONFIG_CRYPTO_DEV_VIRTIO=y
		```
	* Linux Guest support:
		```
		CONFIG_HYPERVISOR_GUEST=y
		CONFIG_XEN=y
		CONFIG_XEN_PV=y
		CONFIG_XEN_PV_SMP=y
		# CONFIG_XEN_DOM0 is not set
		CONFIG_XEN_PVHVM=y
		CONFIG_XEN_PVHVM_SMP=y
		CONFIG_XEN_512GB=y
		CONFIG_XEN_SAVE_RESTORE=y
		# CONFIG_XEN_PVH is not set
		CONFIG_KVM_GUEST=y
		```
	* XEN Drivers: 
		```
		CONFIG_XEN_PCIDEV_FRONTEND=y
		CONFIG_XEN_BLKDEV_FRONTEND=y
		# CONFIG_XEN_SCSI_FRONTEND is not set
		CONFIG_XEN_NETDEV_FRONTEND=y
		CONFIG_HVC_XEN=y
		CONFIG_HVC_XEN_FRONTEND=y
		CONFIG_XEN_BALLOON=y
		CONFIG_XEN_SCRUB_PAGES=y
		CONFIG_XEN_DEV_EVTCHN=y
		CONFIG_XENFS=y
		CONFIG_XEN_COMPAT_XENFS=y
		CONFIG_XEN_SYS_HYPERVISOR=y
		CONFIG_XEN_XENBUS_FRONTEND=y
		CONFIG_XEN_GNTDEV=y
		CONFIG_XEN_GRANT_DEV_ALLOC=y
		CONFIG_SWIOTLB_XEN=y
		CONFIG_XEN_PRIVCMD=y
		CONFIG_XEN_ACPI_PROCESSOR=y
		CONFIG_XEN_HAVE_PVMMU=y
		CONFIG_XEN_AUTO_XLATE=y
		CONFIG_XEN_ACPI=y
		CONFIG_XEN_HAVE_VPMU=y
		```
	* KVM Drivers:
		```
		CONFIG_E1000=m
		```
3. Mount /dev/pts with devpts gid=5, which is needed for glibc[-suid]
4. Mount /var/tmp/portage as tmpfs, since we will use up our disk during compilation otherwise
