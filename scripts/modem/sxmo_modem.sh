#!/bin/sh
# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

stderr() {
	printf "sxmo_modem %s: %s\n" "$(date)" "$*" >&2
}

checkmodem() {
	TRIES=0
	while [ "$TRIES" -lt 10 ]; do
		MODEMS="$(mmcli -L)"
		if echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' > /dev/null; then
			break
		elif grep -q rtc "$UNSUSPENDREASONFILE"; then
			#don't bother checking in rtc-wake situations
			TRIES=0
			break
		else
			TRIES=$((TRIES+1))
			notify-send "Modem not found. Waiting for modem (try #$TRIES)..."
			stderr "Modem not found. Waiting for modem (try #$TRIES)..."
			sleep 3
			if [ "$TRIES" -eq 10 ]; then
				notify-send "ERROR! Modem could not be found after 10 tries. Calling sxmo_modemmonitortoggle.sh ensure."
				stderr "ERROR! checkmodem couldn't find modem. Calling sxmo_modemonitortoggle.sh ensure"
				sxmo_modemmonitortoggle.sh ensure
				break
			fi
		fi
	done
}

modem_n() {
	TRIES=0
	while [ "$TRIES" -lt 10 ]; do
		MODEMS="$(mmcli -L)"
		if ! echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' > /dev/null; then
			TRIES=$((TRIES+1))
			stderr "modem not found, waiting for modem... (try #$TRIES)"
			sleep 1
		else
			echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
			return
		fi
	done
	stderr "ERROR! modem_n couldn't find modem. Calling sxmo_modemmonitortoggle.sh off"
	notify-send "Couldn't find modem - is your modem enabled? Disabling modem monitor."
	sleep 1
	sxmo_modemmonitortoggle.sh off
}

cleanupnumber() {
	if pn valid "$1"; then
		echo "$1"
		return
	fi

	REFORMATTED="$(pn find ${DEFAULT_COUNTRY:+-c "$DEFAULT_COUNTRY"} "$1")"
	if [ -n "$REFORMATTED" ]; then
		echo "$REFORMATTED"
		return
	fi

	echo "$1"
}

lookupnumberfromcallid() {
	VOICECALLID=$1
	mmcli -m "$(modem_n)" --voice-list-calls -o "$VOICECALLID" -K |
		grep call.properties.number |
		cut -d ':' -f 2 |
		tr -d ' '
}

checkforfinishedcalls() {
	#find all finished calls
	for FINISHEDCALLID in $(
		mmcli -m "$(modem_n)" --voice-list-calls |
		grep terminated |
		grep -oE "Call\/[0-9]+" |
		cut -d'/' -f2
	); do
		FINISHEDNUMBER="$(lookupnumberfromcallid "$FINISHEDCALLID")"
		FINISHEDNUMBER="$(cleanupnumber "$FINISHEDNUMBER")"
		mmcli -m "$(modem_n)" --voice-delete-call "$FINISHEDCALLID"
		rm -f "$NOTIFDIR/incomingcall_${FINISHEDCALLID}_notification"* #there may be multiple actionable notification for one call

		rm -f "$CACHEDIR/${FINISHEDCALLID}.monitoredcall"

		TIME="$(date --iso-8601=seconds)"
		mkdir -p "$LOGDIR"
		if [ -f "$CACHEDIR/${FINISHEDCALLID}.discardedcall" ]; then
			#this call was discarded
			stderr "Discarded call from $FINISHEDNUMBER"
			printf %b "$TIME\tcall_discarded\t$FINISHEDNUMBER\n" >> "$LOGDIR/modemlog.tsv"
		elif [ -f "$CACHEDIR/${FINISHEDCALLID}.pickedupcall" ]; then
			#this call was picked up
			pkill -f sxmo_modemcall.sh
			stderr "Finished call from $FINISHEDNUMBER"
			printf %b "$TIME\tcall_finished\t$FINISHEDNUMBER\n" >> "$LOGDIR/modemlog.tsv"
		elif [ -f "$CACHEDIR/${FINISHEDCALLID}.hangedupcall" ]; then
			#this call was hung up by the user
			stderr "Finished call from $FINISHEDNUMBER"
			printf %b "$TIME\tcall_finished\t$FINISHEDNUMBER\n" >> "$LOGDIR/modemlog.tsv"
		elif [ -f "$CACHEDIR/${FINISHEDCALLID}.initiatedcall" ]; then
			#this call was hung up by the contact
			pkill -f sxmo_modemcall.sh
			stderr "Finished call from $FINISHEDNUMBER"
			printf %b "$TIME\tcall_finished\t$FINISHEDNUMBER\n" >> "$LOGDIR/modemlog.tsv"
		elif [ -f "$CACHEDIR/${FINISHEDCALLID}.mutedring" ]; then
			#this ring was muted up
			stderr "Muted ring from $FINISHEDNUMBER"
			printf %b "$TIME\tring_muted\t$FINISHEDNUMBER\n" >> "$LOGDIR/modemlog.tsv"
		else
			#this is a missed call
			# Add a notification for every missed call
			pkill -f sxmo_modemcall.sh
			stderr "Missed call from $FINISHEDNUMBER"
			printf %b "$TIME\tcall_missed\t$FINISHEDNUMBER\n" >> "$LOGDIR/modemlog.tsv"

			CONTACT="$(sxmo_contacts.sh --name "$FINISHEDNUMBER")"
			stderr "Invoking missed call hook (async)"
			[ "$CONTACT" = "???" ] && CONTACT="$FINISHEDNUMBER"
			sxmo_hooks.sh missed_call "$CONTACT" &

			sxmo_notificationwrite.sh \
				random \
				"sxmo_terminal.sh -e sh -c \"echo 'Missed call from $CONTACT at $(date)' && read\"" \
				none \
				"Missed $icon_phn $CONTACT"
		fi
	done
}

checkforincomingcalls() {
	VOICECALLID="$(
		mmcli -m "$(modem_n)" --voice-list-calls -a |
		grep -Eo '[0-9]+ incoming \(ringing-in\)' |
		grep -Eo '[0-9]+'
	)"
	[ -z "$VOICECALLID" ] && return

	[ -f "$CACHEDIR/${VOICECALLID}.monitoredcall" ] && return # prevent multiple rings
	find "$CACHEDIR" -name "$VOICECALLID.*" -delete # we cleanup all dangling event files
	touch "$CACHEDIR/${VOICECALLID}.monitoredcall" #this signals that we handled the call

	cat "$LASTSTATE" > "$CACHEDIR/${VOICECALLID}.laststate"

	# Determine the incoming phone number
	stderr "Incoming Call:"
	INCOMINGNUMBER=$(lookupnumberfromcallid "$VOICECALLID")
	INCOMINGNUMBER="$(cleanupnumber "$INCOMINGNUMBER")"
	CONTACTNAME=$(sxmo_contacts.sh --name "$INCOMINGNUMBER")

	TIME="$(date --iso-8601=seconds)"
	if cut -f1 "$BLOCKFILE" | grep -q "^$INCOMINGNUMBER$"; then
		stderr "BLOCKED call from number: $VOICECALLID"
		sxmo_modemcall.sh mute "$VOICECALLID"
		printf %b "$TIME\tcall_ring\t$INCOMINGNUMBER\n" >> "$BLOCKDIR/modemlog.tsv"
		rm -f "$NOTIFDIR/incomingcall_${VOICECALLID}_notification"*
	else
		stderr "Invoking ring hook (async)"
		[ "$CONTACTNAME" = "???" ] && CONTACTNAME="$INCOMINGNUMBER"
		sxmo_hooks.sh ring "$CONTACTNAME" &

		mkdir -p "$LOGDIR"
		printf %b "$TIME\tcall_ring\t$INCOMINGNUMBER\n" >> "$LOGDIR/modemlog.tsv"

		sxmo_notificationwrite.sh \
			"$NOTIFDIR/incomingcall_${VOICECALLID}_notification" \
			"sxmo_modemcall.sh incomingcallmenu '$VOICECALLID'" \
			none \
			"Incoming $icon_phn $CONTACTNAME" &
		sxmo_modemcall.sh incomingcallmenu "$VOICECALLID" &

		stderr "Call from number: $INCOMINGNUMBER (VOICECALLID: $VOICECALLID)"
	fi
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
		# SMS with no TEXTID is an SMS WAP (I think). So skip.
		if [ -z "$TEXTDATA" ]; then
			stderr "no TEXTDATA, probably MMS."
			echo "$(date) MMS no TEXTDATA" >> ~/mms.debug.log
			continue
		fi
		TEXT="$(echo "$TEXTDATA" | grep sms.content.text | sed -E 's/^sms\.content\.text\s+:\s+//')"
		NUM="$(
			echo "$TEXTDATA" |
			grep sms.content.number |
			sed -E 's/^sms\.content\.number\s+:\s+//'
		)"
		NUM="$(cleanupnumber "$NUM")"
		TIME="$(echo "$TEXTDATA" | grep sms.properties.timestamp | sed -E 's/^sms\.properties\.timestamp\s+:\s+//')"

		if cut -f1 "$BLOCKFILE" | grep -q "^$NUM$"; then
			mkdir -p "$BLOCKDIR/$NUM"
			stderr "BLOCKED text from number: $NUM (TEXTID: $TEXTID)"
			printf %b "Received from $NUM at $TIME:\n$TEXT\n\n" >> "$BLOCKDIR/$NUM/sms.txt"
			printf %b "$TIME\trecv_txt\t$NUM\t${#TEXT} chars\n" >> "$BLOCKDIR/modemlog.tsv"
			mmcli -m "$(modem_n)" --messaging-delete-sms="$TEXTID"
			continue
		fi

		# mmsd-tng devs think that if there's no data, then not an mms,
		# but I've found that sometimes sms can have '--' in DATA
		# so I think safer bet is to just check for TEXT = "--" and ghost sms's above..
		if [ "$TEXT" = "--" ]; then
			stderr "TEXT = '--'. Probably an MMS..."
			echo "$(date) MMS TEXT --." >> ~/mms.debug.log
			continue
		fi
		stderr "Probably not an MMS."

		mkdir -p "$LOGDIR/$NUM"
		stderr "Text from number: $NUM (TEXTID: $TEXTID)"
		printf %b "Received SMS from $NUM at $TIME:\n$TEXT\n\n" >> "$LOGDIR/$NUM/sms.txt"
		printf %b "$TIME\trecv_txt\t$NUM\t${#TEXT} chars\n" >> "$LOGDIR/modemlog.tsv"
		mmcli -m "$(modem_n)" --messaging-delete-sms="$TEXTID"
		CONTACTNAME=$(sxmo_contacts.sh --name "$NUM")
		[ "$CONTACTNAME" = "???" ] && CONTACTNAME="$NUM"

		sxmo_notificationwrite.sh \
			random \
			"sxmo_modemtext.sh tailtextlog '$NUM'" \
			"$LOGDIR/$NUM/sms.txt" \
			"$CONTACTNAME: $TEXT"

		sxmo_hooks.sh sms "$CONTACTNAME" "$TEXT"
	done
}

initialmodemstatus() {
	state=$(mmcli -m "$(modem_n)")
	if echo "$state" | grep -q -E "^.*state:.*locked.*$"; then
		pidof unlocksim || sxmo_hooks.sh unlocksim &
	fi
}

"$@"
