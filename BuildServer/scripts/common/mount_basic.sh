#!/bin/bash

function unmount_basic(){
	pushd "${ROOT}"
	function um(){
		debug "unmounting $1"
		umount $1
	}
	um dev/pts
	um dev
	um proc
	um sys
	um var/tmp/portage
	popd
}
export -f unmount_basic
on_exit unmount_basic

pushd "${ROOT}"
debug "bind-mount /dev to dev/"
mount --bind /dev/ dev
debug "mount proc/"
mount -t proc none proc
debug "mount sys/"
mount -t sysfs none sys
debug "mount devpts with gid=5 for glibc[-suid] at /dev/pts/"
mount -t devpts -o gid=5 none dev/pts/
debug "mount tmpfd on /var/tmp/portage"
mkdir -p var/tmp/portage
mount -t tmpfs -o size=4G none var/tmp/portage
popd
