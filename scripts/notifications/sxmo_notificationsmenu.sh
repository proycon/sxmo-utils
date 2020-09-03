#!/usr/bin/env sh
NOTIFDIR="$XDG_CONFIG_HOME"/sxmo/notifications

notificationmenu() {
	CHOICES="Close Menu\nClear Notifications"
	for NOTIFFILE in "$NOTIFDIR"/*; do
		NOTIFMSG="$(tail -n+3 "$NOTIFFILE" | tr "\n^" " ")"
		NOTIFHRANDMIN="$(stat --printf %y "$NOTIFFILE" | grep -oE '[0-9]{2}:[0-9]{2}')"
		CHOICES="
			$CHOICES
			$NOTIFHRANDMIN - $NOTIFMSG ^ $NOTIFFILE
		"
	done

	PICKEDCONTENT="$(
		printf "%b" "$CHOICES" |
		xargs -0 echo |
		sed '/^[[:space:]]*$/d' |
		awk '{$1=$1};1' |
		cut -d^ -f1 | 
		dmenu -c -i -fn "Terminus-18" -p "Notifs" -l 10
	)"

	[ "$PICKEDCONTENT" = "Close Menu" ] && exit 1
	[ "$PICKEDCONTENT" = "Clear Notifications" ] && rm "$NOTIFDIR"/* && exit 1

	PICKEDNOTIFFILE="$(echo "$CHOICES" | grep "$PICKEDCONTENT" | cut -d^ -f2 | tr -d ' ')"
	NOTIFACTION="$(head -n1 "$PICKEDNOTIFFILE")"
	setsid -f sh -c "$NOTIFACTION" &
	rm "$PICKEDNOTIFFILE"
}

notificationmenu
