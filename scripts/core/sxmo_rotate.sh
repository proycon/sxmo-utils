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
		| grep DSI-1 \
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
	swaymsg -- output  DSI-1 transform 270
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
