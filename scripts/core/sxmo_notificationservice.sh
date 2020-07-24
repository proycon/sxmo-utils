#!/usr/bin/env sh

# This script should be run to initialize the notification watchers.

NOTIFDIR="$XDG_CONFIG_HOME"/sxmo/notifications

notifyd(){
	inotifywait "$1" && rm -f "$2"
}

handlecreation(){
	sxmo_setpineled green 1
	# Start notification watcher if it matches the sxmo_notificationwrite format
	awk 'BEGIN {FS="\t"} ; {print NF}' "$1" | grep -v 3 || 
	( notifyd "$(cut -f3 "$1")" "$1" & )
}

sxmo_setpineled green 0
for NOTIF in "$NOTIFDIR"/*; do
	[ -f "$NOTIF" ] || continue
	handlecreation "$NOTIF"
done

while true; do
	{
		inotifywait -e create,moved_to,delete,delete_self,moved_from "$NOTIFDIR"/ > /tmp/notifyd
		STATUS="$(tail -1 /tmp/notifyd)"
		case "$(echo "$STATUS" | cut -d" " -f2)" in
			"CREATE"|"MOVED_TO")
				NOTIFFILE="$NOTIFDIR/$(echo "$STATUS" | cut -d" " -f3)"
				handlecreation "$NOTIFFILE"
				;;
		
			"DELETE"|"DELETE_SELF"|"MOVED_FROM")
				find "$NOTIFDIR"/ -type f -mindepth 1 | read -r || sxmo_setpineled green 0
				;;
		esac
	}
done
exit 0
