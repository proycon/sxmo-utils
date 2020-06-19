#!/usr/bin/env sh
LOGDIR="$XDG_CONFIG_HOME"/sxmo/modem
trap "gracefulexit" INT TERM

fatalerr() {
	# E.g. hangup all calls, switch back to default audio, notify user, and die
	mmcli -m "$(mmcli -L | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2)" --voice-hangup-all
	notify-send "$1"
	(sleep 0.5; echo 1 > /tmp/sxmo_bar) &
	kill -9 0
}

modem_n() {
	MODEMS="$(mmcli -L)"
	echo "$MODEMS" | grep -qoE 'Modem\/([0-9]+)' || fatalerr "Couldn't find modem - is your modem enabled?"
	echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
}

dialmenu() {
	CONTACTS="$(sxmo_contacts.sh)"
	NUMBER="$(
		printf %b "Close Menu\n$CONTACTS" | 
		grep . |
		sxmo_dmenu_with_kb.sh -l 10 -p Number -c -fn Terminus-20
	)"
	echo "$NUMBER" | grep "Close Menu" && kill 0

	NUMBER="$(
		echo "$NUMBER" | 
		awk -F' ' '{print $NF}' |
		tr -d - |
		cut -f2
	)"
	echo "$NUMBER" | grep -qE '^[+0-9]+$' || fatalerr "$NUMBER is not a number"

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
sxmo_modemcall.sh pickup "$CREATEDCALLID"
