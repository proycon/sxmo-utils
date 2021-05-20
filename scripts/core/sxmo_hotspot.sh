#!/usr/bin/env sh

while [ -z "$SSID" ]; do
	SSID="$(
		echo "$ENTRIES" | sxmo_dmenu_with_kb.sh -c -p "SSID"
	)"
done

while [ -z "$key" ]; do
	key="$(
		echo "$ENTRIES" | sxmo_dmenu_with_kb.sh -c -p "pass"
	)"
done

while [ -z "$key1" ]; do
	key1="$(
		echo "$ENTRIES" | sxmo_dmenu_with_kb.sh -c -p "confirm"
	)"
done

if [ "$key" != "$key1" ]; then
	notify-send key mismatch
	exit 2
fi

while [ -z "$channel" ]; do
	channel="$(
		echo "11" | sxmo_dmenu_with_kb.sh -l 1 -c -p "channels"
	)"
done

if [ -z "$SSID" ] || [ -z "$key" ]; then
	notify-send either SSID: "$SSID" or key are empty
	exit 3
fi

notify-send "$(nmcli device wifi hotspot ifname wlan0 con-name "Hotspot $SSID" ssid "$SSID" channel "$channel" band bg password "$key")"
