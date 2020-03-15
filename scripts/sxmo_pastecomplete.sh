#!/usr/bin/env sh
sxmo_keyboard.sh on &

cat |\
grep -Eo '\\S+' |\
tr -d '[:blank:]' |\
sort |\
uniq |\
dmenu -p Type -l 10 -i -c -fn Terminus-20

sxmo_keyboard.sh off

if [[ "$RESULT" = "Close Menu" ]]; then
else
  xargs -I CC xdotool type "$RESULT"
fi
