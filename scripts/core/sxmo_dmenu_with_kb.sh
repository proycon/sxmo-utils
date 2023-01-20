#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

if [ -n "$WAYLAND_DISPLAY$DISPLAY" ]; then
	if sxmo_keyboard.sh isopen; then
		wasopen="1"
	fi
	sxmo_keyboard.sh open
	sleep .1 # give keyboard time to open
fi

OUTPUT="$(cat | sxmo_dmenu.sh "$@")"
exitcode=$?

if [ -z "$wasopen" ]; then
	sxmo_keyboard.sh close
fi

printf %s "$OUTPUT"
exit $exitcode
