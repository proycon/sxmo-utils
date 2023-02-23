#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

# define these in deviceprofile, or default to pinephone
MODEMUPRTC="/sys/class/wakeup/wakeup${SXMO_MODEMRTC:-10}/active_count"
POWERRTC="/sys/class/wakeup/wakeup${SXMO_POWERRTC:-5}/active_count"
BATTERYRTC="/sys/class/wakeup/wakeup${SXMO_BATTERYRTC:-4}/active_count"
COVERRTC="/sys/class/wakeup/wakeup${SXMO_COVERRTC:-9999}/active_count"

OLD_MODEM_WAKECOUNT="$XDG_RUNTIME_DIR/wakeup.modem.count"
OLD_POWER_WAKECOUNT="$XDG_RUNTIME_DIR/wakeup.power.count"
OLD_COVER_WAKECOUNT="$XDG_RUNTIME_DIR/wakeup.cover.count"
OLD_BATTERY_WAKECOUNT="$XDG_RUNTIME_DIR/wakeup.battery.count"

saveAllEventCounts() {
	#these help us determine the reason of the next wakeup
	cat "$MODEMUPRTC" > "$OLD_MODEM_WAKECOUNT"
	cat "$POWERRTC" > "$OLD_POWER_WAKECOUNT"
	cat "$COVERRTC" > "$OLD_COVER_WAKECOUNT"
	cat "$BATTERYRTC" > "$OLD_BATTERY_WAKECOUNT"
}

whichWake() {
	#attempt to find the reason why we woke up:
	if [ -f "$POWERRTC" ] && [ "$(cat "$POWERRTC")" -gt "$(cat "$OLD_POWER_WAKECOUNT")" ] ; then
		echo "usb power"
		return
	fi

	if [ -f "$MODEMUPRTC" ] && [ "$(cat "$MODEMUPRTC")" -gt "$(cat "$OLD_MODEM_WAKECOUNT")" ] ; then
		echo "modem"
		return
	fi

	if [ -f "$COVERRTC" ] && [ "$(cat "$COVERRTC")" -gt "$(cat "$OLD_COVER_WAKECOUNT")" ] ;then
		echo "cover"
		return
	fi

	if [ -f "$BATTERYRTC" ] && [ "$(cat "$BATTERYRTC")" -gt "$(cat "$OLD_BATTERY_WAKECOUNT")" ] ;then
		echo "battery"
		return
	fi

	echo "button"
}

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
				echo "waiting_cronjob" | doas tee -a /sys/power/wake_lock > /dev/null
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
	echo "woke_up 10000000000" | doas tee -a /sys/power/wake_lock > /dev/null

	sxmo_hook_postwake.sh
}

if [ -z "$*" ]; then
	set -- autosuspend
fi

"$@"
