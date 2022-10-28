#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

CALLID="$1"
ESCAPE="$(printf '\e')"

# Found on stackoverflow
# https://stackoverflow.com/questions/8725925/how-to-read-just-a-single-character-in-shell-script
read_char() {
	stty -icanon -echo
	dd bs=1 count=1 2>/dev/null
	stty icanon echo
}

finish() {
	sxmo_keyboard.sh close
	exit 0
}

sxmo_keyboard.sh close
KEYBOARD_ARGS="-l dialer" sxmo_keyboard.sh open 2>/dev/null
trap 'finish' INT TERM EXIT

printf "DTMF tone: "
while : ; do
	tone="$(read_char)"

	case "$tone" in
		"$ESCAPE")
			break
			;;
		[0-9a-dA-D*#])
			printf '%s' "$tone"
			mmcli -m any -o "$CALLID" --send-dtmf="$tone" >/dev/null &
			;;
		*)
			printf "\nerror: invalid dtmf tone: %s\nDTMF tone: " "$tone" >&2
			;;
	esac
done
