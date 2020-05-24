#!/usr/bin/env sh
pidof svkbd-sxmo || svkbd-sxmo &

OUTINPUT="$(
echo "speaker
headphones
earpiece
none
Close Menu" | dmenu -p "Audio Out" -c -fn "Terminus-30" -l 20
)"

pkill svkbd-sxmo
[[ "Close Menu" == "$OUTINPUT" ]] && exit 0

SPEAKER="Line Out"
HEADPHONE="Headphone"
EARPIECE="Earpiece"

amixer set "$SPEAKER" mute > /dev/null
amixer set "$HEADPHONE" mute > /dev/null
amixer set "$EARPIECE" mute > /dev/null

if [[ "$OUTINPUT" = "speaker" ]]; then
  amixer set "$SPEAKER" unmute > /dev/null
elif [[ "$OUTINPUT" = "headphones" ]]; then
  amixer set "$HEADPHONE" unmute > /dev/null
elif [[ "$OUTINPUT" = "earpiece" ]]; then
  amixer set "$EARPIECE" unmute > /dev/null
fi

