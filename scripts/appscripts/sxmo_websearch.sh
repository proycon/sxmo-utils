#!/usr/bin/env sh
pidof svkbd-sxmo || svkbd-sxmo &
SEARCHQUERY="$(
  echo "Close Menu" | dmenu -p "Search Query:" -c -fn "Terminus-20" -l 20
)"
pkill svkbd-sxmo
[[ "Close Menu" == "$SEARCHQUERY" ]] && exit 0

surf "https://duckduckgo.com/?q=${SEARCHQUERY}"
