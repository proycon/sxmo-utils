#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This hook goal is to setup mutexes if the device must be considered
# as idle or not, if it can go to crust or not

# WARNING: if you remove an entry, be sure to run `sxmo_mutex.sh can_suspend
# free "entry name"` afterwards.

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

lock_suspend_mutex() {
	if ! sxmo_mutex.sh can_suspend lockedby "$1"; then
		sxmo_mutex.sh can_suspend lock "$1"
	fi
}

free_suspend_mutex() {
	sxmo_mutex.sh can_suspend free "$1"
}

cleanup_main_mutex() {
	free_suspend_mutex "Checking some mutexes"
	sxmo_hook_statusbar.sh lockedby
	exit 0
}

lock_suspend_mutex "Checking some mutexes"
trap 'cleanup_main_mutex' TERM INT EXIT

# ongoing_call
if pgrep -f sxmo_modemcall.sh > /dev/null; then
	lock_suspend_mutex "Ongoing call"
else
	free_suspend_mutex "Ongoing call"
fi

# hotspot active
if nmcli --get-values UUID connection show --active 2>/dev/null | while read -r uuid; do
	nmcli --get-values 802-11-wireless.mode connection show "$uuid" 2>/dev/null
done | grep -q '^ap$'; then
	lock_suspend_mutex "Hotspot is active"
else
	free_suspend_mutex "Hotspot is active"
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
	lock_suspend_mutex "SSH is connected"
else
	free_suspend_mutex "SSH is connected"
fi

# active_mosh
if pgrep -f mosh-server > /dev/null; then
	lock_suspend_mutex "Mosh is listening"
else
	free_suspend_mutex "Mosh is listening"
fi

# playing_mpc
if command -v mpc > /dev/null && mpc status 2>/dev/null | grep -q '\[playing\]'; then
	lock_suspend_mutex "MPD is playing music"
else
	free_suspend_mutex "MPD is playing music"
fi

# mpris compatible media player
if command -v playerctl > /dev/null; then
	if test "$(playerctl status 2>/dev/null)" = "Playing"; then
		lock_suspend_mutex "MPRIS client is playing"
	else
		free_suspend_mutex "MPRIS client is playing"
	fi
fi

# photos_processing
if pgrep -f postprocess > /dev/null; then
	lock_suspend_mutex "Camera postprocessing"
else
	free_suspend_mutex "Camera postprocessing"
fi

# auto_suspend
if [ -e "$XDG_CACHE_HOME/sxmo/sxmo.nosuspend" ]; then
	lock_suspend_mutex "Manually disabled"
else
	free_suspend_mutex "Manually disabled"
fi
