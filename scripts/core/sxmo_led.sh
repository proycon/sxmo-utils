#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

get_led() {
	color="$1"

	usage() {
		printf "usage: %s get [red|green|blue|white]\n" "$0"
		exit 1
	}
	[ $# -lt 1 ] && usage

	# need brightnessctl release after 0.5.1 to have --percentage
	value="$(brightnessctl -d "$color:*" get)"
	max="$(brightnessctl -d "$color:*" max)"
	printf "scale=0; %s / %s * 100\n" "$value" "$max" | bc -l
}

set_led() {
	usage (){
		printf "usage: %s set [red|green|blue|white] [0-100]\n" "$0"
		exit 1
	}
	[ $# -lt 2 ] && usage

	color="$1"
	percent="$2"

	brightnessctl -q -d "$color:*" set "$percent%"
}

set_leds() {
	while [ "$#" -ge 2 ]; do
		set_led "$1" "$2" &
		shift 2
	done

	wait
}

finish_blinking() {
	sxmo_wakelock.sh unlock sxmo_playing_with_leds
	eval set_leds green '$'old_green blue '$'old_blue red '$'old_red ${white:+white '$'old_white}
	exit
}

blink_leds() {
	for color in green blue red white; do
		percent="$(get_led "$color")"
		eval "old_$color=$percent" # store old value
	done

	sxmo_wakelock.sh lock sxmo_playing_with_leds 2s
	trap 'finish_blinking' TERM INT EXIT

	while [ -n "$1" ]; do
		case "$1" in
			green|blue|red|white)
				eval "$1=100"
				shift
				;;
		esac
	done

	# shellcheck disable=SC2154
	set_leds green 0 blue 0 red 0 ${white:+white 0}

	sleep 0.1 # Make blink noticable

	set_leds green "${green:-0}" blue "${blue:-0}" red "${red:-0}" ${white:+white "${white:-0}"}

	sleep 0.1 # Make blink noticable

	set_leds green 0 blue 0 red 0 ${white:+white 0}

	sleep 0.1 # Make blink noticable
}

[ -z "$SXMO_DISABLE_LEDS" ] || exit 1

exec 3<> "${XDG_RUNTIME_DIR:-$HOME}/sxmo.led.lock"

cmd="$1"
shift
case "$cmd" in
	"set"|blink)
		flock -x 3
		"$cmd"_leds "$@"
		;;
	get)
		flock -s 3
		get_led "$@"
		;;
esac
