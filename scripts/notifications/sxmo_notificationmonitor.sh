#!/usr/bin/env sh
trap gracefulexit INT TERM
NOTIFDIR="$XDG_CONFIG_HOME"/sxmo/notifications

gracefulexit() {
	echo "Gracefully exiting $0"
	kill -9 0
}

notificationhook() {
	if [ -x "$XDG_CONFIG_HOME"/sxmo/hooks/notification ]; then
		"$XDG_CONFIG_HOME"/sxmo/hooks/notification
	else
			sxmo_vibratepine 200;
			sleep 0.1;
			sxmo_vibratepine 200;
			sleep 0.1;
  fi
}

handlenewnotiffile(){
	NOTIFFILE="$1"

	if [ "$(wc -l "$NOTIFFILE" | cut -d' ' -f1)" -lt 3 ]; then
		echo "Invalid notification file $NOTIFFILE found (<3 lines -- see notif spec in sxmo_notifwrite.sh), deleting!" >&2
		rm -f "$NOTIFFILE"
	else
		sxmo_setpineled green 1;
		notificationhook &
		NOTIFACTION="$(awk NR==1 "$NOTIFFILE")"
		NOTIFWATCHFILE="$(awk NR==2 "$NOTIFFILE")"
		NOTIFMSG="$(tail -n+3 "$NOTIFFILE" | cut -c1-70)"

		if dunstify --action="2,open" "$NOTIFMSG" | grep 2; then
			setsid -f sh -c "$NOTIFACTION" &
		elif [ -e "$NOTIFWATCHFILE" ]; then
			(inotifywait "$NOTIFWATCHFILE" && rm -f "$NOTIFFILE") &
		fi
	fi
}

recreateexistingnotifs() {
	for NOTIF in "$NOTIFDIR"/*; do
		[ -f "$NOTIF" ] || continue
		handlenewnotiffile "$NOTIF"
	done
}

monitorforaddordelnotifs() {
	while true; do
		find "$NOTIFDIR"/ -type f -mindepth 1 | read -r || sxmo_setpineled green 0
		inotifywait -e create,attrib,moved_to,delete,delete_self,moved_from "$NOTIFDIR"/ | (
			INOTIFYOUTPUT="$(cat)"
			INOTIFYEVENTTYPE="$(echo "$INOTIFYOUTPUT" | cut -d" " -f2)"
			echo "$INOTIFYEVENTTYPE" | grep -E "CREATE|MOVED_TO|ATTRIB" || continue
			NOTIFFILE="$NOTIFDIR/$(echo "$INOTIFYOUTPUT" | cut -d" " -f3)"
			handlenewnotiffile "$NOTIFFILE"
		) & wait
	done
}

pgrep -f "$(command -v sxmo_notificationmonitor.sh)" | grep -Ev "^${$}$" | xargs kill
rm -f $NOTIFDIR/incomingcall
sxmo_setpineled green 0
recreateexistingnotifs
monitorforaddordelnotifs
