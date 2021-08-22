#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

applyptrmatrix() {
	TOUCH_POINTER_ID="${TOUCH_POINTER_ID:-8}"
	xinput set-prop "$TOUCH_POINTER_ID" --type=float --type=float "Coordinate Transformation Matrix" "$@"
}

swaytransforms() {
	swaymsg -p -t get_outputs | awk '
		/Output/ { printf $2 " " };
		/Transform/ { print $2 }'
}

xorgisrotated() {
	case "$(xrandr | grep primary | cut -d' ' -f 5)" in
		*right*|*left*) return 0;;
		*) return 1;;
	esac
}

swayisrotated() {
	swaytransforms | grep DSI-1 | grep -q 0
}

xorgrotnormal() {
	sxmo_keyboard.sh close
	xrandr -o normal
	applyptrmatrix 0 0 0 0 0 0 0 0 0
	sxmo_hooks.sh lisgdstart
	exit 0
}

swayrotnormal() {
	swaymsg -- output  DSI-1 transform 0
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
	swaymsg -- output  DSI-1 transform 90
	sxmo_hooks.sh lisgdstart
	exit 0
}

xorgrotleft() {
	sxmo_keyboard.sh close
	xrandr -o left
	applyptrmatrix 0 -1 1 1 0 0 0 0 1
	sxmo_hooks.sh lisgdstart
	exit 0
}

swayrotleft() {
	swaymsg -- output  DSI-1 transform 270
	sxmo_hooks.sh lisgdstart
	exit 0
}

isrotated() {
	case "$wm" in
		sway)
			"swayisrotated"
			;;
		dwm|xorg)
			"xorgisrotated"
			;;
	esac
}

wm="$(sxmo_wm.sh)"

if [ -z "$1" ] || [ "rotate" = "$1" ]; then
	shift
	if isrotated; then
		set -- rotnormal "$@"
	else
		set -- rotright "$@"
	fi
fi

case "$wm" in
	sway)
		"sway$1" "$@"
		;;
	dwm|xorg)
		"xorg$1" "$@"
		;;
esac
