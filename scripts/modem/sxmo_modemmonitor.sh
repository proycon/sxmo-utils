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

lookupnumberfromcallid() {
	VOICECALLID=$1
	mmcli -m "$(modem_n)" --voice-list-calls -o "$VOICECALLID" -K |
		grep call.properties.number |
		cut -d ':' -f 2 |
		tr -d ' +'
}

checkformissedcalls() {
	if pgrep -vf sxmo_modemcall.sh; then
		# Add a notification for every missed call
		# Note sxmo_modemcall.sh cleanups/delete the callid from the modem; so
		# effectivly any incoming call thats terminated here is a missed call!
		for MISSEDCALLID in $(
			mmcli -m "$(modem_n)" --voice-list-calls |
			grep incoming |
			grep terminated |
			grep -oE "Call\/[0-9]+" |
			cut -d'/' -f2
		); do
			MISSEDNUMBER="$(lookupnumberfromcallid "$MISSEDCALLID")"
			mmcli -m "$(modem_n)" --voice-delete-call "$MISSEDCALLID"

			TIME="$(date --iso-8601=seconds)"
			mkdir -p "$LOGDIR"
			printf %b "$TIME\tcall_missed\t$MISSEDNUMBER\n" >> "$LOGDIR/modemlog.tsv"

			CONTACT="$(sxmo_contacts.sh | grep -E "^$MISSEDNUMBER")"
			sxmo_notificationwrite.sh \
				random \
				"st -f Terminus-20 -e sh -c \"echo 'Missed call from $CONTACT at $(date)' && read\"" \
				none \
				"Missed call - $CONTACT"
		done
	fi
}

checkforincomingcalls() {
	VOICECALLID="$(
		mmcli -m "$(modem_n)" --voice-list-calls -a |
		grep -Eo '[0-9]+ incoming \(ringing-in\)' |
		grep -Eo '[0-9]+'
	)"
	echo "$VOICECALLID" | grep -v . && rm -f "$NOTIFDIR/incomingcall" && return

	# Determine the incoming phone number
	echo "Incoming Call:"
	INCOMINGNUMBER=$(lookupnumberfromcallid "$VOICECALLID")

	if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/ring" ]; then
		"$XDG_CONFIG_HOME/sxmo/hooks/ring" "$(sxmo_contacts.sh | grep -E "^$INCOMINGNUMBER")"
	else
		sxmo_vibratepine 2500 &
	fi

	TIME="$(date --iso-8601=seconds)"
	mkdir -p "$LOGDIR"
	printf %b "$TIME\tcall_ring\t$INCOMINGNUMBER\n" >> "$LOGDIR/modemlog.tsv"

	sxmo_notificationwrite.sh \
		"$NOTIFDIR/incomingcall" \
		"sxmo_modemcall.sh pickup $VOICECALLID" \
		none \
		"Pickup - $(sxmo_contacts.sh | grep -E "^$INCOMINGNUMBER")" &

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
		NUM="$(
			echo "$TEXTDATA" | 
			grep sms.content.number | 
			sed -E 's/^sms\.content\.number\s+:\s+//'
		)"
		TIME="$(echo "$TEXTDATA" | grep sms.properties.timestamp | sed -E 's/^sms\.properties\.timestamp\s+:\s+//')"

		mkdir -p "$LOGDIR/$NUM"
		printf %b "Received from $NUM at $TIME:\n$TEXT\n\n" >> "$LOGDIR/$NUM/sms.txt"
		printf %b "$TIME\trecv_txt\t$NUM\t${#TEXT} chars\n" >> "$LOGDIR/modemlog.tsv"
		mmcli -m "$(modem_n)" --messaging-delete-sms="$TEXTID"

		sxmo_notificationwrite.sh \
			random \
			"st -e tail -n9999 -f $LOGDIR/$NUM/sms.txt" \
			"$LOGDIR/$NUM/sms.txt" \
			"Message - $(sxmo_contacts.sh | grep -E "^$NUM:"): $TEXT"

		if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/sms" ]; then
			"$XDG_CONFIG_HOME/sxmo/hooks/sms" "$(sxmo_contacts.sh | grep -E "^$INCOMINGNUMBER")" "$TEXT"
		fi
	done
}

mainloop() {
	while true; do
		checkformissedcalls
		checkforincomingcalls
		checkfornewtexts
		sleep $TIMEOUT & wait
	done
}

mainloop
