#!/bin/sh

# Run from sway.

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(which sxmo_common.sh)"

monitor="${SXMO_MONITOR:-"DSI-1"}"
pwr="${SXMO_POWER_BUTTON:-"0:0:axp20x-pek"}"
vol="${SXMO_VOLUME_BUTTON:-"1:1:1c21800.lradc"}"

swaymsg -- output "$monitor" scale 2

swaymsg -- input "$pwr" repeat_delay 200
swaymsg -- input "$pwr" repeat_rate 15
swaymsg -- input "$pwr" xkb_file /usr/share/sxmo/sway/xkb_mobile_normal_buttons

if ! [ "$vol" = "none" ]; then
	swaymsg -- input "$vol" repeat_delay 200
	swaymsg -- input "$vol" repeat_rate 15
	swaymsg -- input "$vol" xkb_file /usr/share/sxmo/sway/xkb_mobile_normal_buttons
fi

sxmo_multikey.sh clear

swaymsg -- bindsym --input-device="$pwr" XF86PowerOff exec sxmo_multikey.sh \
	powerbutton \
	powerbutton_one \
	powerbutton_two \
	powerbutton_three

if ! [ "$vol" = "none" ]; then
	swaymsg -- bindsym --input-device="$vol" XF86AudioRaiseVolume exec \
		sxmo_multikey.sh \
		volup \
		volup_one \
		volup_two \
		volup_three

	swaymsg -- bindsym --input-device="$vol" XF86AudioLowerVolume exec \
		sxmo_multikey.sh \
		voldown \
		voldown_one \
		voldown_two \
		voldown_three
fi
