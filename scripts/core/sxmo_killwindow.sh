#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

case "$(sxmo_wm.sh)" in
	sway) swaymsg kill;;
	xorg|dwm) xdotool windowkill "$(xdotool getactivewindow)";;
esac
