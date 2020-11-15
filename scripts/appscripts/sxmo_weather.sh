#!/usr/bin/env sh
[ -z "$SXMO_GPSLOCATIONSFILES" ] && SXMO_GPSLOCATIONSFILES="/usr/share/sxmo/appcfg/places_for_gps.tsv"
ROWHOURS=12
WEATHERXML=""

downloadweatherxml() {
	WEATHERXML="$(
		curl "https://forecast.weather.gov/MapClick.php?lat=$LAT&lon=$LON&FcstType=digitalDWML" 
	)"
}

weatherdata() {
	XPATH="$1"
	GREP="$2"
	echo "$WEATHERXML" |
		xmllint --xpath "$XPATH" - |
		grep "$GREP" |
		sed 's/<[^>]*>/ /g' |
		sed 's/  / /g' |
		awk '{$1=$1};1'
}

printarow() {
	LABEL="$1"
	NITEMS="$2"
	DATA="$3"
	INDENT="$4"
	printf %b "$LABEL: $INDENT"
	for i in $(seq "$NITEMS"); do
		NUM="$(echo "$DATA" | grep -Eo '[0-9]+' | head -n1 | bc)"
		if [ "$NUM" -gt "15" ] && [ "$LABEL" = "Rain" ]; then
			# Rain indicator
			tput setaf 12; printf "%2d  " "$NUM"; tput sgr0
		else
			printf "%2d  " "$NUM"
		fi
		DATA="$(echo "$DATA" | grep -Eo '[0-9]+' | tail -n+2)"
	done
	printf "%b" "\n"
}

clearitemsfromrow() {
	NITEMS="$1"
	DATA="$2"
	for i in $(seq "$NITEMS"); do
		DATA="$(echo "$DATA" | grep -Eo '[0-9]+' | tail -n+2)"
	done
	echo "$DATA"
}

printtables() {
	NOWDAY="$(date +%s)"
	NOWHR="$(echo "$TIME" | cut -c 1-2)"
	INDENTN="0"
	if [ "$NOWHR" != "00" ] && [ "$NOWHOUR" != "12" ]; then
		if [ "$NOWHR" -gt "12" ]; then
			INDENTN="$(echo "$NOWHR - 12" | bc)"
		else
			INDENTN="$(echo "$NOWHR" | bc)"
		fi
	fi
	INDENT=""
	# shellcheck disable=SC2034
	for i in $(seq "$INDENTN"); do INDENT="$INDENT    "; done
	FULLROWHOURS="$ROWHOURS"
	ROWHOURS="$(echo "$ROWHOURS - $INDENTN" | bc)"

	LASTDAY=""
	NHOURS=72
	# E.g. each while loop iteration handles 1 row
	while echo "$TIME" | grep -Eq "[0-9]+" && [ "$NHOURS" -gt 0 ]; do
		if [ "$LASTDAY" != "$NOWDAY" ]; then
			printf "%b" "\n"
			tput setaf 14; date -d "@$NOWDAY" +'%a %b %d'; tput sgr0
		fi
		echo "-----------------------------------------------------"
		LASTDAY="$NOWDAY"

		printarow "Time" "$ROWHOURS" "$TIME" "$INDENT"
		printarow "Temp" "$ROWHOURS" "$TEMP" "$INDENT"
		printarow "Rain" "$ROWHOURS" "$RAIN" "$INDENT"
		printarow "Wind" "$ROWHOURS" "$WIND" "$INDENT"
		printarow "Dirn" "$ROWHOURS" "$DIRECTION" "$INDENT"
		TIME="$(clearitemsfromrow "$ROWHOURS" "$TIME")"
		TEMP="$(clearitemsfromrow "$ROWHOURS" "$TEMP")"
		RAIN="$(clearitemsfromrow "$ROWHOURS" "$RAIN")"
		DIRECTION="$(clearitemsfromrow "$ROWHOURS" "$DIRECTION")"
		WIND="$(clearitemsfromrow "$ROWHOURS" "$WIND")"

		echo "$TIME"  | tr -d " " | tr -d '\n' | grep -Eq "^0" &&
			NOWDAY="$(echo "$NOWDAY + (60 * 60 * 24)" | bc)"

		NHOURS="$(echo "$NHOURS - $ROWHOURS" | bc)"
		ROWHOURS="$FULLROWHOURS"
		INDENT=""
	done
}

getweathertexttable() {
	LAT="$1"
	LON="$2"
	PLACE="$3"

	while true; do
		clear
		downloadweatherxml "$LAT" "$LON" 2>/dev/null
		TEMP="$(weatherdata "//temperature" "hourly")"
		RAIN="$(weatherdata "//probability-of-precipitation" ".")"
		DIRECTION="$(weatherdata "//direction" ".")"
		WIND="$(weatherdata "//wind-speed" ".")"
		#LOCATION="$(weatherdata "//location/description" ".")"
		TIME="$(
			weatherdata "//start-valid-time" "." | 
			grep -oE 'T[0-9]{2}' | tr -d 'T' | tr '\n' ' '
		)"
		tput rev; echo "$PLACE"; tput sgr0
		printtables
		read -r
	done
}

weathermenu() {
	CHOICE="$(
		printf %b "$(
			echo "Close Menu";
			echo "$SXMO_GPSLOCATIONSFILES" |
				tr "," "\n" |
				xargs cat |
				grep "United States" # Note only US latlons work on weather.gov
		)" |
		grep -vE '^#' |
		sed "s/\t/: /g" |
		sxmo_dmenu_with_kb.sh -i -c -l 10 -fn Terminus-18 -p "Locations"
	)"
	if [ "$CHOICE" = "Close Menu" ]; then
	 exit 0
	else
		PLACE="$(printf %b "$CHOICE" | cut -d: -f1 | awk '{$1=$1};1')"
		LAT="$(printf %b "$CHOICE" | cut -d: -f2- | awk '{$1=$1};1' | cut -d ' ' -f1)"
		LON="$(printf %b "$CHOICE" | cut -d: -f2- | awk '{$1=$1};1' | cut -d ' ' -f2)"
		st -e "$0" getweathertexttable "$LAT" "$LON" "$PLACE"
	fi
}

if [ -z "$1" ]; then
  weathermenu
else
  "$@"
fi
