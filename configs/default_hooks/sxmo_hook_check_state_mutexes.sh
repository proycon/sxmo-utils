#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This hook goal is to setup mutexes if the device must be considered
# as idle or not, if it can go to crust or not

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

lock_suspend_mutex() {
	echo "$1" | doas tee -a /sys/power/wake_lock > /dev/null
	sxmo_debug "lock \"$1\""
}

free_suspend_mutex() {
	echo "$1" | doas tee -a /sys/power/wake_unlock > /dev/null 2>&1
	sxmo_debug "free \"$1\""
}

cleanup_main_mutex() {
	free_suspend_mutex "checking_mutexes"
	exit 0
}

exec 3<> "${XDG_RUNTIME_DIR:-$HOME}/sxmo.checkstatemutexes.lock"
flock -x 3

lock_suspend_mutex "checking_mutexes"
trap 'cleanup_main_mutex' TERM INT EXIT

# ongoing_call
if pgrep -f sxmo_modemcall.sh > /dev/null; then
	lock_suspend_mutex "ongoing_call"
else
	free_suspend_mutex "ongoing_call"
fi

# hotspot active
if nmcli -t c show --active | grep ^Hotspot; then
	lock_suspend_mutex "hotspot_active"
else
	free_suspend_mutex "hotspot_active"
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
	lock_suspend_mutex "ssh_connected"
else
	free_suspend_mutex "ssh_connected"
fi

# active_mosh
if command -v mosh-server > /dev/null && pgrep -f mosh-server > /dev/null; then
	lock_suspend_mutex "mosh_listening"
else
	free_suspend_mutex "mosh_listening"
fi

# playing_mpc
if command -v mpc > /dev/null && mpc status 2>/dev/null | grep -q '\[playing\]'; then
	lock_suspend_mutex "mpd_playing"
else
	free_suspend_mutex "mpd_playing"
fi

# mpris compatible media player
if command -v playerctl > /dev/null; then
	if test "$(playerctl status 2>/dev/null)" = "Playing"; then
		lock_suspend_mutex "mpris_playing"
	else
		free_suspend_mutex "mpris_playing"
	fi
fi

# photos_processing
if pgrep -f postprocess > /dev/null; then
	lock_suspend_mutex "camera_postprocessing"
else
	free_suspend_mutex "camera_postprocessing"
fi

# auto_suspend
if [ -e "$XDG_CACHE_HOME/sxmo/sxmo.nosuspend" ]; then
	lock_suspend_mutex "manually_disabled"
else
	free_suspend_mutex "manually_disabled"
fi
