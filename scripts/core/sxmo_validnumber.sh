#!/usr/bin/env sh

# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

if pn valid "$1"; then
	printf %s "$1"
	exit
fi

REFORMATTED="$(pn find ${DEFAULT_COUNTRY:+-c "$DEFAULT_COUNTRY"} "$1")"
if pn valid "$REFORMATTED"; then
	printf %s "$REFORMATTED"
	exit
fi

notify-send "\"$1\" is not a valid phone number"

PICKED="$(printf "Ok\nUse as it is\n" | sxmo_dmenu.sh -p "Invalid Number")"
if [ "$PICKED" = "Use as it is" ]; then
	printf %s "$1"
	exit
fi

exit 1
