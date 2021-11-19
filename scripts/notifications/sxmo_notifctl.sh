#!/bin/sh

xorgcloseall() {
	dunstctl close-all

}

swaycloseall() {
	makoctl dismiss --all
}

action="$1"
shift
case "$SXMO_WM" in
	dwm) "xorg$action" "$@";;
	*) "$SXMO_WM$action" "$@";;
esac
