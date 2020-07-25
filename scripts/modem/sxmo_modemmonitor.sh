#!/usr/bin/env sh
TIMEOUT=3
LOGDIR="$XDG_CONFIG_HOME"/sxmo/modem
NOTIFDIR="$XDG_CONFIG_HOME"/sxmo/notifications
trap "gracefulexit" INT TERM

err() {
	notify-send "$1"
	gracefulexit
}

gracefulexit() {
	echo "gracefully exiting $0!"
	kill -9 0
}

modem_n() {
	MODEMS="$(mmcli -L)"
	echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' > /dev/null || err "Couldn't find modem - is your modem enabled?\nDisabling modem monitor"
	echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
}

checkforincomingcalls() {
	VOICECALLID="$(
		mmcli -m "$(modem_n)" --voice-list-calls -a |
		grep -Eo '[0-9]+ incoming \(ringing-in\)' |
		grep -Eo '[0-9]+'
	)"

	if echo "$VOICECALLID" | grep -v .; then
		 rm -f "$NOTIFDIR/sxmo_incomingcall"
		 return
	fi


	# Delete all previous calls which have been terminated calls
	for CALLID in $(
		mmcli -m "$(modem_n)" --voice-list-calls |
		grep terminated |
		grep -oE "Call\/[0-9]+" |
		cut -d'/' -f2
	); do
		mmcli -m "$(modem_n)" --voice-delete-call "$CALLID"
	done


	# Determine the incoming phone number
	echo "Incoming Call:"
	INCOMINGNUMBER=$(
		mmcli -m "$(modem_n)" --voice-list-calls -o "$VOICECALLID" -K |
		grep call.properties.number |
		cut -d ':' -f 2 |
		tr -d ' '
	)

	CONTACT="$(sxmo_contacts.sh | grep "$INCOMINGNUMBER" | cut -d" " -f2- || echo "Unknown Number")"
	if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/ring" ]; then
		"$XDG_CONFIG_HOME/sxmo/hooks/ring" "$CONTACT"
	else
		sxmo_vibratepine 2000 &
	fi

	# Log to $NOTIFDIR/incomingcall to allow pickup and log into modemlog
	TIME="$(date --iso-8601=seconds)"
	mkdir -p "$LOGDIR"
	printf %b "$TIME\tcall_ring\t$INCOMINGNUMBER\t$CONTACT\n" >> "$LOGDIR/modemlog.tsv"
	printf %b "$VOICECALLID:$INCOMINGNUMBER\n" > "$NOTIFDIR/sxmo_incomingcall"
	echo "Number: $INCOMINGNUMBER (VOICECALLID: $VOICECALLID)"
}

checkfornewtexts() {
	TEXTIDS="$(
		mmcli -m "$(modem_n)" --messaging-list-sms |
		grep -Eo '/SMS/[0-9]+ \(received\)' |
		grep -Eo '[0-9]+'
	)"
	echo "$TEXTIDS" | grep -v . && return

	# Loop each textid received and read out the data into appropriate logfile
	for TEXTID in $TEXTIDS; do

		TEXTDATA="$(mmcli -m "$(modem_n)" -s "$TEXTID" -K)"
		TEXT="$(echo "$TEXTDATA" | grep sms.content.text | sed -E 's/^sms\.content\.text\s+:\s+//')"
		TRUNCATED="$(printf %b "$TEXT" | cut -c1-70 | tr '\n' ' ' | sed '$s/ $/\n/')"
		NUM="$(
			echo "$TEXTDATA" |
			grep sms.content.number |
			sed -E 's/^sms\.content\.number\s+:\s+//'
		)"
		TIME="$(echo "$TEXTDATA" | grep sms.properties.timestamp | sed -E 's/^sms\.properties\.timestamp\s+:\s+//')"

		CONTACT="$(sxmo_contacts.sh | grep "$NUM" | cut -d" " -f2- || echo "Unknown Number")"

		mkdir -p "$LOGDIR/$NUM"
		printf %b "Received from $NUM ($CONTACT) at $TIME:\n$TEXT\n\n" >> "$LOGDIR/$NUM/sms.txt"
		printf %b "$TIME\trecv_txt\t$NUM\t$CONTACT\t${#TEXT} chars\n" >> "$LOGDIR/modemlog.tsv"
		mmcli -m "$(modem_n)" --messaging-delete-sms="$TEXTID"

		# Send a notice of each message to a notification file / watcher

		if [ "${#TEXT}" = "${#TRUNCATED}" ]; then
			( sxmo_notificationwrite.sh "Message from $CONTACT: $TEXT" "st -e tail -n9999 -f \"$LOGDIR/$NUM/sms.txt\"" "$LOGDIR/$NUM/sms.txt" & ) &
		else
			( sxmo_notificationwrite.sh "Message from $CONTACT: $TRUNCATED..." "st -e tail -n9999 -f \"$LOGDIR/$NUM/sms.txt\"" "$LOGDIR/$NUM/sms.txt" & ) &
		fi

		if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/sms" ]; then
			"$XDG_CONFIG_HOME/sxmo/hooks/sms" "$CONTACT" "$TEXT"
		fi

	done
}

mainloop() {
	while true; do
		checkforincomingcalls
		checkfornewtexts
		sleep $TIMEOUT & wait
	done
}

mainloop
