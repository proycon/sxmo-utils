#!/bin/sh

wtype_to_xdotool() {
	if [ "$#" -eq 0 ]; then
		exit
	fi

	if [ "-M" = "$1" ] || [ "-P" = "$1" ]; then
		key="$2"
		shift 2
		xdotool keydown "$key"
		sxmo_type.sh -f xorg "$@"
		xdotool keyup "$key"
		exit
	elif [ "-m" = "$1" ] || [ "-p" = "$1" ]; then
		xdotool keyup "$2"
		shift 2
	elif [ "-k" = "$1" ]; then
		xdotool key "$2"
		shift 2
	elif [ "-s" = "$1" ]; then
		printf 'scale=2; %s/1000\n' "$2" | bc -l | xargs xdotool sleep
		shift 2
	else
		xdotool type "$1"
		shift
	fi

	wtype_to_xdotool "$@"
}

# enforce wm
# usefull to recurse without reprobing the wm
if [ "$1" = "-f" ]; then
	wm="$2"
	shift 2
else
	wm="$(sxmo_wm.sh)"
fi

case "$wm" in
	sway)
		wtype "$@"
		;;
	dwm|xorg)
		wtype_to_xdotool "$@"
		;;
esac
