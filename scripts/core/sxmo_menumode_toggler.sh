#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

inputs="
	${SXMO_POWER_BUTTON:-"0:0:axp20x-pek"}
	${SXMO_VOLUME_BUTTON:-"1:1:1c21800.lradc"}
"

setup_xkb() {
	for input in $inputs; do
		swaymsg input "$input" xkb_file "$1"
	done
}

swaymsg -t subscribe -m "['mode']" | while read -r message; do
	if printf %s "$message" | grep -q menu; then
		setup_xkb /usr/share/sxmo/xkb/xkb_mobile_movement_buttons
	else
		setup_xkb /usr/share/sxmo/xkb/xkb_mobile_normal_buttons
	fi
done
