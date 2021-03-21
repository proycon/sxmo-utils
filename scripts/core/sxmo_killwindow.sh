#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

if [ "$1" = "close" ]; then
	xdotool windowclose "$(xdotool getactivewindow)"
else
	xdotool windowkill "$(xdotool getactivewindow)"
fi
