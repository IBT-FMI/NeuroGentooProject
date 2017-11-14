#!/bin/bash

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

chmod -R g+rw "${EPREFIX}"
chgrp -R "${GROUP}" "${EPREFIX}"
find "${EPREFIX}" -type d -exec chmod g+s '{}' '+'
sed -i 's/RETAIN="/RETAIN="PORTAGE_USERNAME=$USER /; /^EPREFIX/i umask g+rwx' "${SCRIPT}"

