#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors
INPUT="$(cat)"
STWIN="$(xprop -root | sed -n '/^_NET_ACTIVE_WINDOW/ s/.* //p')"

menu() {
	RESULT="$(
		printf %b "$(
		echo "Close Menu";
			echo "$INPUT" | grep -Eo '\S+' | tr -d '[:blank:]' | sort | uniq
		)" | sxmo_dmenu.sh -p "$PROMPT" -i
	)"
}

copy() {
	PROMPT=Copy
	menu
	if [ "$RESULT" = "Close Menu" ]; then
		exit 0
	else
		echo "$RESULT" | xclip -i
	fi
}

type() {
	PROMPT=Type
	menu
	if [ "$RESULT" = "Close Menu" ]; then
		exit 0
	else
		xdotool type --window "$STWIN" "$RESULT"
	fi
}

"$1"
