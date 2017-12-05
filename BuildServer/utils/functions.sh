#!/bin/bash

ROOT_DIR="$(realpath "$(dirname "$0")")"
CACHE="${ROOT_DIR}/cache/"
export NUM_CPU="$(grep -c processor /proc/cpuinfo)"

function debug(){
	echo "$@">&2
}

function error(){
	echo -e "\e[31m$@\e[0m">&2
}

function ok(){
	echo -e "\e[32m$@\e[0m">&2
}

declare -a _on_exit;
declare -a _on_error;


export -f debug error

function on_exit(){
	_on_exit=( "$1" "${_on_exit[@]}")
}

function on_error(){
	_on_error=( "${"$1" _on_error[@]}" )
}

function error_cleanup(){
	debug "Cleaning up after error"
	for func in "${_on_error[@]}"
	do
		debug "executing $func"
		eval "$func"
	done
}

function cleanup(){
	debug "Cleaning up"
	for func in "${_on_exit[@]}"
	do
		debug "executing $func"
		eval "$func"
	done
}

function clean_exit(){
	ok "Exiting"
	trap - ERR
	cleanup
	exit 0
}

function error_exit(){
	trap - ERR
	error "Exiting"
	cleanup
	error_cleanup
	exit 1;
}

function chksum(){
	sha256sum | tr -d -c '[a-z0-9]'
}

function normalize_deps(){
	sed 's/[[:blank:]]\+//;s/#.*//g;/^$/d;' | sort | uniq
}

function normalize_overlays(){
	"${ROOT_DIR}/utils/normalize_overlays.py" "$@"
}

function normalize_packagefiles(){
	type="$1"
	shift
	if [ -f "$1" ]
	then
		"${ROOT_DIR}/utils/normalize_packagefiles.py" "$type" "$@"
	fi
}

function get_dotgentoo_id(){
	normalize_dotgentoo "$@" | chksum
}
function normalize_dotgentoo(){
	echo "#dependencies"
	normalize_deps < "$1"/deps
	echo "#overlays"
	olays=( "$1"/overlays/* )
	[ -f "${olays[0]}" ] && normalize_overlays ${olays[@]}
	for pkgfile in keywords mask unmask use
	do
		echo "#$pkgfile"
		normalize_packagefiles "$pkgfile" "$1/package.$pkgfile"/*
	done
}


function exec_scripts(){
	debug "executing scripts"
	STAGE="$1"
	MACHINE="$2"
	MACHINETYPE="${3:-default}"
	ROOT="$PWD/roots/$MACHINE/root"
	export STAGE MACHINE MACHINETYPE ROOT
	debug "Executing $STAGE scripts for machine $MACHINE of type $MACHINETYPE"
	for script in "$ROOT_DIR/scripts/$STAGE/$MACHINETYPE/"*
	do
		if [ ! -x "$script" ]
		then
			continue;
		fi
		debug "Executing ${script#$ROOT_DIR/scripts/}"
		if [ "${script##*\.}" == "chroot" ]
		then
			export -n ROOT
			cp "$script" "$ROOT/script.sh"
			echo "chrooting"
			chroot "$ROOT" "/script.sh"
			rm "${ROOT}/script.sh"
			echo "chroot done $RETVAL"
		else
			. "$script"
		fi

	done
}



function ensure_dir(){
	debug "Ensuring $1 is a directory"
	if [ ! -e "$1" ]
	then
		mkdir -p "$1"
	elif [ ! -d "$1" ]
	then
		error "$1 is not a directory"
		error_exit
	fi
}
set -E
trap error_exit ERR
