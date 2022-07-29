#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# Run from sway.

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

monitor="${SXMO_MONITOR:-"DSI-1"}"
pwr="${SXMO_POWER_BUTTON:-"0:0:axp20x-pek"}"
vols="${SXMO_VOLUME_BUTTON:-"1:1:1c21800.lradc"}"
scale="${SXMO_SWAY_SCALE:-2}"

swaymsg -- output "$monitor" scale "$scale"

focused_name="$(
	swaymsg -t get_outputs | jq -r '.[] | select(.focused == true) | .name'
)"
swaymsg -- input type:touch map_to_output "$focused_name"
swaymsg -- input type:tablet_tool map_to_output "$focused_name"

swaymsg -- input "$pwr" xkb_file "$(xdg_data_path sxmo/sway/xkb_mobile_normal_buttons)"

if ! [ "$vols" = "none" ]; then
	for vol in $vols; do
		swaymsg -- input "$vol" repeat_delay 200
		swaymsg -- input "$vol" repeat_rate 15
		swaymsg -- input "$vol" xkb_file "$(xdg_data_path sxmo/sway/xkb_mobile_normal_buttons)"
	done
fi

swaymsg -- bindsym --locked --input-device="$pwr" --no-repeat XF86PowerOff exec bonsaictl -e power_pressed
swaymsg -- bindsym --locked --input-device="$pwr" --release XF86PowerOff exec bonsaictl -e power_released

if ! [ "$vols" = "none" ]; then
	for vol in $vols; do
		swaymsg -- bindsym --locked --input-device="$vol" --no-repeat XF86AudioRaiseVolume exec bonsaictl -e volup_pressed
		swaymsg -- bindsym --locked --input-device="$vol" --release XF86AudioRaiseVolume exec bonsaictl -e volup_released

		swaymsg -- bindsym --locked --input-device="$vol" --no-repeat XF86AudioLowerVolume exec bonsaictl -e voldown_pressed
		swaymsg -- bindsym --locked --input-device="$vol" --release XF86AudioLowerVolume exec bonsaictl -e voldown_released
	done
fi
