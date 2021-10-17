#!/usr/bin/env sh
SPEAKER=${SPEAKER:-"Line Out"}
HEADPHONE=${HEADPHONE:-"Headphone"}
EARPIECE=${EARPIECE:-"Earpiece"}

audiodevice() {
	amixer sget "Master" | grep -qE '\[on\]' && echo "Master" && return
	amixer sget "$EARPIECE" | grep -qE '\[on\]' && echo "$EARPIECE" && return
	amixer sget "$HEADPHONE" | grep -qE '\[on\]' && echo "$HEADPHONE" && return
	amixer sget "$SPEAKER" | grep -qE '\[on\]' && echo "$SPEAKER" && return
	echo "None"
}

audiodevice
