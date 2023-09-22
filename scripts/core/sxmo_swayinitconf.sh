#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# Run from sway.

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

monitor="${SXMO_MONITOR:-"$(swaymsg -t get_outputs | jq -r '.[0] | .name')"}"
pwr="$SXMO_POWER_BUTTON"
vols="$SXMO_VOLUME_BUTTON"

# Drop this when bonsai is available on 32 bits systems
multikey_retrocompat() {
	sxmo_multikey.sh clear

	if [ -n "$pwr" ]; then
		swaymsg -- input "$pwr" repeat_delay 200
		swaymsg -- input "$pwr" repeat_rate 15
		swaymsg -- bindsym --locked --input-device="$pwr" XF86PowerOff exec sxmo_multikey.sh \
			powerbutton \
			powerbutton_one \
			powerbutton_two \
			powerbutton_three
	else
		swaymsg -- bindsym --locked XF86PowerOff exec \
			sxmo_hook_inputhandler.sh powerbutton_one
	fi

	if [ -n "$vols" ]; then
		for vol in $vols; do
			swaymsg -- input "$vol" repeat_delay 200
			swaymsg -- input "$vol" repeat_rate 15

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
	else
		swaymsg -- bindsym --locked XF86AudioRaiseVolume exec \
			sxmo_hook_inputhandler.sh volup_one
		swaymsg -- bindsym --locked XF86AudioLowerVolume exec \
			sxmo_hook_inputhandler.sh voldown_one
	fi
}

if [ -n "$SXMO_MODEM_GPIO_KEY_RI" ]; then
	# Disable the gpio-key-ri input devive
	# It will trigger idle wakeup on modem notification which break sxmo
	swaymsg -- input "$SXMO_MODEM_GPIO_KEY_RI" events disabled
fi

if [ -n "$SXMO_SWAY_SCALE" ]; then
	swaymsg -- output "$monitor" scale "$SXMO_SWAY_SCALE"
fi

focused_name="$(
	swaymsg -t get_outputs | jq -r '.[] | select(.focused == true) | .name'
)"
swaymsg -- input type:touch map_to_output "$focused_name"
swaymsg -- input type:tablet_tool map_to_output "$focused_name"

if [ "$SXMO_DEVICE_NAME" = "desktop" ]; then
	swaymsg -- bindsym --locked XF86PowerOff exec \
		sxmo_hook_inputhandler.sh powerbutton_one
	exit 0
fi

if ! command -v bonsaictl > /dev/null; then
	multikey_retrocompat
	exit
fi

swaymsg -- bindsym --locked --no-repeat XF86PowerOff exec bonsaictl -e power_pressed
swaymsg -- bindsym --locked --release XF86PowerOff exec bonsaictl -e power_released

swaymsg -- bindsym --locked --no-repeat XF86AudioRaiseVolume exec bonsaictl -e volup_pressed
swaymsg -- bindsym --locked --release XF86AudioRaiseVolume exec bonsaictl -e volup_released

swaymsg -- bindsym --locked --no-repeat XF86AudioLowerVolume exec bonsaictl -e voldown_pressed
swaymsg -- bindsym --locked --release XF86AudioLowerVolume exec bonsaictl -e voldown_released
