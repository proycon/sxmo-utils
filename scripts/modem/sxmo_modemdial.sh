#!/usr/bin/env sh
trap "gracefulexit" INT TERM

fatalerr() {
	# E.g. hangup all calls, switch back to default audio, notify user, and die
	mmcli -m "$(mmcli -L | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2)" --voice-hangup-all
	echo "$1" >&2
	notify-send "$1"
	(sleep 0.5; sxmo_statusbarupdate.sh) &
	kill -9 0
}

modem_n() {
	MODEMS="$(mmcli -L)"
	echo "$MODEMS" | grep -qoE 'Modem\/([0-9]+)' || fatalerr "Couldn't find modem - is your modem enabled?"
	echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
}

dialmenu() {
	CONTACTS="$(sxmo_contacts.sh | grep -E "^\+?[0-9]+:")"
	NUMBER="$(
		printf %b "Close Menu\nMore contacts\n$CONTACTS" |
		grep . |
		sxmo_dmenu_with_kb.sh -l 10 -p Number -c -fn Terminus-20 -i
	)"
	echo "$NUMBER" | grep "Close Menu" && kill -9 0

	echo "$NUMBER" | grep -q "More contacts" && NUMBER="$(
		printf %b "Close Menu\n$(sxmo_contacts.sh --all)" |
		grep . |
		sxmo_dmenu_with_kb.sh -l 10 -p Number -c -fn Terminus-20 -i
	)"
	NUMBER="$(echo "$NUMBER" | cut -d: -f1 | tr -d -- '- ')"
	if [ -z "$NUMBER" ] || [ "$NUMBER" = "CloseMenu" ]; then
		#no number selected (probably cancelled), silently discard
		exit 0
	else
		echo "$NUMBER" | grep -qE '^[+0-9]+$' || fatalerr "$NUMBER is not a number"
	fi

	echo "Attempting to dial: $NUMBER" >&2
	CALLID="$(
		mmcli -m "$(modem_n)" --voice-create-call "number=$NUMBER" |
		grep -Eo "Call/[0-9]+" |
		grep -oE "[0-9]+"
	)"
	echo "Starting call with CALLID: $CALLID" >&2
	echo "$CALLID"
}

modem_n || fatalerr "Couldn't determine modem number - is modem online?"
CREATEDCALLID="$(dialmenu)"
if [ -n "$CREATEDCALLID" ]; then
	sxmo_modemcall.sh pickup "$CREATEDCALLID"
fi
