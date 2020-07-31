#!/usr/bin/env sh

NOTIFDIR="$XDG_CONFIG_HOME"/sxmo/notifications

FILES="$(find "$NOTIFDIR"/ -type f -not -name 'sxmo_incomingcall')"
for FILE in $FILES; do
	CHOICES="$(printf %b "$FILE\t$(echo "$FILE" | cut -d: -f4-6) $(head -1 "$FILE")\n$CHOICES")"
done
PICKED="$(printf %b "$CHOICES\nClose Menu" | cut -f2 | dmenu -c -i -fn "Terminus-18" -p "Notifs" -l 10)"

echo "$PICKED" | grep "Close Menu" && exit 0
TIMESTAMP="$(echo "$PICKED" | cut -d" " -f1 | cut -d: -f4-6)"
FILE="$(printf %b "$CHOICES" | grep "$PICKED" | cut -f1 | grep "$TIMESTAMP")"

# shellcheck disable=SC2091
$(head -2 "$FILE" | tail -1)
