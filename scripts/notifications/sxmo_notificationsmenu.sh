#!/usr/bin/env sh
NOTIFDIR="$XDG_DATA_HOME"/sxmo/notifications

notificationmenu() {
	CHOICES="Close Menu\nClear Notifications"
	# shellcheck disable=SC2045
	for NOTIFFILE in $(ls -tr "$NOTIFDIR"); do
		NOTIFMSG="$(tail -n+3 "$NOTIFDIR/$NOTIFFILE" | tr "\n^" " ")"
		NOTIFHRANDMIN="$(stat --printf %y "$NOTIFDIR/$NOTIFFILE" | grep -oE '[0-9]{2}:[0-9]{2}')"
		CHOICES="
			$CHOICES
			$NOTIFHRANDMIN - $NOTIFMSG ^ $NOTIFDIR/$NOTIFFILE
		"
	done

	PICKEDCONTENT="$(
		printf "%b" "$CHOICES" |
		xargs -0 echo |
		sed '/^[[:space:]]*$/d' |
		awk '{$1=$1};1' |
		cut -d^ -f1 |
		dmenu -c -i -p "Notifs" -l 20
	)"

	[ "$PICKEDCONTENT" = "Close Menu" ] && exit 1
	[ "$PICKEDCONTENT" = "Clear Notifications" ] && rm "$NOTIFDIR"/* && exit 1

	PICKEDNOTIFFILE="$(echo "$CHOICES" | tr -s ' ' | grep -F "$PICKEDCONTENT" | cut -d^ -f2 | tr -d ' ')"
	NOTIFACTION="$(head -n1 "$PICKEDNOTIFFILE")"
	setsid -f sh -c "$NOTIFACTION" &
	rm "$PICKEDNOTIFFILE"
}

notificationmenu
