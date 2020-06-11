#!/usr/bin/env sh

pidof svkbd-sxmo || svkbd-sxmo &
ZIP=$(
	printf %b "
		10025 - NYC
		60007 - Chicago
		94016 - San Francisco
		97035 - Portland, OR
	" |
	awk 'NF' |
	awk '{$1=$1};1' |
	dmenu -fn Terminus-20 -i -c -l 10 -p "US Zipcode" |
	awk -F " " '{print $1}'
)
pkill svkbd-sxmo

LATLON="$(grep "^$ZIP" /usr/share/sxmo/zipcodes_for_weather.csv)"
LAT=$(echo "$LATLON" | cut -d, -f2 | tr -d ' ')
LON=$(echo "$LATLON" | cut -d, -f3 | tr -d ' ')
URL="https://forecast.weather.gov/MapClick.php?lat=${LAT}&lon=${LON}&unit=0&lg=english&FcstType=text&TextType=1"

st -f Monospace-20 -e w3m "$URL"
