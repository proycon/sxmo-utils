#!/usr/bin/env sh

err() {
	printf %b "$1" | dmenu
	exit
}

modem_n() {
	MODEMS="$(mmcli -L)"
	echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' > /dev/null || err "Couldn't find modem - is your modem enabled?"
	echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
}

sxmo_terminal.sh sh -c "mmcli -m $(modem_n) && read"
