#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

info() {
	echo "$(date) $*" >> /dev/stderr
}

err() {
	info "ERR: $*"
	exit 1
}

usage() {
	err "Usage: $(basename "$0") number or contact [-|message]"
}

modem_n() {
	MODEMS="$(mmcli -L)"
	echo "$MODEMS" | grep -qoE 'Modem\/([0-9]+)' || err "Couldn't find modem - is your modem enabled?"
	echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
}

[ 0 -eq $# ] && usage
NUMBER="$1"

# if $1 is not a number, then assume its a contact and look up number
if ! echo "$NUMBER" | grep -q '+'; then
	ACTUAL_NUMBER="$(sxmo_contacts.sh --all | grep "^$NUMBER:" | cut -d':' -f2 | sed 's/^ //')"
	if [ -z "$ACTUAL_NUMBER" ]; then
		info "$NUMBER does not look like a number, but it isn't in your contacts either.  Continuing anyway..."
	else
		NUMBER="$ACTUAL_NUMBER"
	fi
fi

if [ "-" = "$2" ]; then
	TEXT="$(cat)"
else
	shift
	[ 0 -eq $# ] && usage

	TEXT="$*"
fi

# if multiple recipients or attachment, then send via mmsctl
if [ "$(printf %s "$NUMBER" | xargs pn find | wc -l)" -gt 1 ] || [ -f "$LOGDIR/$NUMBER/draft.attachments.txt" ]; then
	# generate mmsctl args for attachments found in draft.attachments.txt (one per line)
	count=0
	total_size=0
	ATTACHMENTS=
	if [ -f "$LOGDIR/$NUMBER/draft.attachments.txt" ]; then
		# shellcheck disable=SC2141
		IFS='\n'
		while read -r line; do
			[ -f "$line" ] || err "File not found!"
			CTYPE=$(file -b --mime-type "$line")
			# file returns longer mime-types than mmsctl likes 
			# TODO: I have only tested jpeg and mp3
			case "$CTYPE" in
				"audio/mpegapplication/octet-stream")
					CTYPE="audio/mpeg"
					;;
			esac
			ATTACHMENTS="$(printf "%s -a '%s' -c '%s'" "$ATTACHMENTS" "$line" "$CTYPE")" # argument for mmsctl
			count="$((count+1))"
			total_size="$((total_size+$(wc -c < "$line")))"
		done < "$LOGDIR/$NUMBER/draft.attachments.txt"
	fi

	# basic mms error checking (since mmsctl does not do it)
	TOT_MAX_ATTACHMENT_SIZE="$(grep "^TotalMaxAttachmentSize" "$MMS_RECEIVED_DIR/mms" | cut -d'=' -f2)"
	MAX_ATTACHMENTS="$(grep "^MaxAttachments" "$MMS_RECEIVED_DIR/mms" | cut -d'=' -f 2)"
	[ -z "$MAX_ATTACHMENTS" ] && MAX_ATTACHMENTS="25"
	[ -z "$TOT_MAX_ATTACHMENT_SIZE" ] && TOT_MAX_ATTACHMENT_SIZE="1100000"
	[ "$count" -gt "$MAX_ATTACHMENTS" ] && err "Number of attachments ($count) greater than MaxAttachments ($MAX_ATTACHMENTS)."
	[ "$count" -ge 1 ] && [ "$total_size" -gt "$TOT_MAX_ATTACHMENT_SIZE" ] && err "Total size of attachments ($total_size) greater than TotalMaxAttachmentSize ($TOT_MAX_ATTACHMENT_SIZE)."

	# generate recipients arguments
	RECIPIENTS="$(echo "$NUMBER" | sed 's/+/ -r +/g' | sed 's/^ //')"

	# make unique attachment argument for text message
	TMPFILE="$(mktemp)"
	printf %s "$TEXT" > "$TMPFILE"
	ATTACHMENTS="$(printf "%s '%s'%s" "-a" "$TMPFILE" "$ATTACHMENTS")"
	info "DEBUG: Launching mmsctl -S $RECIPIENTS $ATTACHMENTS..."
	printf "%s %s %s" "-S" "$RECIPIENTS" "$ATTACHMENTS" | xargs mmsctl
	rm "$TMPFILE"

	# mmsctl doesn't actually fail if can't send
	# wait for message to change from 'draft' to 'sent' then delete *all* sent messages.
	sleep 1s
	NAMED_PIPE="$(mktemp -u)"
	mkfifo "$NAMED_PIPE"
	mmsctl -M > "$NAMED_PIPE" &
	while read -r line; do
		if echo "$line" | grep -q '^"message_path":'; then
			MESSAGE_PATH="$(echo "$line" | cut -d':' -f2 | cut -d'"' -f2)"
		fi
		if echo "$line" | grep -q '^"Status":'; then
			STATUS="$(echo "$line" | cut -d':' -f2 | cut -d'"' -f2)"
			if [ "$STATUS" = "sent" ]; then
				info "DEBUG: Processing sent $MESSAGE_PATH..."
				sxmo_mms.sh processmms "$MESSAGE_PATH" Sent
				SENT_SUCCESS=1
			else
				info "WARNING: found $MESSAGE_PATH with status $STATUS"
				info "Run 'sxmo_mms.sh checkforlostmms' maybe?"
			fi
		fi
	done < "$NAMED_PIPE"

	[ -z "$SENT_SUCCESS" ] && err "Couldn't send text message."

	[ -f "$LOGDIR/$NUMBER/draft.attachments.txt" ] && rm "$LOGDIR/$NUMBER/draft.attachments.txt"

# we are dealing with a normal sms, so use mmcli
else

	MODEM="$(modem_n)"

	TEXTSIZE="${#TEXT}"

	#mmcli doesn't appear to be able to interpret a proper escape
	#mechanism, so we'll substitute double quotes for two single quotes
	SAFE_TEXT=$(echo "$TEXT" | sed "s/\"/''/g")

	SMSNO="$(
		mmcli -m "$MODEM" --messaging-create-sms="text=\"$SAFE_TEXT\",number=$NUMBER" |
		grep -o "[0-9]*$"
	)"
	mmcli -s "${SMSNO}" --send || err "Couldn't send text message"
	for i in $(mmcli -m "$MODEM" --messaging-list-sms | grep " (sent)" | cut -f5 -d' ') ; do
		mmcli -m "$MODEM" --messaging-delete-sms="$i"
	done

	TIME="$(date --iso-8601=seconds)"
	mkdir -p "$LOGDIR/$NUMBER"
	printf %b "Sent SMS to $NUMBER at $TIME:\n$TEXT\n\n" >> "$LOGDIR/$NUMBER/sms.txt"
	printf "%s\tsent_txt\t%s\t%s chars\n" "$TIME" "$NUMBER" "$TEXTSIZE" >> "$LOGDIR/modemlog.tsv"

fi

sxmo_hooks.sh sendsms "$NUMBER" "$TEXT"
info "Sent text to $NUMBER message ok"

