#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

[ -z "$SXMO_GPSLOCATIONSFILES" ] && SXMO_GPSLOCATIONSFILES="/usr/share/sxmo/appcfg/places_for_gps.tsv"
CTILESIZE=256
CLN2=0.693147180559945309417
CPI=3.14159265358979323846

# The following {lat,px}2{px,lat} were derived from the foxtrotgps source
# functions of similar names only just translated from C to bc all because...
# foxtrotgps doesn't support autocentering on restored lat/lon instead it
# stores internally X/Y pixel values; so we need conversion fns
lat2px() {
	DEGREES="$1"; ZOOM="$2"
	echo "
		scale=5;
		define atanh(x) { return((l(1 + x) - l(1 - x))/2) };
		-( \
			atanh(s(($DEGREES * $CPI / 180))) * \
			$CTILESIZE * e($ZOOM * $CLN2) / (2 * $CPI) \
		) + (e($ZOOM * $CLN2) * ($CTILESIZE / 2))\
	" | bc -l
}
lon2px() {
	DEGREES="$1"; ZOOM="$2"
	echo "
		scale=5;
		( \
			($DEGREES * $CPI / 180) * $CTILESIZE *  \
			e($ZOOM * $CLN2) / (2 * $CPI) \
		) + (e($ZOOM * $CLN2) * ($CTILESIZE / 2))
	" | bc -l
}
px2lat() {
	PX="$1"; ZOOM="$2"
	echo "
		scale=5;
		define asin(x) {
			if(x==1) return($CPI/2); if(x==-1) return(-$CPI/2); return(a(x/sqrt(1-(x^2))));
		}
		define tanh(x) { auto t;t=e(x+x)-1;return(t/(t+2)) }
		asin(tanh( \
			(-( $PX - ( e( $ZOOM * $CLN2 ) * ( $CTILESIZE / 2 ) ) ) * ( 2 * $CPI )) / \
			( $CTILESIZE * e( $ZOOM * $CLN2)) \
		)) / $CPI * 180
	" | bc -l
}
px2lon() {
	PX="$1"; ZOOM="$2"
	echo "
		scale=5;
		( \
			($PX - (e($ZOOM * $CLN2) * ($CTILESIZE / 2))) * 2 * $CPI / \
			($CTILESIZE * e($ZOOM * $CLN2)) \
		) / $CPI * 180
	" | bc -l
}


killexistingfoxtrotgps() {
	ACTIVEWIN="$(xdotool getactivewindow)"
	WMCLASS="$(xprop -id "$ACTIVEWIN" | grep WM_CLASS | cut -d ' ' -f3-)"
	if echo "$WMCLASS" | grep -i foxtrot; then
		# E.g. by focusing back and refocuing forward we preserve ordering in stack
		xdotool key Super+k
		xdotool key Super+j
		xdotool windowkill "$ACTIVEWIN" && return 0
		return 1
	else
		return 1
	fi
}

gpslatlonget() {
	ZOOM="$(gsettings get org.foxtrotgps global-zoom)"
	Y="$(gsettings get org.foxtrotgps global-y)"
	X="$(gsettings get org.foxtrotgps global-x)"
	WINH="$(
		xwininfo -id "$(xdotool getactivewindow)" | grep -E '^\s*Height' | cut -d: -f2
	)"
	WINW="$(
		xwininfo -id "$(xdotool getactivewindow)" | grep -E '^\s*Width' | cut -d: -f2
	)"
	LAT="$(px2lat "$(echo "$Y + ($WINH / 2)" | bc -l)" "$ZOOM")"
	LON="$(px2lon "$(echo "$X + ($WINW / 2)" | bc -l)" "$ZOOM")"
	echo "$LAT" "$LON" "$ZOOM"
}
gpslatlonset() {
	COORDS="$(echo "$@" | tr -d ',°' | awk '{$1=$1};1')"
	LAT="$(echo "$COORDS" | cut -d' ' -f1)"
	LON="$(echo "$COORDS" | cut -d' ' -f2)"
	ZOOM="$(echo "$COORDS" | cut -d' ' -f3)"
	[ -z "$ZOOM" ] && ZOOM=10
	WINW="$(
		xwininfo -id "$(xdotool getactivewindow)" | grep -E '^\s*Width' | cut -d: -f2
	)"
	WINH="$(
		xwininfo -id "$(xdotool getactivewindow)" | grep -E '^\s*Height' | cut -d: -f2
	)"

	# Translate lat&lon into pixel values
	Y="$(echo "$(lat2px "$LAT" "$ZOOM") - ($WINH / 2)" | bc -l | cut -d. -f1)"
	X="$(echo "$(lon2px "$LON" "$ZOOM") - ($WINW / 2)" | bc -l | cut -d. -f1)"

	killexistingfoxtrotgps
	sxmo_terminal.sh sh -c "
		gsettings set org.foxtrotgps global-zoom $ZOOM;
		gsettings set org.foxtrotgps global-x $X;
		gsettings set org.foxtrotgps global-y $Y;
		foxtrotgps --lat=$LAT --lon=$LON
	" &
}
gpsgeoclueset() {
	# Will retrieve and set latlon from geoclue
	LATLON="$(
		( /usr/libexec/geoclue-2.0/demos/where-am-i -t 10 & ) |
		grep -E "Latitude|Longitude:" -m2 |
		cut -d: -f2 |
		tr -d " "
	)"
	pkill -f where-am-i

	if echo "$LATLON" | grep .; then
		LAT="$(echo "$LATLON" | head -n1)"
		LON="$(echo "$LATLON" | tail -n1)"
		notify-send "You're at $LAT $LON, refocusing map"
		gpslatlonset "$LAT $LON 14"
	else
		notify-send "Failed to retrieve coordinates from geoclue"
	fi
}
copy() {
	COORDS="$(gpslatlonget)"
	printf %b "$COORDS" | xsel -i
	notify-send "Copied coordinates: $COORDS"
}
paste() {
	COORDS="$(xsel)"
	notify-send "Loading coordinates: $COORDS"
	gpslatlonset "$COORDS"
}

droppin() {
	gpslatlonset "$(gpslatlonget)"
}

details() {
	COORDS="$(gpslatlonget)"
	LAT="$(echo "$COORDS" | cut -d' ' -f1)"
	LON="$(echo "$COORDS" | cut -d' ' -f2)"
	ZOOM="$(echo "$COORDS" | cut -d' ' -f3)"
	surf -S "https://nominatim.openstreetmap.org/reverse.php?lat=${LAT}&lon=${LON}&zoom=${ZOOM}&format=html" &
}

menuregionsearch() {
	WINH="$(xwininfo -id "$(xdotool getactivewindow)" | grep -E '^\s*Height' | cut -d: -f2)"
	WINW="$(xwininfo -id "$(xdotool getactivewindow)" | grep -E '^\s*Width' | cut -d: -f2)"

	POIS="
		Close Menu
		Coffee
		Bar
		Restaurant
		Pizza
		Barbershop
	"
	QUERY="$(
		printf %b "$POIS" |
		sed '/^[[:space:]]*$/d' |
		awk '{$1=$1};1' |
		sxmo_dmenu_with_kb.sh -i -p Search
	)"

	if [ "$QUERY" = "Close Menu" ]; then
		exit 0
	else
		ZOOM="$(gsettings get org.foxtrotgps global-zoom)"
		Y="$(gsettings get org.foxtrotgps global-y)"
		X="$(gsettings get org.foxtrotgps global-x)"
		TOP="$(px2lat "$Y" "$ZOOM")"
		LEFT="$(px2lon "$X" "$ZOOM")"
		RIGHT="$(px2lon "$(echo "$X" + "$WINW" | bc -l)" "$ZOOM")"
		BOTTOM="$(px2lat "$(echo "$Y" + "$WINH" | bc -l)" "$ZOOM")"
		surf -S "https://nominatim.openstreetmap.org/search.php?q=$QUERY&polygon_geojson=1&viewbox=${LEFT}%2C${TOP}%2C${RIGHT}%2C${BOTTOM}&bounded=1" &
	fi
}

# Menus
menulocations() {
	CHOICE="$(
		printf %b "$(
			echo "Close Menu";
			echo "$SXMO_GPSLOCATIONSFILES" | tr "," "\n" | xargs cat
		)" |
		grep -vE '^#' |
		sed "s/\t/: /g" |
		sxmo_dmenu_with_kb.sh -i -p "Locations"
	)"
	ZOOM=14
	if [ "$CHOICE" = "Close Menu" ]; then
		exit 0
	else
		LATLON="$(printf %b "$CHOICE" | cut -d: -f2- )"
		gpslatlonset "$LATLON $ZOOM"
	fi
}

menumaptype() {
	IDX=0
	while true; do
		CURRENTMAPTYPE="$(gsettings get org.foxtrotgps repo-name | tr -d "'")"
		CHOICES=$(echo "
			Close Menu
			OSM               $([ "$CURRENTMAPTYPE" = "OSM" ] && echo "$icon_chk") ^ OSM
			OpenCycleMap      $([ "$CURRENTMAPTYPE" = "OpenCycleMap" ] && echo "$icon_chk") ^ OpenCycleMap
			Google Maps       $([ "$CURRENTMAPTYPE" = "Google Maps (testing only)" ] && echo "$icon_chk") ^ Google Maps (testing only)
			Google Sat        $([ "$CURRENTMAPTYPE" = "Google Sat (testing only)" ] && echo "$icon_chk") ^ Google Sat (testing only)
			Maps-for-free.com $([ "$CURRENTMAPTYPE" = "Maps-for-free.com" ] && echo "$icon_chk") ^ Maps-for-free.com
		" | sed '/^[[:space:]]*$/d' | awk '{$1=$1};1')
		CHOICE="$(
			echo "$CHOICES" |
			awk -F^ '{ print $1 }' |
			dmenu --index "$IDX" -p "Map Type" |
			awk '{$1=$1};1'
		)"
		echo "$CHOICE" | grep "Close Menu" && exit 0
		SETCHOICE="$(printf %b "$CHOICES" | grep "$CHOICE" | cut -d^ -f2 | awk '{$1=$1};1')"
		IDX="$(printf %b "$CHOICES" | grep -n "$CHOICE" | cut -d: -f1)"
		killexistingfoxtrotgps
		gsettings set org.foxtrotgps repo-name "$SETCHOICE"
		sxmo_terminal.sh foxtrotgps &
	done
}

"$@"
