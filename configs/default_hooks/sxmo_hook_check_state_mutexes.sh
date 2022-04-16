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

# modem_use
if pgrep -f sxmo_modem.sh > /dev/null || \
	pgrep -f sxmo_mms.sh > /dev/null || \
	pgrep -f mmcli > /dev/null || \
	pgrep -f mmsctl > /dev/null || \
	pgrep -f sxmo_modemsendsms.sh > /dev/null || \
	sxmo_daemons.sh running modem_nocrust -q || \
	pgrep -f sxmo_modemdaemons.sh >/dev/null; then
	lock_suspend_mutex "Modem is used"
else
	free_suspend_mutex "Modem is used"
fi

# active_ssh
if netstat | grep ESTABLISHED | cut -d':' -f2 | grep -q ssh; then
	lock_suspend_mutex "SSH is connected"
else
	free_suspend_mutex "SSH is connected"
fi

# playing_mpc
if command -v mpc > /dev/null && mpc status 2>/dev/null | grep -q '\[playing\]'; then
	lock_suspend_mutex "MPD is playing music"
else
	free_suspend_mutex "MPD is playing music"
fi

# photos_processing
if pgrep -f postprocess.sh > /dev/null; then
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
