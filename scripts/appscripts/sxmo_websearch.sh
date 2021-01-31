#!/usr/bin/env sh
pidof "$KEYBOARD" || "$KEYBOARD" &
SEARCHQUERY="$(
	echo "Close Menu" | dmenu -t -p "Search:" -c -l 20
)"
pkill "$KEYBOARD"
[ "Close Menu" = "$SEARCHQUERY" ] && exit 0

echo "$SEARCHQUERY" | grep . || exit 0

$BROWSER "https://duckduckgo.com/?q=${SEARCHQUERY}"
