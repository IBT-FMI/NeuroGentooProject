#!/bin/bash

debug "Allocating ${OPENSTACK_IMAGE_SIZE}G for $OPENSTACK_IMAGE"

fallocate -l "${OPENSTACK_IMAGE_SIZE}G" "${OPENSTACK_IMAGE}"
if [[ -v DELETE_ON_FAIL ]]; then on_error "rm ${OPENSTACK_IMAGE}"; fi

debug "Setting up loopback"
OPENSTACK_IMG_LODEV="$(losetup --show -f "${OPENSTACK_IMAGE}")"
debug "Got loopback OPENSTACK_IMG_LODEV"
on_exit "losetup -d ${OPENSTACK_IMG_LODEV}"

debug "Setting up partition table"
sfdisk $OPENSTACK_IMG_LODEV <<-EOF
label: dos
- - L *
EOF

debug "Copying syslinux MBR"
dd if=/usr/share/syslinux/mbr.bin "of=$OPENSTACK_IMG_LODEV" conv=notrunc bs=440 count=1
partx -u "$OPENSTACK_IMG_LODEV"

debug "Formatting the disk with ext4"

#Syslinux can't handle 64bit, so we disable it.
#This has the effect, that our root partition can't grow larger than 2TB
"mkfs.${OPENSTACK_FILESYSTEM}" -O ^64bit -L NeuroGentoo "${OPENSTACK_IMG_LODEV}p1"

OPENSTACK_IMG_UUID="$(blkid ${OPENSTACK_IMG_LODEV}p1 | sed -n 's/.*UUID="\([a-z0-9\-]\+\)".*/\1/p')"
