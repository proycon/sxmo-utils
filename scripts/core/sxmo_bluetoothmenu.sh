#!/usr/bin/env sh

devicemenu() {
	while true; do
		DEVICES="$(bluetoothctl devices | awk '{ $1=""; printf $2; $2=""; printf "  ^" $0 "\n" }')"
		ENTRIES="$(echo "$DEVICES" | sed 's|.*  ^  ||' | xargs -0 printf "Close Menu\nDisconnect\n%s")"

		PICKED="$(
			echo "$ENTRIES" |
			sxmo_dmenu_with_kb.sh -i -c -l 10 -p "Devices"
		)"

		if echo "$PICKED" | grep -q "Close Menu"; then
			exit
		elif echo "$PICKED" | grep -q "Disconnect"; then
			st -e sh -c "bluetoothctl disconnect; sleep 1"
			continue
		else
			devicemac="$(echo "$DEVICES" | grep "  \^  $PICKED$" | sed 's|  ^  .*||'  )"
			st -e sh -c "bluetoothctl connect $devicemac; sleep 1"
		fi
	done
}

devicemenu
