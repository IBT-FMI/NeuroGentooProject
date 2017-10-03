#!/bin/bash
source "$(dirname "$0")/utils/functions.sh"

ensure_dir roots
ensure_dir "$CACHE"
exec_scripts initialize stemgentoo stemgentoo


clean_exit
