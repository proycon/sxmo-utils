#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This hook is called when a notification (sxmo_notificationmonitor.sh)
# is added or removed.
# $1 is the number of notifications on the system (0 if none).

if [ "$1" -eq 0 ]; then
	sxmo_led.sh set green 0
else
	sxmo_led.sh set green 100
fi
sxmo_hook_statusbar.sh notifications
