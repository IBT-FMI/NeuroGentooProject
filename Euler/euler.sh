#!/bin/bash

set -e

if [[ "$1" == "-h" -o "$1" == "--help" ]]
then
	echo "Usage: $0 [/path/to/prefix]"
	exit 0
fi

EPREFIX="${1:-${SCRATCH}/gentoo}"

"${0%/*}/prepare_euler.sh" "${EPREFIX}"
cd "$SCRATCH"
wget "https://dev.gentoo.org/~heroxbd/bootstrap-rap.sh"
chmod a+x bootstrap-rap.sh
./bootstrap-rap.sh "${EPREFIX}" "noninteractive"
