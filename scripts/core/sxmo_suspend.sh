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

sxmo_log "going to suspend to crust"

saveAllEventCounts

sxmo_hook_presuspend.sh

sxmo_uniq_exec.sh sxmo_led.sh blink red

if suspend_time="$(sxmo_hook_mnc.sh)"; then
	sxmo_log "calling suspend with suspend_time <$suspend_time>"

	start="$(date "+%s")"
	sxmo_hook_suspend.sh "$suspend_time"

	#We woke up again
	time_spent="$(( $(date "+%s") - start ))"

	if [ "$suspend_time" -gt 0 ] && [ "$((time_spent + 10))" -ge "$suspend_time" ]; then
		UNSUSPENDREASON="rtc"
	else
		UNSUSPENDREASON="$(whichWake)"
	fi
else
	sxmo_log "fake suspend (suspend_time ($suspend_time) less than zero)"
	UNSUSPENDREASON=rtc # we fake the crust for those seconds
fi

echo "$UNSUSPENDREASON" > "$SXMO_UNSUSPENDREASONFILE"

sxmo_log "woke up from crust (reason=$UNSUSPENDREASON)"

if [ "$UNSUSPENDREASON" = "rtc" ]; then
	sxmo_mutex.sh can_suspend lock "Waiting for cronjob"
fi

sxmo_hook_postwake.sh "$UNSUSPENDREASON"
