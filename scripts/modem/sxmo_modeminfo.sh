#!/usr/bin/env sh

err() {
	printf %b "$1" | dmenu -fn Terminus-20 -c -l 10
	exit
}

modem_n() {
	MODEMS="$(mmcli -L)"
	echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' > /dev/null || err "Couldn't find modem - is your modem enabled?"
	echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
}

st -e sh -c "mmcli -m $(modem_n) && read"
