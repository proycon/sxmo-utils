#!/bin/sh

udev_tmp="$(mktemp)"
udevadm monitor -u -s power_supply >> "$udev_tmp" &
UDEVPID=$!
tail -f "$udev_tmp" | while read -r; do
	sxmo_hooks.sh statusbar battery
done &
STATUSBATTERYPID=$!

finish() {
	kill "$STATUSBATTERYPID"
	kill "$UDEVPID"
	rm "$udev_tmp"
}
trap 'finish' TERM INT EXIT

wait "$STATUSTIMEPID"
wait "$STATUSBATTERYPID"
