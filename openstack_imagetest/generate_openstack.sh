#!/bin/bash

function debug(){
	echo $@
}

function cleanup(){
	popd
	debug "Unmounting Stuff"
	umount gentoo/{dev/pts,dev,var/tmp/portage,proc,sys,usr/portage}
	
	debug "unmounting image"
	umount gentoo/
	
	[ -n "$LODEV" ] && losetup -d "$LODEV"
}

function clean_exit(){
	trap - ERR
	cleanup
	exit 1
}
trap clean_exit ERR

GENTOO_MIRROR="http://distfiles.gentoo.org/releases/amd64/autobuilds"
IMG_SIZE="4G"

NUM_CPU=$(awk '/processor/ {i++} END {print i}' < /proc/cpuinfo)

debug "Generating Image using mirror ${GENTOO_MIRROR}"


debug "Creating ./gentoo/"
mkdir gentoo

debug "creating gentoo.img with size $IMG_SIZE"
fallocate -l "$IMG_SIZE" gentoo.img

debug "Setting up loopback"
LODEV="$(losetup --show -f gentoo.img)"
debug "Got loopback $LODEV"

debug "Setting up partition table"
sfdisk $LODEV <<-EOF
label: dos
- - L *
EOF

debug "Copying syslinux MBR"
dd if=/usr/share/syslinux/mbr.bin "of=$LODEV" conv=notrunc bs=440 count=1
partx -u "$LODEV"

debug "Formatting the disk with ext4"

#Syslinux can't handle 64bit, so we disable it.
#This has the effect, that our root partition can't grow larger than 2TB
mkfs.ext4 -O ^64bit -L NeuroGentoo "${LODEV}p1"

UUID="$(dumpe2fs /dev/loop0p1 | sed -n 's/.*UUID:[[:space:]]\+\([a-z0-9\-]\+\).*/\1/p')"

debug "Mounting the partition under ./gentoo/"
mount -t ext4 "${LODEV}p1" gentoo/


debug "Fetching which is the newest gentoo stage3"
file="$(curl "${GENTOO_MIRROR}/latest-stage3-amd64.txt" | sed -n 's/\(\+*\.tar\.bz2\).*/\1/p')"
filename="${file##*/}"
debug "it is ${file}, downloading ${GENTOO_MIRROR}/${file} -> ${filename}:"
[ -f "${filename}" ] || curl -o "${filename}" "${GENTOO_MIRROR}/${file}"

debug "Unpacking archive to ./gentoo/" 
tar xvjf "${filename}" -C gentoo/

debug "Moving kernel config"
cp kernel.config gentoo/


debug "Setting up ./gentoo/ for chrooting"
pushd gentoo
debug "Copying resolv.conf"
cp -L /etc/resolv.conf etc/resolv.conf
debug "bind-mount /usr/portage to usr/portage/"
mkdir usr/portage
mount --bind /usr/portage usr/portage
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


PKGS="gentoo-sources openssh syslog-ng cloud-init"
cat <<-EOF > ./gentoo/script.sh
#!/bin/bash

function debug(){
	echo \$@
}

set -e


debug "Setting makeopts to -j$NUM_CPU"
echo 'MAKEOPTS="-j${NUM_CPU}"' >> /etc/portage/make.conf

debug "Setting timezone to UTC"
echo "UTC" > /etc/timezone
cp /usr/share/zoneinfo/UTC /etc/localtime

debug "Updateing portage (if necessary)"
emerge -uNq portage
debug "Updateing world"
emerge -uNDqv world


debug "Emerging $PKGS"
emerge -qv $PKGS

debug "Setting up services"
for s in sshd syslog-ng cloud-init
do
	rc-update add \$s default
done

mv kernel.config /usr/src/linux/.config
pushd /usr/src/linux/
make alldefconfig
make -j${NUM_CPU} 
make modules_prepare
make modules_install
make install
popd

pushd /boot/
ln -s vmlinuz-* vmlinuz
popd

EOF


chmod 755 ./gentoo/script.sh

debug "Chrooting to ./gentoo/"
chroot gentoo/ /script.sh

KERNEL="$(readlink gentoo/usr/src/linux)"
KERNELVERSION="${KERNEL%-*}"
KERNELVERSION="${KERNELVERSION#*-}"

debug "Copying syslinux files"
mkdir gentoo/boot/syslinux
cp /usr/share/syslinux/{menu.c32,memdisk,libcom32.c32,libutil.c32} gentoo/boot/syslinux/

debug "Installing extlinux"
extlinux --device="${LODEV}p1" --install gentoo/boot/syslinux/

debug "Writing bootloader, booting from UUID $UUID"
cat <<-EOF > gentoo/boot/syslinux/syslinux.cfg
DEFAULT gentoo
LABEL gentoo
      LINUX /boot/vmlinuz root=UUID=$UUID rootfstype=ext4
      INITRD /boot/initramfs
EOF

debug "Writing fstab root-entry"
cat <<-EOF >> gentoo/etc/fstab
UUID=$UUID		/		ext4		noatime		0 1
EOF

INITRAMFS="./gentoo/boot/initramfs-$KERNELVERSION"
debug "Generating initramfs $INITRAMFS"
dracut --no-kernel -m "base rootfs-block" "$INITRAMFS" "$KERNELVERSION"
ln -s "initramfs-$KERNELVERSION" "./gentoo/boot/initramfs"

cleanup
