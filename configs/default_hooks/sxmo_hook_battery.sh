#!/bin/sh

load_data() {
	data="$(upower -i "$1" | grep . | sed -e 's|^ \+||' -e 's|: \+|:|')"
	type="$(printf "%b" "$data" | grep -m1 -v : | sed -e 's|^ \+||')"
}

data_get() {
	printf "%b" "$data" | grep "^$1:" | cut -d: -f2
}

device_changed() {
	name="$(data_get "native-path")"
	state="$(data_get "state")"
	percentage="$(data_get "percentage" | cut -d% -f1)"

	if [ -z "$name" ] || [ -z "$state" ]; then
		return
	fi

	if [ "$state" = unknown ]; then
		return
	fi

	sxmo_hook_statusbar.sh battery "$name" "$state" "$percentage"
}

object="$1"
event="$2"

load_data "$object"

if [ "$type" != "battery" ]; then
	exit
fi

case "$event" in
	"device changed")
		device_changed "$object"
		;;
esac
