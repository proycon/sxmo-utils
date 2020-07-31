#!/usr/bin/env sh

# This script should be run to initialize the notification watchers.

NOTIFDIR="$XDG_CONFIG_HOME"/sxmo/notifications

handlecreation(){
	sxmo_setpineled green 1;
	echo "$1" | grep "sxmo_incomingcall" ||
		{
			sxmo_vibratepine 200;
			sleep 0.1;
			sxmo_vibratepine 200;
			sleep 0.1;
		} &

	# Dunstify / start notification watcher if it matches the sxmo_notificationwrite format
	grep -c . "$1" | grep 3 &&
		{
			inotifywait "$(tail -1 "$1")" && rm -f "$1" &

			DUNST_RETURN="$(dunstify --action="2,open" "$(head -1 "$1" | cut -c1-70)")";
			# shellcheck disable=SC2091
			echo "$DUNST_RETURN" | grep -v 2 || { $(head -2 "$1" | tail -1)& }
		}
}

sxmo_setpineled green 0
for NOTIF in "$NOTIFDIR"/*; do
	[ -f "$NOTIF" ] || continue
	handlecreation "$NOTIF"
done

while true; do
	{
		DIREVENT="$(inotifywait -e create,moved_to,delete,delete_self,moved_from "$NOTIFDIR"/)"
		case "$(echo "$DIREVENT" | cut -d" " -f2)" in
			"CREATE"|"MOVED_TO")
				NOTIFFILE="$NOTIFDIR/$(echo "$DIREVENT" | cut -d" " -f3)"
				handlecreation "$NOTIFFILE"
				;;
		
			"DELETE"|"DELETE_SELF"|"MOVED_FROM")
				find "$NOTIFDIR"/ -type f -mindepth 1 | read -r || sxmo_setpineled green 0
				;;
		esac
	}
done
