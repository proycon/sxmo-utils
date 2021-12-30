#!/bin/sh

usage () {
	printf "usage: %s [red|green|blue|white] [0-255]\n" "$0"
	exit 1
}

[ $# -lt 2 ] && usage

if [ "$2" -lt 0 ] || [ "$2" -gt 255 ]
then
	usage
fi

color="$1"
brightness="$2"

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

printf "%s\n" "$brightness" > "/sys/class/leds/$color:$type/brightness"
