#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This hook is called in screenoff, launched as a 10s repeating daemon in
# screenoff, and also sxmo_autosleep.sh.  It will check to see if any custom
# things would like to block suspend.
#
# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

finish() {
	sxmo_wakelock.sh unlock checking_wakelocks
	exit 0
}

exec 3<> "${XDG_RUNTIME_DIR:-$HOME}/sxmo.checkwakelocks.lock"
flock -x 3

DEFAULT_DURATION=30s # to be sure to not lock indefinitely

sxmo_wakelock.sh lock checking_wakelocks "$DEFAULT_DURATION"

trap 'finish' TERM INT EXIT

# ongoing_call
if pgrep -f sxmo_modemcall.sh > /dev/null; then
	sxmo_wakelock.sh lock ongoing_call "$DEFAULT_DURATION"
else
	sxmo_wakelock.sh unlock ongoing_call
fi

# hotspot active
if nmcli -t c show --active | grep -q ^Hotspot; then
	sxmo_wakelock.sh lock hotspot_active "$DEFAULT_DURATION"
else
	sxmo_wakelock.sh unlock hotspot_active
fi

ssh_connected() {
	netstat -tn | awk '
		BEGIN { status = 1 }
		$4 ~ /:22$/ { status = 0; exit }
		END { exit status }
		'
}

# active_ssh
if ssh_connected; then
	sxmo_wakelock.sh lock ssh_connected "$DEFAULT_DURATION"
else
	sxmo_wakelock.sh unlock ssh_connected
fi

# active_mosh
if command -v mosh-server > /dev/null && pgrep -f mosh-server > /dev/null; then
	sxmo_wakelock.sh lock mosh_listening "$DEFAULT_DURATION"
else
	sxmo_wakelock.sh unlock mosh_listening
fi

# playing_mpc
if command -v mpc > /dev/null && mpc status 2>/dev/null | grep -q '\[playing\]'; then
	sxmo_wakelock.sh lock mpd_playing "$DEFAULT_DURATION"
else
	sxmo_wakelock.sh unlock mpd_playing
fi

# mpris compatible media player
if command -v playerctl > /dev/null; then
	if test "$(playerctl status 2>/dev/null)" = "Playing"; then
		sxmo_wakelock.sh lock mpris_playing "$DEFAULT_DURATION"
	else
		sxmo_wakelock.sh unlock mpris_playing
	fi
fi

# photos_processing
if pgrep -f postprocess > /dev/null; then
	sxmo_wakelock.sh lock camera_postprocessing "$DEFAULT_DURATION"
else
	sxmo_wakelock.sh unlock camera_postprocessing
fi

# auto_suspend
if [ -e "$XDG_CACHE_HOME/sxmo/sxmo.nosuspend" ]; then
	sxmo_wakelock.sh lock manually_disabled "$DEFAULT_DURATION"
else
	sxmo_wakelock.sh unlock manually_disabled
fi
