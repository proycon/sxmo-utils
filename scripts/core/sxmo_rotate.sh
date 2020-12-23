#!/usr/bin/env sh

applyptrmatrix() {
	PTRID="$(
		xinput | grep -iE 'touchscreen.+pointer' | grep -oE 'id=[0-9]+' | cut -d= -f2
	)"
	xinput set-prop "$PTRID" --type=float --type=float "Coordinate Transformation Matrix" "$@"
}

isrotated() {
	xrandr | grep primary | cut -d' ' -f 5 | grep right && return 0
	xrandr | grep primary | cut -d' ' -f 5 | grep left && return 0
	return 1
}

rotnormal() {
	pkill "$KEYBOARD"
	xrandr -o normal
	applyptrmatrix 0 0 0 0 0 0 0 0 0
	pidof lisgd && pkill lisgd | sxmo_lisgdstart.sh -o 0 &
	exit 0
}

rotright() {
	pkill "$KEYBOARD"
	xrandr -o right
	applyptrmatrix 0 1 0 -1 0 1 0 0 1
	pidof lisgd && pkill lisgd | sxmo_lisgdstart.sh -o 1 &
	exit 0
}

rotleft() {
	pkill "$KEYBOARD"
	xrandr -o left
	applyptrmatrix 0 -1 1 1 0 0 0 0 1
	pidof lisgd && pkill lisgd | sxmo_lisgdstart.sh -o -1 &
	exit 0
}


rotate() {
	if isrotated; then rotnormal; else rotright; fi
}

if [ -z "$1" ]; then
	rotate
else
	"$1"
fi
