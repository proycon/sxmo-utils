#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

monitor="${SXMO_MONITOR:-"DSI-1"}"

applyptrmatrix() {
	xinput set-prop "${SXMO_TOUCHSCREEN_ID:-8}" --type=float --type=float "Coordinate Transformation Matrix" "$@"
	if [ -n "$SXMO_STYLUS_ID" ]; then
		xinput set-prop "$SXMO_STYLUS_ID" --type=float --type=float "Coordinate Transformation Matrix" "$@"
	fi
}

swaytransforms() {
	swaymsg -p -t get_outputs | awk '
		/Output/ { printf $2 " " };
		/Transform/ { print $2 }'
}

xorgisrotated() {
	rotation="$(
		xrandr | grep primary | cut -d' ' -f 5 | sed s/\(//
	)"
	if [ "$rotation" = "normal" ]; then
		return 1;
	fi
	printf %s "$rotation"
	return 0;
}

swayisrotated() {
	rotation="$(
		swaytransforms \
		| grep "$monitor" \
		| cut -d" " -f2 \
		| sed -e s/90/right/ -e s/270/left/ -e s/180/reverse/
	)"
	if [ "$rotation" = "normal" ]; then
		return 1;
	fi
	printf %s "$rotation"
	return 0;
}

xorgrotnormal() {
	sxmo_keyboard.sh close
	xrandr -o normal
	applyptrmatrix 0 0 0 0 0 0 0 0 0
	sxmo_hooks.sh lisgdstart &
	exit 0
}

swayrotnormal() {
	swaymsg -- output  "$monitor" transform 0
	swaymsg -- input type:touch map_to_output "$monitor"
	swaymsg -- input type:tablet_tool map_to_output "$monitor"
	sxmo_hooks.sh lisgdstart &
	exit 0
}

xorgrotright() {
	sxmo_keyboard.sh close
	xrandr -o right
	applyptrmatrix 0 1 0 -1 0 1 0 0 1
	sxmo_hooks.sh lisgdstart &
	exit 0
}

swayrotright() {
	swaymsg -- output  "$monitor" transform 90
	swaymsg -- input type:touch map_to_output "$monitor"
	swaymsg -- input type:tablet_tool map_to_output "$monitor"
	sxmo_hooks.sh lisgdstart &
	exit 0
}

xorgrotleft() {
	sxmo_keyboard.sh close
	xrandr -o left
	applyptrmatrix 0 -1 1 1 0 0 0 0 1
	sxmo_hooks.sh lisgdstart &
	exit 0
}

swayrotleft() {
	swaymsg -- output  "$monitor" transform 270
	swaymsg -- input type:touch map_to_output "$monitor"
	swaymsg -- input type:tablet_tool map_to_output "$monitor"
	sxmo_hooks.sh lisgdstart &
	exit 0
}

isrotated() {
	case "$SXMO_WM" in
		sway)
			"swayisrotated"
			;;
		dwm)
			"xorgisrotated"
			;;
	esac
}

if [ -z "$1" ] || [ "rotate" = "$1" ]; then
	shift
	if isrotated; then
		set -- rotnormal "$@"
	else
		set -- rotright "$@"
	fi
fi

case "$SXMO_WM" in
	sway)
		"sway$1" "$@"
		;;
	dwm)
		"xorg$1" "$@"
		;;
esac
