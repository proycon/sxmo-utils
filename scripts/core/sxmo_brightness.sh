#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh
# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh

notify() {
	if [ "$SXMO_WM" = "sway" ] && [ -z "$SXMO_WOB_DISABLE" ]; then
		getvalue > "$XDG_RUNTIME_DIR"/sxmo.wobsock
	else
		getvalue | xargs dunstify -r 888 "$icon_brightness Brightness"
	fi
}

setvalue() {
	brightnessctl set "$1"%
}

up() {
	brightnessctl set 5%+
}

down() {
	# bugged https://github.com/Hummer12007/brightnessctl/issues/82
	# brightnessctl --min-value "${SXMO_MIN_BRIGHTNESS:-5}" set 5%-

	if [ "$(getvalue)" -gt "${SXMO_MIN_BRIGHTNESS:-5}" ]; then
		brightnessctl set 5%-
	else
		brightnessctl set "${SXMO_MIN_BRIGHTNESS:-5}"%
	fi
}

getvalue() {
	# need brightnessctl release after 0.5.1 to have --percentage
	brightnessctl info \
		| grep "Current brightness:" \
		| awk '{ print $NF }' \
		| grep -o "[0-9]*"
}

"$@"
notify
