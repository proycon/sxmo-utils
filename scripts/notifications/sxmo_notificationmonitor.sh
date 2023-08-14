#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

handlenewnotiffile(){
	NOTIFFILE="$1"

	if [ "$(wc -l "$NOTIFFILE" | cut -d' ' -f1)" -lt 3 ]; then
		sxmo_log "Invalid notification file $NOTIFFILE found (<3 lines -- see notif spec in sxmo_notifwrite.sh), deleting!"
		rm -f "$NOTIFFILE"
	else
		sxmo_hook_notification.sh "$NOTIFFILE" &
		NOTIFACTION="$(awk NR==1 "$NOTIFFILE")"
		NOTIFWATCHFILE="$(awk NR==2 "$NOTIFFILE")"
		NOTIFMSG="$(tail -n+3 "$NOTIFFILE" | cut -c1-70)"

		(
			dunstify --action="2,open" "$NOTIFMSG" | grep 2 && (
				rm -f "$NOTIFFILE"
				eval "$NOTIFACTION"
			)
		) &

		if lsof | grep -q "$NOTIFWATCHFILE"; then # Already viewing watchfile
			rm -f "$NOTIFFILE"
			return
		fi

		[ -e "$NOTIFWATCHFILE" ] && (
			inotifywait -q "$NOTIFWATCHFILE" && \
				rm -f "$NOTIFFILE" && \
				notifications_hook
		) &
	fi
}

recreateexistingnotifs() {
	for NOTIF in "$SXMO_NOTIFDIR"/*; do
		[ -f "$NOTIF" ] || continue
		handlenewnotiffile "$NOTIF"
	done
}

notifications_hook() {
	sxmo_hook_notifications.sh "$(find "$SXMO_NOTIFDIR"/ -type f | wc -l)"
}

monitorforaddordelnotifs() {
	mkdir -p "$SXMO_NOTIFDIR"

	FIFO="$(mktemp -u)"
	mkfifo "$FIFO"
	inotifywait -mq -e attrib,move,delete "$SXMO_NOTIFDIR"  >> "$FIFO" &
	NOTIFYPID=$!

	finish() {
		kill "$NOTIFYPID"
		rm "$FIFO"
		exit
	}
	trap 'finish' TERM INT EXIT

	while read -r NOTIFFOLDER INOTIFYEVENTTYPE NOTIFFILE; do
		if echo "$INOTIFYEVENTTYPE" | grep -E "CREATE|MOVED_TO|ATTRIB"; then
			handlenewnotiffile "$NOTIFFOLDER/$NOTIFFILE"
		fi
		notifications_hook
	done < "$FIFO"

	wait "$NOTIFYPID"
}

rm -f "$SXMO_NOTIFDIR"/incomingcall
recreateexistingnotifs
notifications_hook
monitorforaddordelnotifs
