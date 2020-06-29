#!/usr/bin/env sh
TIMEOUT=3
LOGDIR="$XDG_CONFIG_HOME"/sxmo/modem
trap "gracefulexit" INT TERM

err() {
	notify-send "$1"
	gracefulexit
}

gracefulexit() {
	echo "gracefully exiting $0!"
	sxmo_setpineled green 0
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
		 rm -f /tmp/sxmo_incomingcall
		 return
	fi

	sxmo_vibratepine 2000 & sxmo_setpineled green 1

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

	# Log to /tmp/incomingcall to allow pickup and log into modemlog
	TIME="$(date --iso-8601=seconds)"
	mkdir -p "$LOGDIR"
	printf %b "$TIME\tcall_ring\t$INCOMINGNUMBER\n" >> "$LOGDIR/modemlog.tsv"
	echo "$VOICECALLID:$INCOMINGNUMBER" > /tmp/sxmo_incomingcall
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
	{
		sxmo_setpineled green 1
		sxmo_vibratepine 200;
		sleep 0.1;
		sxmo_vibratepine 200;
		sleep 0.1;
		sxmo_vibratepine 200;
	} &

	for TEXTID in $(printf %b "$TEXTIDS") ; do
		TEXTDATA="$(mmcli -m "$(modem_n)" -s "$TEXTID" -K)"
		TEXT="$(echo "$TEXTDATA" | grep sms.content.text | sed -E 's/^sms\.content\.text\s+:\s+//')"
		NUM="$(
			echo "$TEXTDATA" | 
			grep sms.content.number | 
			sed -E 's/^sms\.content\.number\s+:\s+[+]?//'
		)"
		TIME="$(echo "$TEXTDATA" | grep sms.properties.timestamp | sed -E 's/^sms\.properties\.timestamp\s+:\s+//')"

		mkdir -p "$LOGDIR/$NUM"
		printf %b "Received from $NUM at $TIME:\n$TEXT\n\n" >> "$LOGDIR/$NUM/sms.txt"
		printf %b "$TIME\trecv_txt\t$NUM\t${#TEXT} chars\n" >> "$LOGDIR/modemlog.tsv"
		mmcli -m "$(modem_n)" --messaging-delete-sms="$TEXTID"
	done
}

mainloop() {
	while true; do
		sxmo_setpineled green 0
		checkforincomingcalls
		checkfornewtexts
		sleep $TIMEOUT & wait
	done
}

mainloop
