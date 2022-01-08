#!/bin/sh
# Main vvm (Visual Voice Mail) code.  Functions here are called from sxmo_modemmonitor.sh

# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

stderr() {
	printf "%s sxmo_vvm: %s.\n" "$(date)" "$*" >&2
}

checkvvmd() {
	if [ -f "$VVM_BASE_DIR/vvm" ]; then
		pgrep vvmd > /dev/null && return
		pgrep -f sxmo_vvmdconfig && return
		stderr "vvmd not found, attempting to start it: $DBUS_SESSION_BUS_ADDRESS."
		setsid -f vvmd
	fi
}

# usually invoked from sxmo_modemmonitor.sh once a dbus signal is received
processvvm() {
	VVM_DATE="$(date +%FT%H:%M:%S%z -d "$1")" # date of voice mail
	VVM_SENDER="$2" # number the voice mail is from
	VVM_ID="$3" # unique id assigned to voice mail from vvmd
	VVM_ATTACHMENT="$4" # full path + filename of amr file
	VVM_FILE="$LOGDIR/$VVM_SENDER/attachments/$(basename "$VVM_ATTACHMENT")"
	VVM_SENDER_NAME="$(sxmo_contacts.sh --name "$VVM_SENDER")"
	[ "$VVM_SENDER_NAME" = "???" ] && VVM_SENDER_NAME="$VVM_SENDER"

	mkdir -p "$LOGDIR/$VVM_SENDER/attachments"

	printf "%s\trecv_vvm\t%s\t%s\n" "$VVM_DATE" "$VVM_SENDER" "$VVM_ID" >> "$LOGDIR/modemlog.tsv"

	if [ -f "$VVM_ATTACHMENT" ]; then
		cp "$VVM_ATTACHMENT" "$VVM_FILE"
	else
		stderr "ERR: vvm attachment ($VVM_ATTACHMENT) not found!"
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
