#!/usr/bin/env sh
LOGDIR="$XDG_DATA_HOME"/sxmo/modem
NOTIFDIR="$XDG_DATA_HOME"/sxmo/notifications
CACHEDIR="$XDG_CACHE_HOME"/sxmo
trap "gracefulexit" INT TERM

err() {
	echo "sxmo_modemmonitor: Error: $1">&2
	notify-send "$1"
	gracefulexit
}

gracefulexit() {
	echo "sxmo_modemmonitor: gracefully exiting (on signal or after error)">&2
	kill -9 0
}

modem_n() {
	TRIES=0
	while [ "$TRIES" -lt 10 ]; do
		MODEMS="$(mmcli -L)"
		if ! echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' > /dev/null; then
			TRIES=$((TRIES+1))
			echo "sxmo_modemmonitor: modem not found, waiting for modem... (try #$TRIES)">&2
			sleep 1
		else
			echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
			return
		fi
	done
	err "Couldn't find modem - is your modem enabled? Disabling modem monitor"
}

lookupnumberfromcallid() {
	VOICECALLID=$1
	mmcli -m "$(modem_n)" --voice-list-calls -o "$VOICECALLID" -K |
		grep call.properties.number |
		cut -d ':' -f 2 |
		tr -d ' '
}

lookupcontactname() {
	if [ "$1" = "--" ]; then
		echo "Unknown number"
	else
		NUMBER="$1"
		CONTACT=$(sxmo_contacts.sh --all |
			grep "$NUMBER:" | #this is not an exact match but a suffix match
							  #which also works if the + and country code are missing
							  #but may lead to false positives in rare cases (short numbers)
			cut -d':' -f 2 |
			sed 's/^[ \t]*//;s/[ \t]*$//' #strip leading/trailing whitespace
		)
		if [ -n "$CONTACT" ]; then
			echo "$CONTACT"
		else
			echo "Unknown ($NUMBER)"
		fi
	fi
}

checkforfinishedcalls() {
	#find all finished calls
	for FINISHEDCALLID in $(
		mmcli -m "$(modem_n)" --voice-list-calls |
		grep incoming |
		grep terminated |
		grep -oE "Call\/[0-9]+" |
		cut -d'/' -f2
	); do
		FINISHEDNUMBER="$(lookupnumberfromcallid "$FINISHEDCALLID")"
		mmcli -m "$(modem_n)" --voice-delete-call "$FINISHEDCALLID"
		rm -f "$NOTIFDIR/incomingcall_${FINISHEDCALLID}_notification"

		TIME="$(date --iso-8601=seconds)"
		mkdir -p "$LOGDIR"
		if [ -f "$CACHEDIR/${FINISHEDCALLID}.pickedupcall" ]; then
			#this call was picked up
			pkill -f sxmo_modemcall.sh #kill call (softly) in case it is still in progress (remote party hung up)
			echo "sxmo_modemmonitor: Finished call from $FINISHEDNUMBER">&2
			rm -f "$CACHEDIR/${FINISHEDCALLID}.pickedupcall"
			printf %b "$TIME\tcall_finished\t$FINISHEDNUMBER\n" >> "$LOGDIR/modemlog.tsv"
		else
			#this is a missed call
			# Add a notification for every missed call
			echo "sxmo_modemmonitor: Missed call from $FINISHEDNUMBER">&2
			printf %b "$TIME\tcall_missed\t$FINISHEDNUMBER\n" >> "$LOGDIR/modemlog.tsv"

			CONTACT="$(lookupcontactname "$FINISHEDNUMBER")"
			sxmo_notificationwrite.sh \
				random \
				"st -f Terminus-20 -e sh -c \"echo 'Missed call from $CONTACT at $(date)' && read\"" \
				none \
				"Missed call - $CONTACT"
		fi
	done
}

checkforincomingcalls() {
	VOICECALLID="$(
		mmcli -m "$(modem_n)" --voice-list-calls -a |
		grep -Eo '[0-9]+ incoming \(ringing-in\)' |
		grep -Eo '[0-9]+'
	)"
	echo "$VOICECALLID" | grep -v . && rm -f "$NOTIFDIR/incomingcall*" && return

	# Determine the incoming phone number
	echo "sxmo_modemmonitor: Incoming Call:">&2
	INCOMINGNUMBER=$(lookupnumberfromcallid "$VOICECALLID")
	CONTACTNAME=$(lookupcontactname "$INCOMINGNUMBER")

	if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/ring" ]; then
		echo "sxmo_modemmonitor: Invoking ring hook (async)">&2
		"$XDG_CONFIG_HOME/sxmo/hooks/ring" "$CONTACTNAME" &
	else
		sxmo_vibratepine 2500 &
	fi

	TIME="$(date --iso-8601=seconds)"
	mkdir -p "$LOGDIR"
	printf %b "$TIME\tcall_ring\t$INCOMINGNUMBER\n" >> "$LOGDIR/modemlog.tsv"

	sxmo_notificationwrite.sh \
		"$NOTIFDIR/incomingcall_${VOICECALLID}_notification" \
		"sxmo_modemcall.sh pickup $VOICECALLID" \
		none \
		"Pickup - $CONTACTNAME" &

	echo "sxmo_modemmonitor: Call from number: $INCOMINGNUMBER (VOICECALLID: $VOICECALLID)">&2
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
		echo "sxmo_modemmonitor: Text from number: $NUM (TEXTID: $TEXTID)">&2
		printf %b "Received from $NUM at $TIME:\n$TEXT\n\n" >> "$LOGDIR/$NUM/sms.txt"
		printf %b "$TIME\trecv_txt\t$NUM\t${#TEXT} chars\n" >> "$LOGDIR/modemlog.tsv"
		mmcli -m "$(modem_n)" --messaging-delete-sms="$TEXTID"
		CONTACTNAME=$(lookupcontactname "$NUM")

		sxmo_notificationwrite.sh \
			random \
			"st -e tail -n9999 -f '$LOGDIR/$NUM/sms.txt'" \
			"$LOGDIR/$NUM/sms.txt" \
			"Message - $CONTACTNAME: $TEXT"

		if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/sms" ]; then
			"$XDG_CONFIG_HOME/sxmo/hooks/sms" "$CONTACTNAME" "$TEXT"
		fi
	done
}

mainloop() {
	checkforfinishedcalls
	checkforincomingcalls
	checkfornewtexts

	# Monitor for incoming calls
	dbus-monitor --system "interface='org.freedesktop.ModemManager1.Modem.Voice',type='signal',member='CallAdded'" | \
		while read -r line; do
			echo "$line" | grep -E "^signal" && checkforincomingcalls
		done &

	# Monitor for incoming texts
	dbus-monitor --system "interface='org.freedesktop.ModemManager1.Modem.Messaging',type='signal',member='Added'" | \
		while read -r line; do
			echo "$line" | grep -E "^signal" && checkfornewtexts
		done &

	# Monitor for finished calls
	dbus-monitor --system "interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='org.freedesktop.ModemManager1.Call'" | \
		while read -r line; do
			echo "$line" | grep -E "^signal" && checkforfinishedcalls
		done &

	wait
	wait
	wait
}

echo "sxmo_modemmonitor: starting -- $(date)" >&2
rm -f "$CACHEDIR"/*.pickedupcall 2>/dev/null #new session, forget all calls we picked up previously
mainloop
echo "sxmo_modemmonitor: exiting -- $(date)" >&2
