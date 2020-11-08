#!/usr/bin/env sh
trap gracefulexit INT TERM
NOTIFDIR="$XDG_CONFIG_HOME"/sxmo/notifications

gracefulexit() {
	echo "Gracefully exiting $0"
	kill -9 0
}

notificationhook() {
	if [ -x "$XDG_CONFIG_HOME"/sxmo/hooks/notification ]; then
		"$XDG_CONFIG_HOME"/sxmo/hooks/notification "$@"
	else
		VIBS=5
		VIBI=0
		while [ $VIBI -lt $VIBS ]; do
			sxmo_vibratepine 400 &
			sleep 0.5
			VIBI=$(echo $VIBI+1 | bc)
		done
  fi
}

handlenewnotiffile(){
	NOTIFFILE="$1"

	if [ "$(wc -l "$NOTIFFILE" | cut -d' ' -f1)" -lt 3 ]; then
		echo "Invalid notification file $NOTIFFILE found (<3 lines -- see notif spec in sxmo_notifwrite.sh), deleting!" >&2
		rm -f "$NOTIFFILE"
	else
		notificationhook "$NOTIFFILE" &
		NOTIFACTION="$(awk NR==1 "$NOTIFFILE")"
		NOTIFWATCHFILE="$(awk NR==2 "$NOTIFFILE")"
		NOTIFMSG="$(tail -n+3 "$NOTIFFILE" | cut -c1-70)"

		(
			dunstify --action="2,open" "$NOTIFMSG" | grep 2 && (
				setsid -f sh -c "$NOTIFACTION" &
				rm -f "$NOTIFFILE"
			)
		) &

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
	sxmo_setpineled green 0
	if [ "$(find "$NOTIFDIR"/ -type f | wc -l)" -gt 0 ]; then
		sleep 0.1
		sxmo_setpineled green 1
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

pgrep -f "$(command -v sxmo_notificationmonitor.sh)" | grep -Ev "^${$}$" | xargs kill
rm -f "$NOTIFDIR"/incomingcall
recreateexistingnotifs
syncled
monitorforaddordelnotifs
