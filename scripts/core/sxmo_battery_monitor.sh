#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

udev_tmp="$(mktemp)"
udevadm monitor -u -s power_supply >> "$udev_tmp" &
UDEVPID=$!
# shellcheck disable=SC2034
tail -f "$udev_tmp" | while read -r _; do
	sxmo_hook_statusbar.sh battery
done &
STATUSBATTERYPID=$!

finish() {
	kill "$STATUSBATTERYPID"
	kill "$UDEVPID"
	rm "$udev_tmp"
}
trap 'finish' TERM INT EXIT

wait "$UDEVPID"
wait "$STATUSBATTERYPID"
