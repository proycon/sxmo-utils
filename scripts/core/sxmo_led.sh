#!/bin/sh
# shellcheck source=scripts/core/sxmo_common.sh
. "$(which sxmo_common.sh)"

free_mutex() {
	sxmo_mutex.sh can_suspend free "Playing with leds"
	rmdir "$XDG_RUNTIME_DIR"/sxmo.led.lock
}

ensure_mutex() {
	sxmo_mutex.sh can_suspend lock "Playing with leds"

	while ! mkdir "$XDG_RUNTIME_DIR"/sxmo.led.lock 2> /dev/null; do
		sleep 0.1
	done

	trap 'free_mutex' TERM INT EXIT
}

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
	printf "scale=0; %s / %s * 100" "$value" "$max" | bc -l
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

blink_led() {
	for color in green blue red white; do
		percent="$(get_led "$color")"
		eval "old_$color=$percent" # store old value
	done

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

	eval set_leds green '$'old_green blue '$'old_blue red '$'old_red ${white:+white '$'old_white}
}

[ -z "$SXMO_DISABLE_LEDS" ] || exit 1

cmd="$1"
shift
case "$cmd" in
	"set")
		ensure_mutex
		set_leds "$@"
		;;
	get|blink)
		ensure_mutex

		"$cmd"_led "$@"
		;;
esac
