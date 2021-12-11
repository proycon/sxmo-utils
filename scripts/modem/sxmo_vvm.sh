#!/bin/sh
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

# usually invoked from sxmo_modemmonitor.sh once a dbus signal is received
processvvm() {
	VVM_DATE="$1" # date of voice mail
	VVM_SENDER="$2" # who the voice mail is from
	VVM_ID="$3" # id assigned to voice mail from vvmd
	VVM_ATTACHMENT="$4" # full path + filename of amr file
	VVM_FILE="$LOGDIR/$VVM_SENDER/attachments/$(basename "$VVM_ATTACHMENT")"
	VVM_SENDER_NAME="$(sxmo_contacts.sh --name "$VVM_SENDER")"
	[ "$VVM_SENDER_NAME" = "???" ] && VVM_SENDER_NAME="$VVM_SENDER"

	mkdir -p "$LOGDIR/$VVM_SENDER/attachments"

	printf "%s\trecv_vvm\t%s\t%s\n" "$VVM_DATE" "$VVM_SENDER" "$VVM_ID" >> "$LOGDIR/modemlog.tsv"

	if [ -f "$VVM_ATTACHMENT" ]; then
		cp "$VVM_ATTACHMENT" "$VVM_FILE"
	else
		printf "ERR: %s vvm attachment (%s) not found!" "$(date)" "$VVM_ATTACHMENT" >&2
		exit 1
	fi

	printf "Received Voice Mail from %s at %s:\n%s %s\n\n" "$VVM_SENDER_NAME" "$VVM_DATE" "$icon_att" "$(basename "$VVM_FILE")" >> "$LOGDIR/$VVM_SENDER/sms.txt"

	sxmo_notificationwrite.sh \
		random \
		"sxmo_open.sh '$VVM_FILE'" \
		"$LOGDIR/$VVM_SENDER/sms.txt" \
		"VM: $VVM_SENDER_NAME ($VVM_ID)"

	sxmo_hooks.sh vvm "$VVM_SENDER" "$VVM_ID"

	# VVM_AUTO_DELETE and VVM_AUTO_MARKREAD are defined in sxmo_common.sh based on
	# SXMO_VVM_AUTO_DELETE and SXMO_VVM_AUTO_MARKREAD variables that users can set
	# in profile.
	# Default is DELETE=1 and MARKREAD=0
	if [ "$VVM_AUTO_DELETE" -eq 1 ]; then
		dbus-send --dest=org.kop316.vvm --print-reply /org/kop316/vvm/modemmanager/"$VVM_ID" org.kop316.vvm.Message.Delete
	fi
	if [ "$VVM_AUTO_MARKREAD" -eq 1 ]; then
		dbus-send --dest=org.kop316.vvm --print-reply /org/kop316/vvm/modemmanager/"$VVM_ID" org.kop316.vvm.Message.MarkRead
	fi
}

"$@"
