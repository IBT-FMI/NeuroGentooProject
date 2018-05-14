#!/bin/bash

echo "WARNING! This script is documented to potentially break Portage. See https://github.com/IBT-FMI/NeuroGentooProject/issues/16 for further details. Edit the script to proceed only if you know what you are doing."

exit 1

if [ "$1" == "-h" -o "$1" == "--help" ]
then
	echo "Usage: $0 [group] [prefix-directory] [start-script]"
	cat <<-EOF
Shares the prefix in <prefix-directory> with every member of group <group>,
using <start-script> as startprefix-script
EOF
	exit 0
fi

GROUP="${1:-gentoo}"
EPREFIX="${2:-$HOME/gentoo}"
SCRIPT="${3:-$EPREFIX/startprefix}"

FAIL=false
if [ ! -d "${EPREFIX}" ]
then
	FAIL=true
	echo "${EPREFIX} is not a directory"
	stat "${EPREFIX}"
fi

if [ ! -f "${SCRIPT}" ]
then
	FAIL=true
	echo "${SCRIPT} does not exist"
	stat "${SCRIPT}"
fi

if ! grep "${GROUP}" /etc/group > /dev/null
then
	FAIL=true
	echo "group ${GROUP} does not exist"
fi

if $FAIL
then
	exit 1
fi

echo "Making prefix group-read/writeable"
chmod -R g+rw "${EPREFIX}"
echo "changing group of prefix to ${GROUP}"
chgrp -R "${GROUP}" "${EPREFIX}"
echo "Setting the sticky-bit in prefix"
find "${EPREFIX}" -type d -exec chmod +s '{}' '+'
echo "Modifying the start_gentoo script ${SCRIPT}"
sed -i 's/RETAIN="/RETAIN="PORTAGE_USERNAME=$USER PORTAGE_GRPNAME=gentoo/; /^EPREFIX/i umask g+rwx' "${SCRIPT}"
echo "Adding FEATURES=unprivileged to make.conf"
echo 'FEATURES="${FEATURES} unprivileged"' >> "${EPREFIX}/etc/portage/make.conf"
