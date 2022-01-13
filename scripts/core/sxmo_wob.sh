#!/bin/sh

# This is a little bit painfull to ensure everything is
# killed on signal

useable_width="$(swaymsg -t get_outputs -r | jq '.[] | select(.focused == true) | .rect.width')"

wob_sock="$XDG_RUNTIME_DIR"/sxmo.wobsock

mkfifo "$wob_sock"

sxmo_daemons.sh start wob_reader tail -f "$wob_sock" 2> /dev/null | \
	wob -W "$((useable_width - 60))" -a top -a left -a right -M 10 &
WOBPID=$!

finish() {
	kill "$WOBPID"
	sxmo_daemons.sh stop wob_reader
	rm -f "$wob_sock"
}
trap 'finish' TERM INT EXIT

wait "$WOBPID"
