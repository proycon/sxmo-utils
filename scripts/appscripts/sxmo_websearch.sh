#!/usr/bin/env sh
pidof svkbd-sxmo || svkbd-sxmo &
SEARCHQUERY="$(
  echo "Close Menu" | dmenu -t -p "Search Query:" -c -fn "Terminus-20" -l 20
)"
pkill svkbd-sxmo
echo "$SEARCHQUERY" | grep . || exit 0

$BROWSER "https://duckduckgo.com/?q=${SEARCHQUERY}"
