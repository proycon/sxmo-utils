#!/bin/sh

# shellcheck disable=SC2034
SXMO_NO_ICONS=1 #just to make it a bit faster
# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

isopen() {
	pidof "$KEYBOARD" > /dev/null
}

open() {
	#Note: KEYBOARD_ARGS is not quoted by design as it may includes a pipe and further tools
	# shellcheck disable=SC2086
	isopen || eval "$KEYBOARD" $KEYBOARD_ARGS &
}

close() {
	pkill -f "$KEYBOARD"
}

if [ "$1" = "toggle" ]; then
	close || open
elif [ "$1" = "close" ]; then
	close
elif [ "$1" = "isopen" ]; then
	isopen || exit 1
else
	open
fi
