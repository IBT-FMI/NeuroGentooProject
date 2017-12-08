#!/bin/bash

EPREFIX=${1:-${SCRATCH}/gentoo}

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
cp -L /etc/nsswitch.conf "${EPREFIX}/etc/"
