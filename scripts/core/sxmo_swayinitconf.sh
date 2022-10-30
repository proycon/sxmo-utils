#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# Run from sway.

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

monitor="${SXMO_MONITOR:-"$(swaymsg -t get_outputs | jq -r '.[0] | .name')"}"
pwr="${SXMO_POWER_BUTTON:-"0:0:axp20x-pek"}"
vols="${SXMO_VOLUME_BUTTON:-"1:1:1c21800.lradc"}"
scale="${SXMO_SWAY_SCALE:-2}"

# Drop this when bonsai is available on 32 bits systems
multikey_retrocompat() {
	sxmo_multikey.sh clear

	swaymsg -- input "$pwr" repeat_delay 200
	swaymsg -- input "$pwr" repeat_rate 15

	swaymsg -- bindsym --locked --input-device="$pwr" XF86PowerOff exec sxmo_multikey.sh \
		powerbutton \
		powerbutton_one \
		powerbutton_two \
		powerbutton_three

	 if ! [ "$vols" = "none" ]; then
		for vol in $vols; do
			swaymsg -- bindsym --locked --input-device="$vol" XF86AudioRaiseVolume exec \
				sxmo_multikey.sh \
				volup \
				volup_one \
				volup_two \
				volup_three

			swaymsg -- bindsym --locked --input-device="$vol" XF86AudioLowerVolume exec \
				sxmo_multikey.sh \
				voldown \
				voldown_one \
				voldown_two \
				voldown_three
		done
	 fi
}

if [ -n "$SXMO_MODEM_GPIO_KEY_RI" ]; then
	# Disable the gpio-key-ri input devive
	# It will trigger idle wakeup on modem notification which break sxmo
	swaymsg -- input "$SXMO_MODEM_GPIO_KEY_RI" events disabled
fi

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

if ! command -v bonsaictl > /dev/null; then
	multikey_retrocompat
	exit
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
