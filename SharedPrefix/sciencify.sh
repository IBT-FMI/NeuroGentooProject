#!/usr/bin/env bash
set -e

EPREFIX="${1}"

mkdir ${EPREFIX}/etc/portage/repos.conf || echo "There already exists a ${EPREFIX}/etc/portage/repos.conf directory."

echo ""
echo "Preparing Environment:"
echo "~~~~~~~~~~~~~~~~~~~~~~"
echo 'ACCEPT_KEYWORDS="~amd64"' >> ${EPREFIX}/etc/portage/make.conf
echo 'ACCEPT_LICENSE="*"' >> ${EPREFIX}/etc/portage/make.conf
emerge -n dev-vcs/git 
if [ ! -f "${EPREFIX}/etc/portage/repos.conf/science" ]; then
cat <<-EOF >> "${EPREFIX}/etc/portage/repos.conf/science"
[science]
location = ${EPREFIX}/var/repos/science
sync-type = git
sync-uri = https://github.com/gentoo-science/sci.git
priority = 7777
EOF
emaint sync --repo science
eix-update
./lapack-sci.sh ${EPREFIX}
