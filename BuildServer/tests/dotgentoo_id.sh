#!/bin/bash

ID1="$(get_dotgentoo_id "${ROOT_DIR}/tests/dotgentoos/.gentoo1")"
ID2="$(get_dotgentoo_id "${ROOT_DIR}/tests/dotgentoos/.gentoo2")"

if [ "$ID1" != "$ID2" ]
then
	error "IDs of two should-be identical .gentoos do not match"
	RET=1
fi
