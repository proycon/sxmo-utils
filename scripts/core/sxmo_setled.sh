#!/bin/sh

usage () {
	printf "usage: %s [red|green|blue|white] [0-100]\n" "$0"
	exit 1
}

[ $# -lt 2 ] && usage

if [ "$2" -lt 0 ] || [ "$2" -gt 100 ]
then
	usage
fi

color="$1"
percent="$2"

# Get type from variable name created dynamically from the color,
# e.g. $LED_RED_TYPE
eval type='$'LED_"$(echo "$color" | tr '[:lower:]' '[:upper:]')"_TYPE

# Defaults
if [ -z "$type" ]; then
	case $color in
		red|green|blue) color="$1"; type="indicator" ;;
		white) color="$1"; type="flash" ;;
		*) usage ;;
	esac
fi

if [ ! -d "/sys/class/leds/$color:$type" ]; then
	echo "LED does not exist: /sys/class/leds/$color:$type"
	exit 1
fi

max="$(cat "/sys/class/leds/$color:$type/max_brightness")"
brightness="$(echo "($percent / 100.0) * $max" | bc -l)"
printf "%0.f\n" "$brightness" > "/sys/class/leds/$color:$type/brightness"
