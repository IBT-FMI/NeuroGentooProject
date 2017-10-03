#!/bin/bash

source "$(dirname "$0")/utils/functions.sh"

ID="$(get_dotgentoo_id "$1")"

if [ "$2" == "initialize" -a -n "roots/$ID" ]
then
	mkdir "roots/$ID"
	cp -r "$1" "roots/$ID/.gentoo"
fi

exec_scripts "$2" "$ID" "$3"
