#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

sxmo_keyboard.sh open
SEARCHQUERY="$(
	echo "Close Menu" | dmenu -t -p "Search:" -c -l 20
)"
sxmo_keyboard.sh close
[ "Close Menu" = "$SEARCHQUERY" ] && exit 0

echo "$SEARCHQUERY" | grep . || exit 0

$BROWSER "https://duckduckgo.com/?q=${SEARCHQUERY}"
