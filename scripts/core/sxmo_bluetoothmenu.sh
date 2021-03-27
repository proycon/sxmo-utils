#!/usr/bin/env sh

connect() {
	if bluetoothctl info "$1" | grep Connected | grep -q no; then
		bluetoothctl discoverable on
		if bluetoothctl info "$1" | grep Paired | grep -q no; then
			bluetoothctl pairable on
			notify-send "Pairing with $1..."
			bluetoothctl --timeout=10 pair "$1" || notify-send "Pairing failed" && return
			bluetoothctl trust "$1" || notify-send "Trusting failed" && return
		fi
		bluetoothctl --timeout=5 connect "$1" || notify-send "Connecting failed" && return
	fi
}

devicemenu() {
	if bluetoothctl show | grep Powered | grep -q no; then
		bluetoothctl power on
	fi
	while true; do
		DEVICES="$(bluetoothctl devices | awk '{ $1=""; printf $2; $2=""; printf "  ^" $0 "\n" }')"
		ENTRIES="$(echo "$DEVICES" | sed 's|.*  ^  ||' | xargs -0 printf "Close Menu\nDisconnect\nScan\n%s")"

		PICKED="$(
			echo "$ENTRIES" |
			sxmo_dmenu_with_kb.sh -i -c -l 10 -p "Devices"
		)"

		if echo "$PICKED" | grep -q "Close Menu"; then
			exit
		elif echo "$PICKED" | grep -q "Disconnect"; then
			st -e sh -c "bluetoothctl disconnect; sleep 1"
		elif echo "$PICKED" | grep -q "Scan"; then
			notify-send "Scanning BT devices for 5 seconds..."
			bluetoothctl --timeout=5 scan on
		else
			devicemac="$(echo "$DEVICES" | grep "  \^  $PICKED$" | sed 's|  ^  .*||'  )"
			st -e sh -c "$0 connect $devicemac"
			bluetoothctl pairable off
			bluetoothctl discoverable off
		fi
	done
}

if [ -n "$1" ]; then
	"$@"
else
	devicemenu
fi
