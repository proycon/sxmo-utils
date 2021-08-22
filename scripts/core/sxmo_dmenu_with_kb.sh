#!/usr/bin/env sh

if [ "$(sxmo_wm.sh)" != "ssh" ]; then
	if sxmo_keyboard.sh isopen; then
		wasopen="1"
	fi
	sxmo_keyboard.sh open
fi

OUTPUT="$(cat | sxmo_dmenu.sh "$@")"
exitcode=$?

if [ -z "$wasopen" ]; then
	sxmo_keyboard.sh close
fi

printf %s "$OUTPUT"
exit $exitcode
