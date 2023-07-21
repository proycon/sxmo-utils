#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors
# Main vvm (Visual Voice Mail) code.  Functions here are called from sxmo_modemmonitor.sh

# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

stderr() {
	sxmo_log "$*"
}

# usually invoked from sxmo_modemmonitor.sh once a dbus signal is received
processvvm() {
	VVM_DATE="$(date +%FT%H:%M:%S%z -d "$1")" # date of voice mail
	VVM_SENDER="$2" # number the voice mail is from
	VVM_ID="$3" # unique id assigned to voice mail from vvmd
	VVM_ATTACHMENT="$4" # full path + filename of amr file
	VVM_FILE="$SXMO_LOGDIR/$VVM_SENDER/attachments/$(basename "$VVM_ATTACHMENT")"
	VVM_SENDER_NAME="$(sxmo_contacts.sh --name-or-number "$VVM_SENDER")"

	mkdir -p "$SXMO_LOGDIR/$VVM_SENDER/attachments"

	printf "%s\trecv_vvm\t%s\t%s\n" "$VVM_DATE" "$VVM_SENDER" "$VVM_ID" >> "$SXMO_LOGDIR/modemlog.tsv"

	if [ -f "$VVM_ATTACHMENT" ]; then
		cp "$VVM_ATTACHMENT" "$VVM_FILE"
	else
		stderr "ERR: vvm attachment ($VVM_ATTACHMENT) not found!"
		exit 1
	fi

	sxmo_hook_smslog.sh "recv" "$VVM_SENDER" "$VVM_SENDER" "$VVM_DATE" \
		"$icon_phn $(basename "$VVM_FILE")" >> "$SXMO_LOGDIR/$VVM_SENDER/sms.txt"

	if [ -z "$SXMO_DISABLE_SMS_NOTIFS" ]; then
		sxmo_notificationwrite.sh \
			random \
			"sxmo_open.sh '$VVM_FILE'" \
			"$SXMO_LOGDIR/$VVM_SENDER/sms.txt" \
			"VM: $VVM_SENDER_NAME ($VVM_ID)"
	fi

	if grep -q screenoff "$SXMO_STATE"; then
		sxmo_hook_lock.sh
	fi

	sxmo_hook_sms.sh "$VVM_SENDER" "VVM" "$VVM_ID"

	if [ "${SXMO_VVM_AUTO_DELETE:-1}" -eq 1 ]; then
		dbus-send --dest=org.kop316.vvm --print-reply /org/kop316/vvm/modemmanager/"$VVM_ID" org.kop316.vvm.Message.Delete
	fi
	if [ "${SXMO_VVM_AUTO_MARKREAD:-0}" -eq 1 ]; then
		dbus-send --dest=org.kop316.vvm --print-reply /org/kop316/vvm/modemmanager/"$VVM_ID" org.kop316.vvm.Message.MarkRead
	fi
}

"$@"
