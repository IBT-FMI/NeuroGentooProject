#!/bin/bash

cp "${ROOT}/../.gentoo/deps" "${ROOT}/var/lib/portage/specialization"
ensure_dir "${ROOT}/etc/portage/repos.conf"
for file in "${ROOT}/../.gentoo/overlays/"*
do
	if [ -f "$file" ]; then cp "$file" "${ROOT}/etc/portage/repos.conf/"; fi
done
