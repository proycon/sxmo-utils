#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_icons.sh
. "$(dirname "$0")/sxmo_icons.sh"
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

stderr() {
	sxmo_log "$*"
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
	mmcli -m any --voice-list-calls -o "$VOICECALLID" -K |
		grep call.properties.number |
		cut -d ':' -f 2 |
		tr -d ' '
}

checkforfinishedcalls() {
	#find all finished calls
	for FINISHEDCALLID in $(
		mmcli -m any --voice-list-calls |
		grep terminated |
		grep -oE "Call\/[0-9]+" |
		cut -d'/' -f2
	); do
		FINISHEDNUMBER="$(lookupnumberfromcallid "$FINISHEDCALLID")"
		FINISHEDNUMBER="$(cleanupnumber "$FINISHEDNUMBER")"
		mmcli -m any --voice-delete-call "$FINISHEDCALLID"
		rm -f "$SXMO_NOTIFDIR/incomingcall_${FINISHEDCALLID}_notification"* #there may be multiple actionable notification for one call

		rm -f "$XDG_RUNTIME_DIR/${FINISHEDCALLID}.monitoredcall"

		TIME="$(date +%FT%H:%M:%S%z)"
		mkdir -p "$SXMO_LOGDIR"
		if [ -f "$XDG_RUNTIME_DIR/${FINISHEDCALLID}.discardedcall" ]; then
			#this call was discarded
			stderr "Discarded call from $FINISHEDNUMBER"
			printf %b "$TIME\tcall_finished\t$FINISHEDNUMBER\n" >> "$SXMO_LOGDIR/modemlog.tsv"
		elif [ -f "$XDG_RUNTIME_DIR/${FINISHEDCALLID}.pickedupcall" ]; then
			#this call was picked up
			pkill -f sxmo_modemcall.sh
			sxmo_hooks.sh statusbar volume
			stderr "Finished call from $FINISHEDNUMBER"
			printf %b "$TIME\tcall_finished\t$FINISHEDNUMBER\n" >> "$SXMO_LOGDIR/modemlog.tsv"
		elif [ -f "$XDG_RUNTIME_DIR/${FINISHEDCALLID}.hangedupcall" ]; then
			#this call was hung up by the user
			stderr "Finished call from $FINISHEDNUMBER"
			printf %b "$TIME\tcall_finished\t$FINISHEDNUMBER\n" >> "$SXMO_LOGDIR/modemlog.tsv"
		elif [ -f "$XDG_RUNTIME_DIR/${FINISHEDCALLID}.initiatedcall" ]; then
			#this call was hung up by the contact
			pkill -f sxmo_modemcall.sh
			sxmo_hooks.sh statusbar volume
			stderr "Finished call from $FINISHEDNUMBER"
			printf %b "$TIME\tcall_finished\t$FINISHEDNUMBER\n" >> "$SXMO_LOGDIR/modemlog.tsv"
		elif [ -f "$XDG_RUNTIME_DIR/${FINISHEDCALLID}.mutedring" ]; then
			#this ring was muted up
			stderr "Muted ring from $FINISHEDNUMBER"
			printf %b "$TIME\tring_muted\t$FINISHEDNUMBER\n" >> "$SXMO_LOGDIR/modemlog.tsv"
		else
			#this is a missed call
			# Add a notification for every missed call
			pkill -f sxmo_modemcall.sh
			sxmo_hooks.sh statusbar volume
			stderr "Missed call from $FINISHEDNUMBER"
			printf %b "$TIME\tcall_missed\t$FINISHEDNUMBER\n" >> "$SXMO_LOGDIR/modemlog.tsv"

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
		mmcli -m any --voice-list-calls -a |
		grep -Eo '[0-9]+ incoming \(ringing-in\)' |
		grep -Eo '[0-9]+'
	)"
	[ -z "$VOICECALLID" ] && return

	[ -f "$XDG_RUNTIME_DIR/${VOICECALLID}.monitoredcall" ] && return # prevent multiple rings
	find "$XDG_RUNTIME_DIR" -name "$VOICECALLID.*" -delete 2>/dev/null # we cleanup all dangling event files
	touch "$XDG_RUNTIME_DIR/${VOICECALLID}.monitoredcall" #this signals that we handled the call

	cat "$SXMO_LASTSTATE" > "$XDG_RUNTIME_DIR/${VOICECALLID}.laststate"

	# Determine the incoming phone number
	stderr "Incoming Call..."
	INCOMINGNUMBER=$(lookupnumberfromcallid "$VOICECALLID")
	INCOMINGNUMBER="$(cleanupnumber "$INCOMINGNUMBER")"
	CONTACTNAME=$(sxmo_contacts.sh --name "$INCOMINGNUMBER")

	TIME="$(date +%FT%H:%M:%S%z)"
	if cut -f1 "$SXMO_BLOCKFILE" 2>/dev/null | grep -q "^$INCOMINGNUMBER$"; then
		stderr "BLOCKED call from number: $VOICECALLID"
		sxmo_modemcall.sh mute "$VOICECALLID"
		printf %b "$TIME\tcall_ring\t$INCOMINGNUMBER\n" >> "$SXMO_BLOCKDIR/modemlog.tsv"
		rm -f "$SXMO_NOTIFDIR/incomingcall_${VOICECALLID}_notification"*
	else
		stderr "Invoking ring hook (async)"
		[ "$CONTACTNAME" = "???" ] && CONTACTNAME="$INCOMINGNUMBER"
		sxmo_hooks.sh ring "$CONTACTNAME" &

		mkdir -p "$SXMO_LOGDIR"
		printf %b "$TIME\tcall_ring\t$INCOMINGNUMBER\n" >> "$SXMO_LOGDIR/modemlog.tsv"

		sxmo_notificationwrite.sh \
			"$SXMO_NOTIFDIR/incomingcall_${VOICECALLID}_notification" \
			"sxmo_modemcall.sh incomingcallmenu '$VOICECALLID'" \
			none \
			"Incoming $icon_phn $CONTACTNAME" &
		sxmo_modemcall.sh incomingcallmenu "$VOICECALLID" &

		stderr "Call from number: $INCOMINGNUMBER (VOICECALLID: $VOICECALLID)"
	fi
}

checkfornewtexts() {
	TEXTIDS="$(
		mmcli -m any --messaging-list-sms |
		grep -Eo '/SMS/[0-9]+ \(received\)' |
		grep -Eo '[0-9]+'
	)"
	echo "$TEXTIDS" | grep -v . && return

	# Loop each textid received and read out the data into appropriate logfile
	for TEXTID in $TEXTIDS; do
		TEXTDATA="$(mmcli -m any -s "$TEXTID" -K)"
		# SMS with no TEXTID is an SMS WAP (I think). So skip.
		if [ -z "$TEXTDATA" ]; then
			stderr "Received an empty SMS (TEXTID: $TEXTID).  I will assume this is an MMS."
			printf %b "$(date +%FT%H:%M:%S%z)\tdebug_mms\tNULL\tEMPTY (TEXTID: $TEXTID)\n" >> "$SXMO_LOGDIR/modemlog.tsv"
			if [ -f "${SXMO_MMS_BASE_DIR:-"$HOME"/.mms/modemmanager}/mms" ]; then 
				if sxmo_daemons.sh running mmsd -q; then
					continue
				else
					stderr "mmsd not running."
					if pgrep -f sxmo_mmsdconfig.sh; then
						stderr "mmsdconfig running."
						continue
					fi
					stderr "restarting mmsd."
					sxmo_daemons.sh start mmsd mmsdtng "$SXMO_MMSD_ARGS"
					continue
				fi
			else
				stderr "WARNING: mmsdtng not found or unconfigured, treating as normal sms."
			fi
		fi
		TEXT="$(echo "$TEXTDATA" | grep sms.content.text | sed -E 's/^sms\.content\.text\s+:\s+//')"
		NUM="$(
			echo "$TEXTDATA" |
			grep sms.content.number |
			sed -E 's/^sms\.content\.number\s+:\s+//'
		)"
		NUM="$(cleanupnumber "$NUM")"

		# vvmd will mormally swallow sms numbers from VVMDestinationNumber, so if we receive an sms
		# from that number, we know vvmd is either not configured or it is crashed.
		if [ -f "${SXMO_VVM_BASE_DIR:-"$HOME"/.vvm/modemmanager}/vvm" ]; then
			VVM_NUM="$(grep "^VVMDestinationNumber" "${SXMO_VVM_BASE_DIR:-"$HOME"/.vvm/modemmanager}/vvm" | cut -d'=' -f2)"
			if [ "$NUM" = "$VVM_NUM" ]; then
				stderr "WARNING: number ($NUM) is VVMDestinationNumber ($VVM_NUM). Vvmd must be down."
				if pgrep -f sxmo_vvmdconfig; then
					stderr "vvmdconfig running, doing nothing."
				else
					stderr "starting vvmd."
					sxmo_daemons.sh start vvmd vvmd "$SXMO_VVMD_ARGS"
				fi
			fi
		fi

		TIME="$(echo "$TEXTDATA" | grep sms.properties.timestamp | sed -E 's/^sms\.properties\.timestamp\s+:\s+//')"
		TIME="$(date +%FT%H:%M:%S%z -d "$TIME")"

		# Note: this will *not* block MMS, since we have to unpack the phone numbers for an MMS
		# later.
		#
		# TODO: a user *could* block the sms wap number (which would be user error).  But then
		# the mms would not be processed.  So probably give a warning here if the user has blocked 
		# the sms wap number?
		if cut -f1 "$SXMO_BLOCKFILE" 2>/dev/null | grep -q "^$NUM$"; then
			mkdir -p "$SXMO_BLOCKDIR/$NUM"
			stderr "BLOCKED text from number: $NUM (TEXTID: $TEXTID)"
			printf %b "Received from $NUM at $TIME:\n$TEXT\n\n" >> "$SXMO_BLOCKDIR/$NUM/sms.txt"
			printf %b "$TIME\trecv_txt\t$NUM\t${#TEXT} chars\n" >> "$SXMO_BLOCKDIR/modemlog.tsv"
			mmcli -m any --messaging-delete-sms="$TEXTID"
			continue
		fi

		if [ "$TEXT" = "--" ]; then
			stderr "Text from $NUM (TEXTID: $TEXTID) with '--'.  I will assume this is an MMS."
			printf %b "$TIME\tdebug_mms\t$NUM\t$TEXT\n" >> "$SXMO_LOGDIR/modemlog.tsv"
			if [ -f "${SXMO_MMS_BASE_DIR:-"$HOME"/.mms/modemmanager}/mms" ]; then
				if sxmo_daemons.sh running mmsd -q; then
					continue
				else
					stderr "mmsd not running."
					if pgrep -f sxmo_mmsdconfig.sh; then
						stderr "mmsdconfig running."
						continue
					fi
					stderr "restarting mmsd."
					sxmo_daemons.sh start mmsd mmsdtng "$SXMO_MMSD_ARGS"
					continue
				fi
			else
				stderr "WARNING: mmsdtng not found or unconfigured, treating as normal sms."
			fi
		fi

		mkdir -p "$SXMO_LOGDIR/$NUM"
		stderr "Text from number: $NUM (TEXTID: $TEXTID)"
		printf %b "Received SMS from $NUM at $TIME:\n$TEXT\n\n" >> "$SXMO_LOGDIR/$NUM/sms.txt"
		printf %b "$TIME\trecv_txt\t$NUM\t${#TEXT} chars\n" >> "$SXMO_LOGDIR/modemlog.tsv"
		mmcli -m any --messaging-delete-sms="$TEXTID"
		CONTACTNAME=$(sxmo_contacts.sh --name "$NUM")
		[ "$CONTACTNAME" = "???" ] && CONTACTNAME="$NUM"

		sxmo_notificationwrite.sh \
			random \
			"sxmo_modemtext.sh tailtextlog '$NUM'" \
			"$SXMO_LOGDIR/$NUM/sms.txt" \
			"$CONTACTNAME: $TEXT"

		sxmo_hooks.sh sms "$CONTACTNAME" "$TEXT"
	done
}

initialmodemstatus() {
	state=$(mmcli -m any)
	if echo "$state" | grep -q -E "^.*state:.*locked.*$"; then
		pidof unlocksim || sxmo_hooks.sh unlocksim &
	fi
}

"$@"
