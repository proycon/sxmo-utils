#!/bin/sh

# This script is called prior to suspending

. sxmo_common.sh

pkill clickclack
sxmo_keyboard.sh close
pkill mpv #if any audio/video is playing, kill it (it might stutter otherwise)

case "$SXMO_WM" in
	dwm)
		sxmo_dmenu.sh close
		;;
esac

printf "SUSPEND" > "$SXMO_STATE"
sxmo_hook_statusbar.sh state_change

# store brightness state and set it to zero
light > "$XDG_RUNTIME_DIR"/sxmo.brightness.presuspend.state
light -S 0
sleep 1s # give statusbar a second to update

# Add here whatever you want to do
