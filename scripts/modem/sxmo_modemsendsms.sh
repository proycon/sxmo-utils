#!/usr/bin/env sh
LOGDIR="$XDG_CONFIG_HOME"/sxmo/modem

info() {
	echo "$1" > /dev/stderr
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

if [ "-" = "$2" ]; then
	TEXT="$(cat)"
else
	shift
	[ 0 -eq $# ] && usage

	TEXT="$*"
fi
TEXTSIZE="${#TEXT}"

SMSNO="$(
	mmcli -m "$MODEM" --messaging-create-sms="text='$TEXT',number=$NUMBER" |
	grep -o "[0-9]*$"
)"
mmcli -s "${SMSNO}" --send || err "Couldn't send text message"
for i in $(mmcli -m "$MODEM" --messaging-list-sms | grep " (sent)" | cut -f5 -d' ') ; do
  mmcli -m "$MODEM" --messaging-delete-sms="$i"
done

TIME="$(date --iso-8601=seconds)"
mkdir -p "$LOGDIR/$NUMBER"
printf %b "Sent to $NUMBER at $TIME:\n$TEXT\n\n" >> "$LOGDIR/$NUMBER/sms.txt"
printf %b "$TIME\tsent_txt\t$NUMBER\t$TEXTSIZE chars\n" >> "$LOGDIR/modemlog.tsv"

info "Sent text message ok"