#!/bin/bash

if [[ -v DELETE_ON_FAIL ]]; then on_error "rm --one-file-system -r '${ROOT%root}'"; fi

cp --reflink -r roots/stemgentoo/root/ "${ROOT}"
