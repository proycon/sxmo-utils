#!/usr/bin/env sh

# This script takes 3 arguments, (1) a fuzzy description of the notification, (2) the action that the notification invokes upon selecting, and (3) the file to watch for deactivation.
# A notification file has 3 different fields, (1) a fuzzy description, (2) the selection action, and (3) the watch file.

NOTIFDIR="$XDG_CONFIG_HOME"/sxmo/notifications

mkdir -p "$NOTIFDIR"
echo "$3" | grep -v . && { echo "Not enough args."; exit 2; }

# Don't send a notification if we're already looking at it!
lsof | grep "$3" && exit 0
	
OUTFILE=$NOTIFDIR/$(date "+%Y:%m:%d:%H:%M:%S:%N")
printf %b "$1\n$2\n$3\n" > "$OUTFILE"
