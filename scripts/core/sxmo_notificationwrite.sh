#!/usr/bin/env sh

# This script takes 3 arguments, (1) a fuzzy description of the notification, (2) the action that the notification invokes upon selecting, and (3) the file to watch for deactivation.
# The message will first be fed to Dunst, and then will be handled based on whether the user interacts with the notification or not.
# A notification file has 3 different fields, (1) a timestamp with a fuzzy description, (2) the selection action, and (3) the watch file.

NOTIFDIR="$XDG_CONFIG_HOME"/sxmo/notifications
TIMEFORMAT="$(date "+%H:%M")"

mkdir -p "$NOTIFDIR"
echo "$3" | grep -v . && { echo "Not enough args."; exit 2; }

# Don't send a notification if we're already looking at it!
lsof | grep "$3" && exit 0

{
	sxmo_vibratepine 200;
	sleep 0.1;
	sxmo_vibratepine 200;
	sleep 0.1;
	sxmo_vibratepine 200;
} &

# Dunstify and handle input
DUNST_RETURN=$(dunstify --action="2,open" "$1");
	echo "$DUNST_RETURN" | grep -v 2 || { $2& exit 0; }
	OUTFILE=$NOTIFDIR/$(date "+%Y_%m_%d_%H_%M_%S_%N").tsv
	printf %b "$TIMEFORMAT $1\t$2\t$3\n" > "$OUTFILE"

exit 0
