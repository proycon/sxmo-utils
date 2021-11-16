#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

case "$SXMO_WM" in
	sway) swaymsg kill;;
	dwm) xdotool windowkill "$(xdotool getactivewindow)";;
esac
