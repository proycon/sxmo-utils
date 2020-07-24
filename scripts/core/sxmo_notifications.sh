#!/usr/bin/env sh

NOTIFDIR="$XDG_CONFIG_HOME"/sxmo/notifications

while true; do
	CHOICES="$(find "$NOTIFDIR"/ -type f -not -name 'sxmo_incomingcall' -exec cat {} +)"
	PICKED="$(printf %b "$CHOICES\nClose Menu" | cut -f1 | dmenu -c -i -fn "Terminus-18" -p "Notifs" -l 10)"

	echo "$PICKED" | grep "Close Menu" && exit 0
	
	$(printf %b "$CHOICES" | grep "$PICKED" | cut -f2)
	exit 0
done
