#!/usr/bin/env bash

EPREFIX=${1:-$HOME/gentoo/}

mkdir .debug
mkdir ${EPREFIX}/etc/portage/repos.conf

echo ""
echo "Preparing Environment:"
echo "~~~~~~~~~~~~~~~~~~~~~~"
export FEATURES="-news"
echo 'ACCEPT_KEYWORDS="~amd64"' >> ${EPREFIX}/etc/portage/make.conf
echo 'ACCEPT_LICENSE="*"' >> ${EPREFIX}/etc/portage/make.conf
echo 'EMERGE_DEFAULT_OPTS="--quiet-build"' >> ${EPREFIX}/etc/portage/make.conf
emerge --sync >> .debug/emerge_sync.txt
emerge -n dev-vcs/git wgetpaste eix gentoolkit
cat <<-EOF >> "${EPREFIX}/etc/portage/repos.conf"

[neurogentoo]
location = ${EPREFIX}/usr/local/portage/neurogentoo
sync-type = git
sync-uri = https://github.com/TheChymera/neurogentoo.git
priority=8888
EOF
cat <<-EOF >> "${EPREFIX}/etc/portage/repos.conf"

[science]
location = ${EPREFIX}/usr/local/portage/science
sync-type = git
sync-uri = https://github.com/gentoo-science/sci.git
priority = 7777
EOF
emaint sync --repo science
emaint sync --repo neurogentoo 
eix-update

#Link to the workaroud we reproduce in this section : https://wiki.gentoo.org/wiki/User_talk:Houseofsuns#Migration_to_science_overlay_from_main_tree
#Efforts to more permanently address the issue: https://github.com/gentoo/sci/issues/805
echo ""
echo "Setting Up Eselect for Gentoo Science:"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
cp ".gentoo/files/sci-lapack" "${EPREFIX}/etc/portage/package.mask/"
emerge --oneshot --verbose app-admin/eselect::science >> /dev/null
FEATURES="-preserve-libs":$FEATURES emerge --oneshot --verbose sci-libs/blas-reference::science
eselect blas set reference
FEATURES="-preserve-libs":$FEATURES emerge --oneshot --verbose sci-libs/cblas-reference::science
eselect cblas set reference
FEATURES="-preserve-libs":$FEATURES emerge --oneshot --verbose sci-libs/lapack-reference::science
eselect lapack set reference
FEATURES="-preserve-libs":$FEATURES emerge --oneshot --verbose --exclude sci-libs/blas-reference --exclude sci-libs/cblas-reference --exclude sci-libs/lapack-reference `eix --only-names --installed --in-overlay science`

emerge -1qv @preserved-rebuild
