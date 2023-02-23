#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

# We use this directory to store states, so it must exist
mkdir -p "$XDG_RUNTIME_DIR/sxmo_calls"

stderr() {
	sxmo_log "$*"
}

cleanupnumber() {
	if pnc valid "$1"; then
		echo "$1"
		return
	fi

	REFORMATTED="$(pnc find ${DEFAULT_COUNTRY:+-c "$DEFAULT_COUNTRY"} "$1")"
	if [ -n "$REFORMATTED" ]; then
		echo "$REFORMATTED"
		return
	fi

	echo "$1"
}

checkforfinishedcalls() {
	#find all finished calls
	for FINISHEDCALLID in $(
		mmcli -m any --voice-list-calls |
		grep terminated |
		grep -oE "Call\/[0-9]+" |
		cut -d'/' -f2
	); do
		FINISHEDNUMBER="$(sxmo_modemcall.sh vid_to_number "$FINISHEDCALLID")"
		FINISHEDNUMBER="$(cleanupnumber "$FINISHEDNUMBER")"
		mmcli -m any --voice-delete-call "$FINISHEDCALLID"

		rm -f "$XDG_RUNTIME_DIR/sxmo_calls/${FINISHEDCALLID}.monitoredcall"

		CONTACT="$(sxmo_contacts.sh --name "$FINISHEDNUMBER")"
		[ "$CONTACT" = "???" ] && CONTACT="$FINISHEDNUMBER"

		TIME="$(date +%FT%H:%M:%S%z)"
		mkdir -p "$SXMO_LOGDIR"
		if [ -f "$XDG_RUNTIME_DIR/sxmo_calls/${FINISHEDCALLID}.discardedcall" ]; then
			#this call was discarded
			sxmo_notify_user.sh "Call with $CONTACT terminated"
			stderr "Discarded call from $FINISHEDNUMBER"
			printf %b "$TIME\tcall_finished\t$FINISHEDNUMBER\n" >> "$SXMO_LOGDIR/modemlog.tsv"
		elif [ -f "$XDG_RUNTIME_DIR/sxmo_calls/${FINISHEDCALLID}.pickedupcall" ]; then
			#this call was picked up
			sxmo_notify_user.sh "Call with $CONTACT terminated"
			stderr "Finished call from $FINISHEDNUMBER"
			printf %b "$TIME\tcall_finished\t$FINISHEDNUMBER\n" >> "$SXMO_LOGDIR/modemlog.tsv"
		elif [ -f "$XDG_RUNTIME_DIR/sxmo_calls/${FINISHEDCALLID}.hangedupcall" ]; then
			#this call was hung up by the user
			sxmo_notify_user.sh "Call with $CONTACT terminated"
			stderr "Finished call from $FINISHEDNUMBER"
			printf %b "$TIME\tcall_finished\t$FINISHEDNUMBER\n" >> "$SXMO_LOGDIR/modemlog.tsv"
		elif [ -f "$XDG_RUNTIME_DIR/sxmo_calls/${FINISHEDCALLID}.initiatedcall" ]; then
			#this call was hung up by the contact
			sxmo_notify_user.sh "Call with $CONTACT terminated"
			stderr "Finished call from $FINISHEDNUMBER"
			printf %b "$TIME\tcall_finished\t$FINISHEDNUMBER\n" >> "$SXMO_LOGDIR/modemlog.tsv"
		elif [ -f "$XDG_RUNTIME_DIR/sxmo_calls/${FINISHEDCALLID}.mutedring" ]; then
			#this ring was muted up
			stderr "Muted ring from $FINISHEDNUMBER"
			printf %b "$TIME\tring_muted\t$FINISHEDNUMBER\n" >> "$SXMO_LOGDIR/modemlog.tsv"
		else
			#this is a missed call
			# Add a notification for every missed call

			NOTIFMSG="Missed call from $CONTACT ($FINISHEDNUMBER)"
			stderr "$NOTIFMSG"
			printf %b "$TIME\tcall_missed\t$FINISHEDNUMBER\n" >> "$SXMO_LOGDIR/modemlog.tsv"

			stderr "Invoking missed call hook (async)"
			sxmo_hook_missed_call.sh "$CONTACT" &

			sxmo_notificationwrite.sh \
				random \
				"TERMNAME='$NOTIFMSG' sxmo_terminal.sh sh -c \"echo '$NOTIFMSG at $(date)' && read\"" \
				none \
				"Missed $icon_phn $CONTACT ($FINISHEDNUMBER)"
		fi

		# If it was the last call
		if ! sxmo_modemcall.sh list_active_calls | grep -q .; then
			# Cleanup
			sxmo_vibrate 1000 &
			sxmo_daemons.sh stop incall_menu
			sxmo_daemons.sh stop proximity_lock

			if ! sxmo_modemaudio.sh reset_audio; then
				sxmo_notify_user.sh --urgency=critical "We failed to reset call audio"
			fi
		else
			# Or refresh the menu
			sxmo_daemons.sh start incall_menu sxmo_modemcall.sh incall_menu
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

	[ -f "$XDG_RUNTIME_DIR/sxmo_calls/${VOICECALLID}.monitoredcall" ] && return # prevent multiple rings
	rm "$XDG_RUNTIME_DIR/sxmo_calls/$VOICECALLID."* 2>/dev/null # we cleanup all dangling event files
	touch "$XDG_RUNTIME_DIR/sxmo_calls/${VOICECALLID}.monitoredcall" #this signals that we handled the call

	# Determine the incoming phone number
	stderr "Incoming Call..."
	INCOMINGNUMBER=$(sxmo_modemcall.sh vid_to_number "$VOICECALLID")
	INCOMINGNUMBER="$(cleanupnumber "$INCOMINGNUMBER")"
	CONTACTNAME=$(sxmo_contacts.sh --name "$INCOMINGNUMBER")

	TIME="$(date +%FT%H:%M:%S%z)"
	if cut -f1 "$SXMO_BLOCKFILE" 2>/dev/null | grep -q "^$INCOMINGNUMBER$"; then
		stderr "BLOCKED call from number: $VOICECALLID"
		sxmo_modemcall.sh mute "$VOICECALLID"
		printf %b "$TIME\tcall_ring\t$INCOMINGNUMBER\n" >> "$SXMO_BLOCKDIR/modemlog.tsv"
	else
		stderr "Invoking ring hook (async)"
		[ "$CONTACTNAME" = "???" ] && CONTACTNAME="$INCOMINGNUMBER"
		sxmo_hook_ring.sh "$CONTACTNAME" &

		mkdir -p "$SXMO_LOGDIR"
		printf %b "$TIME\tcall_ring\t$INCOMINGNUMBER\n" >> "$SXMO_LOGDIR/modemlog.tsv"

		sxmo_daemons.sh start proximity_lock sxmo_proximitylock.sh

		# If we already got an active call
		if sxmo_modemcall.sh list_active_calls \
			| grep -v ringing-in \
			| grep -q .; then
			# Refresh the incall menu
			sxmo_daemons.sh start incall_menu sxmo_modemcall.sh incall_menu
		else
			# Or fire the incomming call menu
			sxmo_daemons.sh start incall_menu sxmo_modemcall.sh incoming_call_menu "$VOICECALLID"
		fi

		stderr "Call from number: $INCOMINGNUMBER (VOICECALLID: $VOICECALLID)"
	fi
}

# this function is called in the modem hook when the modem registers
checkforstucksms() {
	stuck_messages="$(mmcli -m any --messaging-list-sms)"
	if ! echo "$stuck_messages" | grep -q "^No sms messages were found"; then
		sxmo_notify_user.sh "WARNING: $(echo "$stuck_messages" | wc -l) stuck sms found.  Run sxmo_modem.sh checkforstucksms view to view or delete to delete."
		case "$1" in
			"delete")
				mmcli -m any --messaging-list-sms | while read -r line; do
					sms_number="$(echo "$line" | cut -d'/' -f6 | cut -d' ' -f1)"
					sxmo_log "Deleting sms $sms_number"
					mmcli -m any --messaging-delete-sms="$sms_number"
				done
				;;
			"view")
				mmcli -m any --messaging-list-sms | while read -r line; do
					sms_number="$(echo "$line" | cut -d'/' -f6 | cut -d' ' -f1)"
					mmcli -m any -s "$sms_number" -K
				done
				;;
		esac
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
				continue
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
				continue
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

		if [ -z "$SXMO_DISABLE_SMS_NOTIFS" ]; then
			sxmo_notificationwrite.sh \
				random \
				"sxmo_hook_tailtextlog.sh '$NUM'" \
				"$SXMO_LOGDIR/$NUM/sms.txt" \
				"$CONTACTNAME: $TEXT"
		fi

		if grep -q screenoff "$SXMO_STATE"; then
			sxmo_hook_lock.sh
		fi

		sxmo_hook_sms.sh "$CONTACTNAME" "$TEXT"
	done
}

sxmo_wakelock.sh lock modem_used 30000000000
"$@"
sxmo_wakelock.sh unlock modem_used
