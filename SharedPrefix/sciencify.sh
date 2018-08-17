#!/usr/bin/env bash
set -e

if $1 == "eprefix"; then
	EPREFIX=${1:-$HOME/gentoo/}
else
	EPREFIX=""
fi

mkdir ${EPREFIX}/etc/portage/repos.conf

echo ""
echo "Preparing Environment:"
echo "~~~~~~~~~~~~~~~~~~~~~~"
echo 'ACCEPT_KEYWORDS="~amd64"' >> ${EPREFIX}/etc/portage/make.conf
echo 'ACCEPT_LICENSE="*"' >> ${EPREFIX}/etc/portage/make.conf
emerge -n dev-vcs/git 
cat <<-EOF >> "${EPREFIX}/etc/portage/repos.conf"

[science]
location = ${EPREFIX}/var/repos/science
sync-type = git
sync-uri = https://github.com/gentoo-science/sci.git
priority = 7777
EOF
emaint sync --repo science
eix-update
./lapack-sci.sh
