#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This hook launches a desktop widget (e.g. a clock) (blocking)

pangodraw() {
	date +"<b>%H</b>:%M" #date with some pango markup syntax (https://docs.gtk.org/Pango/pango_markup.html)
	date +"<small><small><small><small>%a %d %b %Y</small></small></small></small>"
	# here you can output whatever you want to end up in the widget
	# make sure to use pango markup syntax if you want colours etc, ANSI is not supported by wayout
	# for instance, you can show details about the activated network connections:
	#nmcli -w 3 -c no -p -f DEVICE,STATE,NAME,TYPE con show | grep activated | sed 's/activated/   /' | sed '/^\s*$/d' 2> /dev/null
	# make sure to end with an empty line, to denote the end of data for wayout
	echo
}

if [ -n "$WAYLAND_DISPLAY" ] && command -v wayout > /dev/null; then
	# For wayland we use wayout:
	tmp="$(mktemp)"
	(
		pangodraw
		pangodraw
		while : ; do
			sleep 60
			pangodraw
		done
	) >> "$tmp" &
	PIDS="$!"

	forceredraw() {
		pangodraw >> "$tmp"
		for PID in $PIDS; do
			wait "$PID"
		done
	}
	trap 'forceredraw' USR2

	tail -f "$tmp" | wayout --font "FiraMono Nerd Font" --foreground-color "#ffffff" --fontsize "80" --height 200 --textalign center --feed-par &
	PIDS="$! $PIDS"

	finish() {
		for PID in $PIDS; do
			kill "$PID"
		done
		rm "$tmp"
	}
	trap 'finish' TERM INT EXIT

	for PID in $PIDS; do
		wait "$PID"
	done
elif [ -n "$DISPLAY" ] && command -v conky > /dev/null; then
	# For X we use conky (if not already running):
	exec conky -c /usr/share/sxmo/appcfg/conky24h.conf #24 hour clock
	#exec conky -c /usr/share/sxmo/appcfg/conky.conf #12 hour clock (am/pm)
fi
