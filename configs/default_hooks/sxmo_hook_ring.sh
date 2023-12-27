#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script is executed (asynchronously) when you get an incoming call
# You can use it to play a ring tone

# $1 = Contact Name or Number (if not in contacts)

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

# Only vibrate if you already got an active call
if sxmo_modemcall.sh list_active_calls \
	| grep -v ringing-in \
	| grep -q .; then
	sxmo_vibrate 1500 "${SXMO_VIBRATE_STRENGTH:-1}"
	exit
fi

# Shallow if you have more than one ringing call
if ! sxmo_modemcall.sh list_active_calls \
	| grep -c ringing-in \
	| grep -q 1; then
	exit
fi

finish() {
	trap - INT TERM EXIT
	jobs -p | xargs -r kill
	exit
}

ring() {
	mpv --no-resume-playback --quiet --no-video \
		--loop="${SXMO_RINGNUMBER:-10}" "$SXMO_RINGTONE" >/dev/null &
}

vibrate() {
	while : ; do
		trap 'finish' INT TERM EXIT
		sxmo_vibrate 1500 "${SXMO_VIBRATE_STRENGTH:-1}" &
		wait "$!"

		sleep 0.5 &
		wait "$!"
	done &
}

# RING & VIBRATE MODE (DEFAULT)
if [ ! -f "$XDG_CONFIG_HOME"/sxmo/.noring ] && [ ! -f "$XDG_CONFIG_HOME"/sxmo/.novibrate ]; then
	sxmo_log "RING AND VIBRATE"

	# In order for this to work, you will need to install playerctl and run playerctld
	# In order for this to work with mpv, you will need to install mpv-mdis.
	sxmo_playerctl.sh pause_all

	ring
	vibrate

# RING-ONLY MODE
elif [ ! -f "$XDG_CONFIG_HOME"/sxmo/.noring ] && [ -f "$XDG_CONFIG_HOME"/sxmo/.novibrate ]; then
	sxmo_log "RING ONLY"

	# In order for this to work, you will need to install playerctl and run playerctld
	# In order for this to work with mpv, you will need to install mpv-mdis.
	sxmo_playerctl.sh pause_all

	ring

# VIBRATE-ONLY MODE
elif [ ! -f "$XDG_CONFIG_HOME"/sxmo/.novibrate ] && [ -f "$XDG_CONFIG_HOME"/sxmo/.noring ]; then
	smxo_log "VIBRATE ONLY"

	vibrate
fi

trap 'finish' INT TERM EXIT
sleep "${SXMO_RINGTIME:-20}" &
wait "$!"
