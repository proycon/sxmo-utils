#!/usr/bin/env sh
OUTINPUT="$(
echo "Speaker
Headphones
Earpiece
Close Menu" | dmenu -p "Audio Out" -c -fn "Terminus-30" -l 20
)"

[[ "Close Menu" == "$OUTINPUT" ]] && exit 0

SPEAKER="Line Out"
HEADPHONE="Headphone"
EARPIECE="Earpiece"

amixer set "$SPEAKER" mute
amixer set "$HEADPHONE" mute
amixer set "$EARPIECE" mute

if [[ "$OUTINPUT" = "Speaker" ]]; then
  amixer set "$SPEAKER" unmute
elif [[ "$OUTINPUT" = "Headphones" ]]; then
  amixer set "$HEADPHONE" unmute
elif [[ "$OUTINPUT" = "Earpiece" ]]; then
  amixer set "$EARPIECE" unmute
fi

