#!/bin/sh

# 1.9.0 introduced a new naming scheme for hooks.
# This script moves them from their 1.8.x location.

mkdir -p "$XDG_CONFIG_HOME/sxmo/hooks/$SXMO_DEVICE_NAME"
cd "$XDG_CONFIG_HOME/sxmo/hooks/" || exit

[ -e inputhandler ] && mv inputhandler "$SXMO_DEVICE_NAME/sxmo_hook_inputhandler.sh"
[ -e lock ] && mv lock "$SXMO_DEVICE_NAME/sxmo_hook_lock.sh"
[ -e off ] && mv off "$SXMO_DEVICE_NAME/sxmo_hook_off.sh"
[ -e unlock ] && mv unlock "$SXMO_DEVICE_NAME/sxmo_hook_unlock.sh"

find . -type f -maxdepth 1 -exec basename {} \; | grep -v '^sxmo_hook_.*\.sh$' | xargs -I{} mv {} sxmo_hook_{}.sh