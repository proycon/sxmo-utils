#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

get_type() {
	# Get type from variable name created dynamically from the color,
	# e.g. $SXMO_LED_RED_TYPE
	eval type='$'SXMO_LED_"$(echo "$1" | tr '[:lower:]' '[:upper:]')"_TYPE

	# Defaults
	if [ -z "$type" ]; then
		case $1 in
			red|green|blue) type="indicator" ;;
			white) type="flash" ;;
		esac
	fi

	printf %s "$type"
}

get_led() {
	color="$1"

	usage() {
		printf "usage: %s get [red|green|blue|white]\n" "$0"
		exit 1
	}
	[ $# -lt 1 ] && usage

	type="$(get_type "$color")";

	value="$(cat "/sys/class/leds/$color:$type/brightness")"
	max="$(cat "/sys/class/leds/$color:$type/max_brightness")"
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

	type="$(get_type "$color")";

	if [ ! -d "/sys/class/leds/$color:$type" ]; then
		echo "LED does not exist: /sys/class/leds/$color:$type"
		exit 1
	fi

	max="$(cat "/sys/class/leds/$color:$type/max_brightness")"
	brightness="$(echo "($percent / 100.0) * $max" | bc -l)"
	printf "%0.f\n" "$brightness" > "/sys/class/leds/$color:$type/brightness"
}

set_leds() {
	while [ "$#" -ge 2 ]; do
		set_led "$1" "$2" &
		shift 2
	done

	wait
}

finish_blinking() {
	sxmo_wakelock.sh unlock playing_with_leds
	eval set_leds green '$'old_green blue '$'old_blue red '$'old_red ${white:+white '$'old_white}
	exit
}

blink_leds() {
	for color in green blue red white; do
		percent="$(get_led "$color")"
		eval "old_$color=$percent" # store old value
	done

	sxmo_wakelock.sh lock playing_with_leds 2000000000
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
flock -x 3

cmd="$1"
shift
case "$cmd" in
	"set"|blink)
		"$cmd"_leds "$@"
		;;
	get)
		get_led "$@"
		;;
esac
