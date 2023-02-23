#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

finish() {
	if [ -n "$INITIAL" ]; then
		echo "$INITIAL" > /sys/power/autosleep
	fi
	kill "$WAKEPID"
	exit
}

autosuspend() {
	YEARS8_TO_SEC=268435455

	INITIAL="$(cat /sys/power/autosleep)"
	trap 'finish' TERM INT EXIT

	while : ; do
		# necessary?
		echo "$INITIAL" > /sys/power/autosleep

		suspend_time=99999999 # far away
		mnc="$(sxmo_hook_mnc.sh)"
		if [ -n "$mnc" ] && [ "$mnc" -gt 0 ] && [ "$mnc" -lt "$YEARS8_TO_SEC" ]; then
			if [ "$mnc" -le 15 ]; then # cronjob imminent
				sxmo_wakelock.sh lock waiting_cronjob infinite
				suspend_time=$((mnc + 1)) # to arm the following one
			else
				suspend_time=$((mnc - 10))
			fi
		fi

		sxmo_wakeafter "$suspend_time" "sxmo_autosuspend.sh wokeup" &
		WAKEPID=$!
		sleep 1 # wait for it to epoll pwait

		echo mem > /sys/power/autosleep
		wait
	done
}

wokeup() {
	# 10s basic hold
	sxmo_wakelock.sh lock woke_up 10000000000

	sxmo_hook_postwake.sh
}

if [ -z "$*" ]; then
	set -- autosuspend
fi

"$@"
