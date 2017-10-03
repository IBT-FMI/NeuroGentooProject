#!/bin/bash

source "$(dirname "$0")/utils/functions.sh"
MACHINETYPE="$3"
declare ID
if [ "$1" == "stemgentoo" ]
then
	ID="stemgentoo"
	MACHINETYPE="stemgentoo"
else
	ID="$(get_dotgentoo_id "$1")"
fi

if [ "$2" == "initialize" -a -n "roots/$ID" ]
then
	mkdir "roots/$ID"
	cp -r "$1" "roots/$ID/.gentoo"
fi

exec_scripts "$2" "$ID" "$MACHINETYPE"

clean_exit
