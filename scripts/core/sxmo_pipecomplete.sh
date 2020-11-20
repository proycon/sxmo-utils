#!/usr/bin/env sh
INPUT="$(cat)"
STWIN="$(xprop -root | sed -n '/^_NET_ACTIVE_WINDOW/ s/.* //p')"

menu() {
	pidof "$KEYBOARD" || "$KEYBOARD" &
	RESULT="$(
		printf %b "$(
		echo "Close Menu";
			echo "$INPUT" | grep -Eo '\S+' | tr -d '[:blank:]' | sort | uniq
		)" | dmenu -p "$PROMPT" -l 10 -i -c -fn Terminus-20
	)"
	pkill "$KEYBOARD"
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
