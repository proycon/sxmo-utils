#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_icons.sh
. "$(dirname "$0")/sxmo_icons.sh"
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

stderr() {
	sxmo_log "$*"
}

checkmmsd() {
	if [ -d "${SXMO_MMS_BASE_DIR:-"$HOME"/.mms/modemmanager}" ]; then
		sxmo_daemons.sh running mmsd -q && return
		pgrep -f sxmo_mmsdconfig.sh && return
		stderr "mmsdtng not found, attempting to start it." >&2
		sxmo_daemons.sh start mmsd mmsdtng "$SXMO_MMSD_ARGS"
	fi
}

# This function checks to see if there are orphaned mms messages on the server.
# This shouldn't happen if SXMO_MMS_AUTO_DELETE is set to 1 (default).
# However, it sometimes will, for instance, during a crash.  This function run
# whenever the modem is REGISTERED in sxmo_modemmonitor.sh.  If the argument
# "--force" is passed then it will *actually* process these files, otherwise it
# will just report them.  I do not recommend automatically running these, since
# there might be a race condition.  Hence, to manually process these files,
# run: sxmo_mms.sh checkforlostmms --force
#
checkforlostmms() {
	# only run if SXMO_MMS_AUTO_DELETE is set to 1 (default)
	[ "${SXMO_MMS_AUTO_DELETE:-1}" -eq 1 ] || exit

	if [ "$1" = "--force" ]; then
		FORCE=1
	else
		FORCE=0
	fi

	# generate a list of all messages on the server
	ALL_MMS_TEMP="$(mktemp)"
	dbus-send --dest=org.ofono.mms --print-reply /org/ofono/mms/modemmanager org.ofono.mms.Service.GetMessages | grep "object path" | cut -d'"' -f2 | rev | cut -d'/' -f1 | rev | sort -u > "$ALL_MMS_TEMP"
	count="$(wc -l < "$ALL_MMS_TEMP")"

	# loop through messages and report (or process if FORCE=1) them
	# we delete messages with status draft, and process those with sent 
	# and received
	if [ "$count" -gt 0 ]; then
		stderr "WARNING! Found $count unprocessed mms messages."
		while read -r line; do
			stderr "... mms $line"
			MESSAGE_STATUS="$(mmsctl -M -o "/org/ofono/mms/modemmanager/$line" | jq -r '.attrs.Status')"
			case "$MESSAGE_STATUS" in
				sent)
					stderr "This mms is status:sent."
					[ "$FORCE" -eq 1 ] && processmms "/org/ofono/mms/modemmanager/$line" "Sent"
					;;
				draft)
					stderr "This mms is status:draft."
					[ "$FORCE" -eq 1 ] && dbus-send --dest=org.ofono.mms --print-reply "/org/ofono/mms/modemmanager/$line" org.ofono.mms.Message.Delete
					;;
				received)
					stderr "This mms is status:received."
					[ "$FORCE" -eq 1 ] && processmms "/org/ofono/mms/modemmanager/$line" "Received"

					;;
				*)
					stderr "This mms has a bad message type: '$MESSAGE_STATUS'. Bailing."
					;;
			esac
		done < "$ALL_MMS_TEMP"
		stderr "Done."
		if [ "$FORCE" -eq 1 ]; then
			stderr "Processed."
		else 
			stderr "Did not process anything. Run \"sxmo_mms.sh checkforlostmms --force\" to process, if you are sure."
		fi
	else
		stderr "No unprocessed mms messages found.  Good job."
	fi
	rm "$ALL_MMS_TEMP"
}

# called from sxmo_modemsendsms.sh, deletes *all* drafts
deletedrafts() {
	# generate a list of all messages
	ALL_MMS_TEMP="$(mktemp)"
	dbus-send --dest=org.ofono.mms --print-reply /org/ofono/mms/modemmanager org.ofono.mms.Service.GetMessages | grep "object path" | cut -d'"' -f2 | rev | cut -d'/' -f1 | rev | sort -u > "$ALL_MMS_TEMP"
	count="$(wc -l < "$ALL_MMS_TEMP")"
	if [ "$count" -gt 0 ]; then
		stderr "Found $count unprocessed mms messages. Deleting all drafts, if any."
		while read -r line; do
			if mmsctl -M -o "/org/ofono/mms/modemmanager/$line" | jq -r '.attrs.Status' | grep -q "draft"; then
				stderr "This mms ($line) is a draft. Deleting it."
				dbus-send --dest=org.ofono.mms --print-reply "/org/ofono/mms/modemmanager/$line" org.ofono.mms.Message.Delete
			fi
		done < "$ALL_MMS_TEMP"
		stderr "Done"
	else
		stderr "No unprocessed mms messages found. Doing nothing."
	fi
	rm "$ALL_MMS_TEMP"
}

# stdout extracted mms file paths
extractmmsattachement() {
	jq -r '.attrs.Attachments[] | join(",")' | while read -r aline; do
		ACTYPE="$(printf %s "$aline" | cut -d',' -f2 | cut -d';' -f1 | sed 's|^Content-Type: "\(.*\)"$|\1|')"
		AOFFSET="$(printf %s "$aline" | cut -d',' -f4)"
		ASIZE="$(printf %s "$aline" | cut -d',' -f5)"
		case "$ACTYPE" in
			text/plain)
				DATA_EXT="txt"
				;;
			image/gif)
				DATA_EXT="gif"
				;;
			image/png)
				DATA_EXT="png"
				;;
			image/jpeg)
				DATA_EXT="jpeg"
				;;
			video/*)
				DATA_EXT="video"
				;;
			*)
				DATA_EXT="bin"
				;;
		esac

		MMS_BASE_DIR="${SXMO_MMS_BASE_DIR:-"$HOME"/.mms/modemmanager}" 
		if [ -f "$MMS_BASE_DIR/$MMS_FILE" ]; then
			OUTFILE="$MMS_FILE.$DATA_EXT"
			count=0
			while [ -f "$SXMO_LOGDIR/$LOGDIRNUM/attachments/$OUTFILE" ]; do
				OUTFILE="$MMS_FILE-$count.$DATA_EXT"
				count="$((count+1))"
			done
			dd skip="$AOFFSET" count="$ASIZE" \
				if="$MMS_BASE_DIR/$MMS_FILE" \
				of="$SXMO_LOGDIR/$LOGDIRNUM/attachments/$OUTFILE" \
				bs=1 >/dev/null 2>&1
		fi

		if [ "$ACTYPE" != "text/plain" ]; then
			printf "$icon_att %s\n" \
				"$(basename "$SXMO_LOGDIR/$LOGDIRNUM/attachments/$OUTFILE")" \
				>> "$SXMO_LOGDIR/$LOGDIRNUM/sms.txt"

			printf "%s\0" "$SXMO_LOGDIR/$LOGDIRNUM/attachments/$OUTFILE"
		fi
	done
}

processmms() {
	MESSAGE_PATH="$1"
	MESSAGE_TYPE="$2" # Sent or Received
	MESSAGE="$(mmsctl -M -o "$MESSAGE_PATH")"
	stderr "Processing mms ($MESSAGE_PATH)."

	# If a message expires on the server-side, just chuck it
	if printf %s "$MESSAGE" | grep -q "Accept-Charset (deprecated): Message not found"; then
		stderr "The mms ($MESSAGE_PATH) states: 'Message not found'. Deleting."
		dbus-send --dest=org.ofono.mms --print-reply "$MESSAGE_PATH" org.ofono.mms.Message.Delete
		printf "%s\tdebug_mms\t%s\t%s\n" "$(date +%FT%H:%M:%S%z)" "NULL" "ERROR: Message not found." >> "$SXMO_LOGDIR/modemlog.tsv"
		return
	fi

	MMS_FILE="$(printf %s "$MESSAGE_PATH" | rev | cut -d'/' -f1 | rev)"
	DATE="$(printf %s "$MESSAGE" | jq -r '.attrs.Date')"
	DATE="$(date +%FT%H:%M:%S%z -d "$DATE")"

	MYNUM="$(printf %s "$MESSAGE" | jq -r '.attrs."Modem Number"')"
	if [ -z "$MYNUM" ]; then
		MYNUM="$(sxmo_contacts.sh --me)"
		if [ -z "$MYNUM" ]; then
			stderr "The mms ($MMS_FILE) does not have a 'Modem Number'."
			stderr "This probably means you need to configure the Me contact."
			stderr "We will use a fake number in the meanwhile: +12345670000."
			MYNUM="+12345670000"
		fi
	fi

	if [ "$MESSAGE_TYPE" = "Sent" ]; then
		FROM_NUM="$MYNUM"
	elif [ "$MESSAGE_TYPE" = "Received" ]; then
		FROM_NUM="$(printf %s "$MESSAGE" | jq -r '.attrs.Sender')"
	fi

	FROM_NAME="$(sxmo_contacts.sh --name "$FROM_NUM")"
	TO_NUMS="$(printf %s "$MESSAGE" | jq -r '.attrs.Recipients | join("\n")')"
	# generate string of contact names, e.g., "BOB, SUZIE, SAM"
	TO_NAMES="$(printf %s "$TO_NUMS" | xargs -n1 sxmo_contacts.sh --name | tr '\n' '\0' | xargs -0 printf "%s, " | sed 's/, $//')"

	count="$(printf "%s" "$TO_NUMS" | wc -l)"
	if [ "$count" -gt 0 ]; then
		# a group chat.  LOGDIRNUM = all numbers except one's own, sorted numerically
		LOGDIRNUM="$(printf "%b\n%s\n" "$TO_NUMS" "$FROM_NUM" | grep -v "^$MYNUM$" | sort -u | grep . | xargs printf %s)"
		mkdir -p "$SXMO_LOGDIR/$LOGDIRNUM"
		printf "%s Group MMS from %s to %s at %s:\n" "$MESSAGE_TYPE" "$FROM_NAME" "$TO_NAMES" "$DATE" >> "$SXMO_LOGDIR/$LOGDIRNUM/sms.txt"
	else
		# not a group chat
		if [ "$MESSAGE_TYPE" = "Sent" ]; then
			LOGDIRNUM="$TO_NUMS"
		elif [ "$MESSAGE_TYPE" = "Received" ]; then
			LOGDIRNUM="$FROM_NUM"
		fi
		mkdir -p "$SXMO_LOGDIR/$LOGDIRNUM"
		printf "%s MMS from %s at %s:\n" "$MESSAGE_TYPE" "$FROM_NAME" "$DATE" >> "$SXMO_LOGDIR/$LOGDIRNUM/sms.txt"
	fi

	stderr "$MESSAGE_TYPE MMS ($MMS_FILE) from number $LOGDIRNUM"

	if cut -f1 "$SXMO_BLOCKFILE" 2>/dev/null | grep -q "^$LOGDIRNUM$"; then
		mkdir -p "$SXMO_BLOCKDIR/$LOGDIRNUM"
		stderr "BLOCKED mms from number: $LOGDIRNUM ($MMS_FILE)."
		SXMO_LOGDIR="$SXMO_BLOCKDIR"
	fi

	mkdir -p "$SXMO_LOGDIR/$LOGDIRNUM/attachments"

	if [ "$MESSAGE_TYPE" = "Received" ]; then
		printf "%s\trecv_mms\t%s\t%s\n" "$DATE" "$LOGDIRNUM" "$MMS_FILE" >> "$SXMO_LOGDIR/modemlog.tsv"
	elif [ "$MESSAGE_TYPE" = "Sent" ]; then
		printf "%s\tsent_mms\t%s\t%s\n" "$DATE" "$LOGDIRNUM" "$MMS_FILE" >> "$SXMO_LOGDIR/modemlog.tsv"
	else
		stderr "Unknown message type: $MESSAGE_TYPE for $MMS_FILE"
	fi

	# process 'content' of mms payload
	OPEN_ATTACHMENTS_CMD="$(printf %s "$MESSAGE" | extractmmsattachement | xargs -0 printf "sxmo_open.sh '%s'; " | sed "s/sxmo_open.sh ''; //")"
	if [ -f "$SXMO_LOGDIR/$LOGDIRNUM/attachments/$MMS_FILE.txt" ]; then
		TEXT="$(cat "$SXMO_LOGDIR/$LOGDIRNUM/attachments/$MMS_FILE.txt")"
		rm -f "$SXMO_LOGDIR/$LOGDIRNUM/attachments/$MMS_FILE.txt"
	else
		TEXT="<Empty>"
	fi

	printf "%b\n\n" "$TEXT" >> "$SXMO_LOGDIR/$LOGDIRNUM/sms.txt"

	if [ "$MESSAGE_TYPE" = "Received" ]; then
		[ -n "$OPEN_ATTACHMENTS_CMD" ] && TEXT="$icon_att $TEXT"
		[ "$FROM_NAME" = "???" ] && FROM_NAME="$FROM_NUM"
		sxmo_notificationwrite.sh \
			random \
			"${OPEN_ATTACHMENTS_CMD}sxmo_modemtext.sh tailtextlog \"$LOGDIRNUM\"" \
			"$SXMO_LOGDIR/$LOGDIRNUM/sms.txt" \
			"$FROM_NAME: $TEXT ($MMS_FILE)"

		if [ "$count" -gt 0 ]; then
			GROUPNAME="$(sxmo_contacts.sh --name "$LOGDIRNUM")"
			[ "$GROUPNAME" = "???" ] && GROUPNAME="$LOGDIRNUM"
			sxmo_hooks.sh sms "$FROM_NAME" "$TEXT" "$MMS_FILE" "$GROUPNAME"
		else
			sxmo_hooks.sh sms "$FROM_NAME" "$TEXT" "$MMS_FILE"
		fi
	fi

	if [ "${SXMO_MMS_AUTO_DELETE:-1}" -eq 1 ]; then
		# keep the mms payload file (useful for debugging)
		if [ "${SXMO_MMS_KEEP_MMSFILE:-1}" -eq 1 ]; then
			MMS_BASE_DIR="${SXMO_MMS_BASE_DIR-"$HOME"/.mms/modemmanager}" 
			mkdir -p "$MMS_BASE_DIR/bak"
			cp "$MMS_BASE_DIR/$MMS_FILE" "$MMS_BASE_DIR/bak/$MMS_FILE"
		fi
		dbus-send --dest=org.ofono.mms --print-reply "$MESSAGE_PATH" org.ofono.mms.Message.Delete
		stderr "Finished processing $MMS_FILE. Deleting it."
	fi
}

"$@"
