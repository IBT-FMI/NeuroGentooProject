#!/bin/bash

function debug(){
	echo $@
}

function cleanup(){
	debug "Unmounting Stuff"
	umount gentoo/{dev,proc,sys,usr/portage}
	
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
partprobe "$LODEV"
mkfs.ext4 -L NeuroGentoo "${LODEV}p1"
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
emerge -1nq portage
debug "Updateing world"
emerge -uNDqv world


debug "Emerging $PKGS"
emerge -qv $PKGS

debug "Setting up services"
for s in sshd syslog-ng cloud-init cloud-final cloud-config cloud-init-local
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

debug "Copying syslinux files"
mkdir gentoo/boot/extlinux/
cp /usr/share/syslinux/{menu.c32,memdisk,libcom32.c32,libutil.c32} gentoo/boot/extlinux/

debug "Installing extlinux"
extlinux --device="${LODEV}" --install gentoo/boot/

cat <<-EOF > gentoo/boot/extlinux/extlinux.cfg
DEFAULT gentoo
LABEL gentoo
      LINUX /boot/vmlinuz
EOF


cleanup