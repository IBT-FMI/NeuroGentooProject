#!/bin/bash

debug "Setting up the specialization-set"
DEPSFILE="${ROOT}/../.gentoo/deps"
SPECFILE="${ROOT}/etc/portage/sets/specialization"
ensure_dir "${SPECFILE%/*}"
if [ -f "${DEPSFILE}" ]
then
	debug "Copying the set"
	cp "${DEPSFILE}"  "${SPECFILE}"
else
	debug "Creating an empty set"
	touch "${SPECFILE}"
fi

debug "Setting up the additional repos"
ensure_dir "${ROOT}/etc/portage/repos.conf"
for file in "${ROOT}/../.gentoo/overlays/"*
do
	if [ -f "$file" ]; then cp "$file" "${ROOT}/etc/portage/repos.conf/"; fi
done
