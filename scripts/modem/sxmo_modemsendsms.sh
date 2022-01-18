#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(which sxmo_common.sh)"

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
if [ "$(printf %s "$NUMBER" | xargs pn find | wc -l)" -gt 1 ] || [ -f "$SXMO_LOGDIR/$NUMBER/draft.attachments.txt" ]; then

	MMS_BASE_DIR="${SXMO_MMS_BASE_DIR:-"$HOME"/.mms/modemmanager}"
	[ -d "$MMS_BASE_DIR" ] || err "MMS not configured."

	# generate mmsctl args for attachments found in draft.attachments.txt (one per line)
	count=0
	total_size=0
	ATTACHMENTS=
	if [ -f "$SXMO_LOGDIR/$NUMBER/draft.attachments.txt" ]; then
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
		done < "$SXMO_LOGDIR/$NUMBER/draft.attachments.txt"
	fi

	# basic mms error checking (since mmsctl does not do it)
	TOT_MAX_ATTACHMENT_SIZE="$(grep "^TotalMaxAttachmentSize" "$MMS_BASE_DIR/mms" | cut -d'=' -f2)"
	MAX_ATTACHMENTS="$(grep "^MaxAttachments" "$MMS_BASE_DIR/mms" | cut -d'=' -f 2)"
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

	# First, send it via mmsctl.  mmsctl does the equivalent of:
	# dbus-send --dest=org.ofono.mms --print-reply /org/ofono/mms/modemmanager \
	# org.ofono.mms.Service.SendMessage string:"+1234560000" variant:smil \
	# string:"cid-1,text/plain,foobar.txt"
	info "DEBUG: Launching mmsctl -S $RECIPIENTS $ATTACHMENTS"
	MMSCTL_RES="$(printf "%s %s %s" "-S" "$RECIPIENTS" "$ATTACHMENTS" | xargs mmsctl 2>&1)"
	MMSCTL_OK="$?"
	rm "$TMPFILE"
	# Possible results:
	#
	# syntax error) "mmsctl: unrecognized option:"
	#
	# mmsdtng not running) "DBus error: The name org.ofono.mms was not
	# provided by any .service files"
	#
	# not sure) "DBus error: Did not receive a reply.  Possible causes
	# include: the remote application did not send a reply, the message bus
	# security policy blocked the reply, the reply timeout expered, or the
	# network connection was broken."
        #
	# Note that mmsctl will (wrongly) return success with bad filename,
	# attachment size too big, and max attachments too large.  Hence, I check 
	# for those above.  
	#
	# Note also that mmsctl will send a success only if it reaches mmsdtng, and
	# so it will not tell us if the message was actually sent.
	if [ "$MMSCTL_OK" -ne 0 ]; then
		if echo "$MMSCTL_RES" | grep -q "unrecognized option"; then
			err "mmsctl syntax error!"
		elif echo "$MMSCTL_RES" | grep -q "was not provied"; then
			err "mmsdtng down ($MMSCTL_RES)!"
		else
			info "DEBUG: Unknown mmsctl error: $MMSCTL_RES"
			# Note that *sometimes* mmsctl will still create a draft in this case.
			# Hence, we continue to cleanup draft and do not exit here..
		fi
	else
		info "DEBUG: mmsctl returned success.  Checking for sent status..."
	fi

	# Second, check to see if it actually sent. mmsdtng creates a 
	# new message with the status 'draft' and once it *actually*
	# sends it it changes the status to 'sent'.  Hence, here we 
	# sit on PropertyChanged and detect if status changes to sent.
	NAMED_PIPE="$(mktemp -u)"
	mkfifo "$NAMED_PIPE"
	# 60 second timeout because on dns errors, mmsdtng takes this long sometimes
	timeout 60 dbus-monitor "interface='org.ofono.mms.Message',type='signal',member='PropertyChanged'" > "$NAMED_PIPE" &
	while read -r line; do
		if echo "$line" | grep -q 'member=PropertyChanged'; then
			MESSAGE_PATH="$(echo "$line" | cut -d'=' -f6 | cut -d';' -f1)"
		fi
		if echo "$line" | grep -q "string \"sent\""; then
			SENT_SUCCESS=1
			break
		fi
	done < "$NAMED_PIPE"
	rm -f "$NAMED_PIPE"

	# we failed to send!
	if [ -z "$SENT_SUCCESS" ]; then
		# Delete all drafts.
		sxmo_mms.sh deletedrafts
		err "Couldn't send text message.  Check mmsd log for errors."
	fi

	# we sent!  process it and cleanup
	sxmo_mms.sh processmms "$MESSAGE_PATH" "Sent"
	[ -f "$SXMO_LOGDIR/$NUMBER/draft.attachments.txt" ] && rm "$SXMO_LOGDIR/$NUMBER/draft.attachments.txt"

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

	TIME="$(date +%FT%H:%M:%S%z)"
	mkdir -p "$SXMO_LOGDIR/$NUMBER"
	printf %b "Sent SMS to $NUMBER at $TIME:\n$TEXT\n\n" >> "$SXMO_LOGDIR/$NUMBER/sms.txt"
	printf "%s\tsent_txt\t%s\t%s chars\n" "$TIME" "$NUMBER" "$TEXTSIZE" >> "$SXMO_LOGDIR/modemlog.tsv"

fi

sxmo_hooks.sh sendsms "$NUMBER" "$TEXT"
info "Sent text to $NUMBER message ok"

