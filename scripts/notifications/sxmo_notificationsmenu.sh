#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

notificationmenu() {
	CHOICES="$icon_cls Close Menu\n$icon_del Clear Notifications"
	# shellcheck disable=SC2045
	for NOTIFFILE in $(ls -tr "$NOTIFDIR"); do
		NOTIFMSG="$(tail -n+3 "$NOTIFDIR/$NOTIFFILE" | tr "\n^" " ")"
		NOTIFHRANDMIN="$(stat --printf %y "$NOTIFDIR/$NOTIFFILE" | grep -oE '[0-9]{2}:[0-9]{2}')"
		CHOICES="
			$CHOICES
			$NOTIFHRANDMIN $NOTIFMSG ^ $NOTIFDIR/$NOTIFFILE
		"
	done

	PICKEDCONTENT="$(
		printf "%b" "$CHOICES" |
		xargs -0 echo |
		sed '/^[[:space:]]*$/d' |
		awk '{$1=$1};1' |
		cut -d^ -f1 |
		dmenu -i -p "Notifs"
	)"

	echo "$PICKEDCONTENT" | grep -q "Close Menu" && exit 1
	echo "$PICKEDCONTENT" | grep -q "Clear Notifications" && rm "$NOTIFDIR"/* && exit 1

	PICKEDNOTIFFILE="$(echo "$CHOICES" | tr -s ' ' | grep -F "$PICKEDCONTENT" | head -1 | cut -d^ -f2 | tr -d ' ')"
	NOTIFACTION="$(head -n1 "$PICKEDNOTIFFILE")"
	setsid -f sh -c "$NOTIFACTION" &
	rm "$PICKEDNOTIFFILE"
}

notificationmenu
