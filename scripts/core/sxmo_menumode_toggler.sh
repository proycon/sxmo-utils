#!/bin/sh

inputs="
	1:1:1c21800.lradc
	0:0:axp20x-pek

	1:1:gpio-key-power
	1:1:adc-keys

	0:0:pm8941_pwrkey
	1:1:GPIO_Buttons
	0:0:pm8941_resin
"

setup_xkb() {
	for input in $inputs; do
		swaymsg input "$input" xkb_file "$1"
	done
}

swaymsg -t subscribe -m "['mode']" | while read -r message; do
	if printf %s "$message" | grep -q menu; then
		setup_xkb /usr/share/sxmo/sway/xkb_mobile_movement_buttons
	else
		setup_xkb /usr/share/sxmo/sway/xkb_mobile_normal_buttons
	fi
done
