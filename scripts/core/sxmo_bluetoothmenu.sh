#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

ispaired() {
	bluetoothctl info "$1" | grep Paired | grep -q yes
}

isconnected() {
	bluetoothctl info "$1" | grep Connected | grep -q yes
}

connect() {
	if isconnected "$1"; then
		notify-send "Already connected !"
		return
	fi
	bluetoothctl discoverable on
	if ! ispaired "$1"; then
		notify-send "Pairing..."
		bluetoothctl pairable on
		if bluetoothctl --agent=KeyboardDisplay pair "$1"; then
			notify-send "Paired !"
			bluetoothctl trust "$1" || notify-send "Trusting failed"
		else
			notify-send "Pairing failed"
		fi
		bluetoothctl pairable off
	fi
	if ispaired "$1"; then
		notify-send "Connecting..."
		if bluetoothctl --agent=KeyboardDisplay connect "$1"; then
			notify-send "Connected !"
		else
			notify-send "Connecting failed"
		fi
	fi
	bluetoothctl discoverable off
}

devicemenu() {
	if bluetoothctl show | grep Powered | grep -q no; then
		bluetoothctl power on
	fi
	while true; do
		DEVICES="$(bluetoothctl devices | awk '{ $1=""; printf $2; $2=""; printf "  ^" $0 "\n" }')"
		ENTRIES="$(echo "$DEVICES" | sed 's|.*  ^  ||' | xargs -0 printf "Refresh\nClose Menu\nDisconnect\nScan\n%s")"

		PICKED="$(
			echo "$ENTRIES" |
			dmenu -i -c -l 10 -p "Devices"
		)"

		if echo "$PICKED" | grep -q "Refresh"; then
			continue
		elif echo "$PICKED" | grep -q "Close Menu"; then
			exit
		elif echo "$PICKED" | grep -q "Disconnect"; then
			st -e sh -c "bluetoothctl disconnect; sleep 1"
		elif echo "$PICKED" | grep -q "Scan"; then
			notify-send "Scanning BT devices for 30 seconds..."
			bluetoothctl --timeout=30 scan on && notify-send "End of scan" &
		else
			devicemac="$(echo "$DEVICES" | grep "  \^  $PICKED$" | sed 's|  ^  .*||'  )"
			st -e sh -c "$0 connect $devicemac; sleep 1"
		fi
	done
}

if [ -n "$1" ]; then
	"$@"
else
	devicemenu
fi
