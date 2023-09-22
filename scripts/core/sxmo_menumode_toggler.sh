#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

inputs="$SXMO_POWER_BUTTON $SXMO_VOLUME_BUTTON"

setup_xkb() {
	for input in $inputs; do
		swaymsg input "$input" xkb_file "$1"
	done
}

swaymsg -t subscribe -m "['mode']" | while read -r message; do
	if printf %s "$message" | grep -q menu; then
		setup_xkb "$(xdg_data_path sxmo/xkb/xkb_mobile_movement_buttons)"
	else
		setup_xkb "$(xdg_data_path sxmo/xkb/xkb_mobile_normal_buttons)"
	fi
done
