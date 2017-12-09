#!/bin/bash

set -e

function prepare_euler(){
	cat >>~/.bashrc <<-EOF
export -n LD_LIBRARY_PATH
unset LD_LIBRARY_PATH
EOF

	for b in 32 64
	do
		dir="${EPREFIX}/lib${b}/"
		mkdir -p "${dir}"
		ln -s -t "${dir}" /usr/lib${b}/libnss_sss.so* 
	done

	mkdir "${EPREFIX}/etc"
	cp -L /etc/nsswitch.conf "${EPREFIX}/etc/"
}

if [ "$1" == "-h" -o "$1" == "--help" ]
then
	echo "Usage: $0 [/path/to/prefix]"
	exit 0
fi

EPREFIX="${1:-${SCRATCH}/gentoo}"

prepare_euler
cd "$SCRATCH"
wget "https://dev.gentoo.org/~heroxbd/bootstrap-rap.sh"
chmod a+x bootstrap-rap.sh
./bootstrap-rap.sh "${EPREFIX}" "noninteractive"
