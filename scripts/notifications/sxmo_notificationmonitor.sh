#!/usr/bin/env sh
trap gracefulexit INT TERM

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

gracefulexit() {
	echo "Gracefully exiting $0"
	kill -9 0
}

handlenewnotiffile(){
	NOTIFFILE="$1"

	if [ "$(wc -l "$NOTIFFILE" | cut -d' ' -f1)" -lt 3 ]; then
		echo "Invalid notification file $NOTIFFILE found (<3 lines -- see notif spec in sxmo_notifwrite.sh), deleting!" >&2
		rm -f "$NOTIFFILE"
	else
		sxmo_hooks.sh notification "$NOTIFFILE" &
		NOTIFACTION="$(awk NR==1 "$NOTIFFILE")"
		NOTIFWATCHFILE="$(awk NR==2 "$NOTIFFILE")"
		NOTIFMSG="$(tail -n+3 "$NOTIFFILE" | cut -c1-70)"

		(
			dunstify --action="2,open" "$NOTIFMSG" | grep 2 && (
				setsid -f sh -c "$NOTIFACTION" &
				rm -f "$NOTIFFILE"
			)
		) &

		if lsof | grep -q "$WATCHFILE"; then # Already viewing watchfile
			rm -f "$NOTIFFILE"
			return
		fi

		[ -e "$NOTIFWATCHFILE" ] && (
			inotifywait "$NOTIFWATCHFILE" && rm -f "$NOTIFFILE"
		) &
	fi
}

recreateexistingnotifs() {
	for NOTIF in "$NOTIFDIR"/*; do
		[ -f "$NOTIF" ] || continue
		handlenewnotiffile "$NOTIF"
	done
}

syncled() {
	sxmo_setled.sh green 0
	if [ "$(find "$NOTIFDIR"/ -type f | wc -l)" -gt 0 ]; then
		sleep 0.1
		sxmo_setled.sh green 1
	fi
}

monitorforaddordelnotifs() {
	while true; do
		if [ ! -e "$NOTIFDIR" ]; then
			mkdir -p "$NOTIFDIR" || sleep 10
		fi
		inotifywait -e create,attrib,moved_to,delete,delete_self,moved_from "$NOTIFDIR"/ | (
			INOTIFYOUTPUT="$(cat)"
			INOTIFYEVENTTYPE="$(echo "$INOTIFYOUTPUT" | cut -d" " -f2)"
			syncled
			if echo "$INOTIFYEVENTTYPE" | grep -E "CREATE|MOVED_TO|ATTRIB"; then
				NOTIFFILE="$NOTIFDIR/$(echo "$INOTIFYOUTPUT" | cut -d" " -f3)"
				handlenewnotiffile "$NOTIFFILE"
			fi
		) & wait
	done
}

pgrep -f "$(command -v sxmo_notificationmonitor.sh)" | grep -Ev "^${$}$" | xargs -r kill
rm -f "$NOTIFDIR"/incomingcall
recreateexistingnotifs
syncled
monitorforaddordelnotifs
