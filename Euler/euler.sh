#!/bin/bash

EPREFIX=${EPREFIX:-${SCRATCH}/gentoo}

cat >>~/.bashrc <<-EOF
export -n LD_LIBRARY_PATH
unset LD_LIBRARY_PATH
EOF

pushd ${EPREFIX}/lib/
ln -s /usr/lib64/libnss_sss.so* .
cd ../etc/
mv nsswitch.conf nsswitch.conf.bk
ln -s /etc/nsswitch.conf .
popd
