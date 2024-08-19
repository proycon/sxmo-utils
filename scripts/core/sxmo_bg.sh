#!/bin/sh

bg="$(sxmo_hook_wallpaper.sh)"

case "$SXMO_WM" in
	dwm)
		exec feh "${1+--bg-$1}" "$bg"
		;;
	sway)
		exec swaybg -i "$bg" "${1+-m "$1"}"
		;;
esac
