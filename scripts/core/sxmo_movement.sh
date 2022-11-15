#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

anglevel_x_raw_bus="$(find /sys/ -name 'in_anglvel_x_raw')"
anglx() {
	cat "$anglevel_x_raw_bus"
}

waitmovement() {
	initialpos="$(anglx)"
	while true; do
		pos="$(anglx)"
		movement="$(echo "$initialpos" - "$pos" | bc)"
		[ 0 -gt "$movement" ] && movement="$(echo "$movement * -1" | bc)"
		[ 10 -lt "$movement" ] && return
		sleep 0.5
	done
}

"$@"
