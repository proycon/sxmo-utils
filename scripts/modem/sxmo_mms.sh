#!/usr/bin/env sh
# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

# if mmsdtng is running but sxmo_modemmonitor.sh wasn't running (or in other odd cases) we might
# have mms in mmsdtng that aren't downloaded.  this quick function will grab them and populate
# sxmo with them.
# run from commandline, e.g., sxmo_mms.sh downloadmissedmms
downloadmissedmms() {
	ALL_MMS_TEMP="$(mktemp)"
	LOCAL_MMS_TEMP="$(mktemp)"
	SERVER_MMS_TEMP="$(mktemp)"
	echo "Making list of all MMS messages on server."
	mmsctl -M | jq -r '.message_path' | rev | cut -d'/' -f1 | rev | sort -u > "$ALL_MMS_TEMP"
	echo "Got $(wc -l < "$ALL_MMS_TEMP") messages."
	echo "Making list of local MMS messages."
	cut -f 4 < "$LOGDIR/modemlog.tsv" | grep -v 'chars' | sort -u > "$LOCAL_MMS_TEMP"
	echo "Got $(wc -l < "$LOCAL_MMS_TEMP") messages."

	echo "Comparing them and making list of MMS messages ONLY on server."
	# see comm manpage: prints only unique files in ALL_MMS_TMP, i.e., files only on server
	comm -23 "$ALL_MMS_TEMP" "$LOCAL_MMS_TEMP" > "$SERVER_MMS_TEMP"
	count="$(wc -l < "$SERVER_MMS_TEMP")"
	echo "Got $count messages."
	if [ "$count" -gt 0 ]; then
		read -r "Warning. This will download all the undownloaded MMS messages still on server and process them. Continue?  Any key to continue."

		while read -r line; do
			processmms "/org/ofono/mms/modemmanager/$line" "Unknown"
		done < "$SERVER_MMS_TEMP"
		echo "Done!"
	else
		echo "No outstanding messages. Done!"
	fi
	echo "Cleaning up temp files."
	rm "$ALL_MMS_TEMP"
	rm "$LOCAL_MMS_TEMP"
	rm "$SERVER_MMS_TEMP"
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

		if [ -f "$MMS_RECEIVED_DIR/$MMS_FILE" ]; then
			OUTFILE="$MMS_FILE.$DATA_EXT"
			count=0
			while [ -f "$LOGDIR/$LOGDIRNUM/attachments/$OUTFILE" ]; do
				OUTFILE="$MMS_FILE-$count.$DATA_EXT"
				count="$((count+1))"
			done
			dd skip="$AOFFSET" count="$ASIZE" \
				if="$MMS_RECEIVED_DIR/$MMS_FILE" \
				of="$LOGDIR/$LOGDIRNUM/attachments/$OUTFILE" \
				bs=1 >/dev/null 2>&1
		fi

		if [ "$ACTYPE" != "text/plain" ]; then
			printf "$icon_att %s\n" \
				"$(basename "$LOGDIR/$LOGDIRNUM/attachments/$OUTFILE")" \
				>> "$LOGDIR/$LOGDIRNUM/sms.txt"

			printf "%s\0" "$LOGDIR/$LOGDIRNUM/attachments/$OUTFILE"
		fi
	done
}

processmms() {
	MESSAGE_PATH="$1"
	MESSAGE_TYPE="$2" # Sent or Received or Unknown
	MESSAGE="$(mmsctl -M -o "$MESSAGE_PATH")"
	echo "sxmo_mms.sh processmms $MESSAGE_PATH $MESSAGE_TYPE">&2

	# If a message expires on the server-side, just chuck it
	if printf %s "$MESSAGE" | grep -q "Accept-Charset (deprecated): Message not found"; then
		echo "sxmo_modemmonitor: $MESSAGE_PATH not found! Deleting.">&2
		mmsctl -D -o "$MESSAGE_PATH"
		return
	fi

	# Unknown is what downloadmissedmms() sends.
	if [ "$MESSAGE_TYPE" = "Unknown" ]; then
		MESSAGE_TYPE="$(printf %s "$MESSAGE" | jq -r '.attrs.Status')"
		case "$MESSAGE_TYPE" in
			sent)
				MESSAGE_TYPE="Sent"
				;;
			draft)
				MESSAGE_TYPE="Sent"
				echo "WARNING: Draft">&2
				;;
			received)
				MESSAGE_TYPE="Received"
				;;
			*)
				echo "Bad message type: $MESSAGE_TYPE">&2
				return
				;;
		esac
	fi

	MMS_FILE="$(printf %s "$MESSAGE_PATH" | rev | cut -d'/' -f1 | rev)"
	DATE="$(printf %s "$MESSAGE" | jq -r '.attrs.Date')"
	MYNUM="$(printf %s "$MESSAGE" | jq -r '.attrs."Modem Number"')"

	if [ "$MESSAGE_TYPE" = "Sent" ]; then
		FROM_NUM="$MYNUM"
	else
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
		mkdir -p "$LOGDIR/$LOGDIRNUM"
		printf "%s Group MMS from %s to %s at %s:\n" "$MESSAGE_TYPE" "$FROM_NAME" "$TO_NAMES" "$DATE" >> "$LOGDIR/$LOGDIRNUM/sms.txt"
	else
		# not a group chat
		if [ "$MESSAGE_TYPE" = "Sent" ]; then
			LOGDIRNUM="$TO_NUMS"
		else
			LOGDIRNUM="$FROM_NUM"
		fi
		mkdir -p "$LOGDIR/$LOGDIRNUM"
		printf "%s MMS from %s at %s:\n" "$MESSAGE_TYPE" "$FROM_NAME" "$DATE" >> "$LOGDIR/$LOGDIRNUM/sms.txt"
	fi
	echo "sxmo_modemmonitor: $MESSAGE_TYPE MMS ($MMS_FILE) from number: $FROM_NUM to number: $TO_NUMS">&2

	mkdir -p "$LOGDIR/$LOGDIRNUM/attachments"

	if [ "$MESSAGE_TYPE" = "Received" ]; then
		printf "%s\trecv_mms\t%s\t%s\n" "$DATE" "$LOGDIRNUM" "$MMS_FILE" >> "$LOGDIR/modemlog.tsv"
	else
		printf "%s\tsent_mms\t%s\t%s\n" "$DATE" "$LOGDIRNUM" "$MMS_FILE" >> "$LOGDIR/modemlog.tsv"
	fi

	# process 'content' of mms payload
	OPEN_ATTACHMENTS_CMD="$(printf %s "$MESSAGE" | extractmmsattachement | xargs -0 printf "sxmo_open.sh '%s'; " | sed "s/sxmo_open.sh ''; //")"
	if [ -f "$LOGDIR/$LOGDIRNUM/attachments/$MMS_FILE.txt" ]; then
		TEXT="$(cat "$LOGDIR/$LOGDIRNUM/attachments/$MMS_FILE.txt")"
		rm -f "$LOGDIR/$LOGDIRNUM/attachments/$MMS_FILE.txt"
	else
		TEXT="<Empty>"
	fi

	printf "%b\n\n" "$TEXT" >> "$LOGDIR/$LOGDIRNUM/sms.txt"

	if [ "$MESSAGE_TYPE" = "Received" ]; then
		[ -n "$OPEN_ATTACHMENTS_CMD" ] && TEXT="$icon_att $TEXT"

		sxmo_notificationwrite.sh \
			random \
			"TERMNAME=\"$LOGDIRNUM SMS\" sxmo_terminal.sh sh -c \"""${OPEN_ATTACHMENTS_CMD}""sxmo_modemtext.sh tailtextlog \"$LOGDIRNUM\"\"" \
			"$LOGDIR/$LOGDIRNUM/sms.txt" \
			"$FROM_NAME: $TEXT ($MMS_FILE)"

		if [ "$count" -gt 0 ]; then
			sxmo_hooks.sh sms "$FROM_NAME <$(sxmo_contacts.sh --name "$LOGDIRNUM")>" "$TEXT ($MMS_FILE)"
		else
			sxmo_hooks.sh sms "$FROM_NAME" "$TEXT ($MMS_FILE)"
		fi
	fi
}

"$@"
