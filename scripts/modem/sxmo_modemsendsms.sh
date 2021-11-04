#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

info() {
	echo "$1" >> /dev/stderr
}

err() {
	info "$1"
	exit 1
}

usage() {
	err "Usage: $(basename "$0") number [-|message]"
}

modem_n() {
	MODEMS="$(mmcli -L)"
	echo "$MODEMS" | grep -qoE 'Modem\/([0-9]+)' || err "Couldn't find modem - is your modem enabled?"
	echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
}

MODEM="$(modem_n)"
[ 0 -eq $# ] && usage
NUMBER="$1"

if ! echo "$NUMBER" | grep -q '+'; then
	CONTACT=$(sxmo_contacts.sh --all | grep "^$NUMBER:" |
		cut -d':' -f2 |
		sed 's/^[ \t]*//;s/[ \t]*$//'
	)
	if [ -z "$CONTACT" ]; then
		info "$NUMBER does not look like a number, but it isn't a contact either.  Continuing anyway."
	else
		NUMBER="$CONTACT"
	fi
fi

if [ "-" = "$2" ]; then
	TEXT="$(cat)"
else
	shift
	[ 0 -eq $# ] && usage

	TEXT="$*"
fi
TEXTSIZE="${#TEXT}"

#mmcli doesn't appear to be able to interpret a proper escape
#mechanism, so we'll substitute double quotes for two single quotes
SAFE_TEXT=$(echo "$TEXT" | sed "s/\"/''/g")

# if Group Chat (multiple numbers) or attachments, then send via mmsctl.
if [ "$(printf %s "$NUMBER" | xargs pn find | wc -l)" -gt 1 ] || [ -f "$LOGDIR/$NUMBER/draft.attachments.txt" ]; then
	RECIPIENTS="$(echo "$NUMBER" | sed 's/+/ -r +/g' | sed 's/^ //')"
	TMPFILE="$(mktemp)"
	echo "$SAFE_TEXT" > "$TMPFILE"
	ATTACHMENTS="-a $TMPFILE"
	count=0
	total_size=0
	if [ -f "$LOGDIR/$NUMBER/draft.attachments.txt" ]; then
		info "Attachments:"
		# shellcheck disable=SC2141
		IFS='\n'
		while read -r line; do
			[ -f "$line" ] || err "File not found!"
			CTYPE=$(file -b --mime-type "$line")
			# TODO: I have only tested jpeg and mp3
			# Why do I have to rewrite the mime-type for mp3 but not jpeg?
			case "$CTYPE" in
				"audio/mpegapplication/octet-stream")
					CTYPE="audio/mpeg"
					;;
			esac
			ATTACHMENTS="$ATTACHMENTS -a '$line' -c '$CTYPE'"
			count="$((count+1))"
			total_size="$((total_size+$(wc -c < "$line")))"
			info "$CTYPE: $line"
		done < "$LOGDIR/$NUMBER/draft.attachments.txt"
	fi

	MAX_ATTACHMENTS="$(grep "^TotalMaxAttachmentSize" "$MMS_RECEIVED_DIR/mms" | cut -d'=' -f2)"
	TOT_MAX_ATTACHMENT_SIZE="$(grep "^MaxAttachments" "$MMS_RECEIVED_DIR/mms" | cut -d'=' -f 2)"
	[ -z $MAX_ATTACHMENTS ] && MAX_ATTACHMENTS="25"
	[ -z $TOT_MAX_ATTACHMENT_SIZE ] && TOT_MAX_ATTACHMENT_SIZE="1100000"

	if [ "$count" -gt "$MAX_ATTACHMENTS" ]; then
		err "Too many attachments!"
	fi

	if [ "$count" -ge 1 ] && [ "$total_size" -gt "$TOT_MAX_ATTACHMENT_SIZE" ]; then
		err "Total size of attachments too big!"
	fi

	if [ -z "$RECIPIENTS" ]; then
		err "No recipients provided."
	fi
	info "Launching mmsctl -S $RECIPIENTS $ATTACHMENTS..."
	# TODO: I forget why I need the sh -c, but I do in order to have files with spaces in them processed correctly...
	sh -c "mmsctl -S $RECIPIENTS $ATTACHMENTS" || err "mmsctl error..."
	#mmsctl -S "$RECIPIENTS" "$ATTACHMENTS" || err "mmsctl error..."

	rm "$TMPFILE"
	[ -f "$LOGDIR/$NUMBER/draft.attachments.txt" ] && rm "$LOGDIR/$NUMBER/draft.attachments.txt"

	# Note that sxmo_modemmonitor.sh dbus-monitor subprocess should now detect 'draft' and process the sent mms accordingly
	sxmo_hooks.sh sendsms "$NUMBER" "$TEXT"
	info "Sent MMS to $NUMBER message ok"
else
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
	sxmo_hooks.sh sendsms "$NUMBER" "$TEXT"
	info "Sent SMS to $NUMBER message ok"
fi
