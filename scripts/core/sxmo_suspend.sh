#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

# define these in deviceprofile, or default to pinephone
WAKEUPRTC="/sys/class/wakeup/wakeup${SXMO_WAKEUPRTC:-1}/active_count"
MODEMUPRTC="/sys/class/wakeup/wakeup${SXMO_MODEMRTC:-10}/active_count"
POWERRTC="/sys/class/wakeup/wakeup${SXMO_POWERRTC:-5}/active_count"
COVERRTC="/sys/class/wakeup/wakeup${SXMO_COVERRTC:-9999}/active_count"

OLD_RTC_WAKECOUNT="$XDG_RUNTIME_DIR/wakeup.rtc.count"
OLD_MODEM_WAKECOUNT="$XDG_RUNTIME_DIR/wakeup.modem.count"
OLD_POWER_WAKECOUNT="$XDG_RUNTIME_DIR/wakeup.power.count"
OLD_COVER_WAKECOUNT="$XDG_RUNTIME_DIR/wakeup.cover.count"

saveAllEventCounts() {
	#these help us determine the reason of the next wakeup
	cat "$WAKEUPRTC" > "$OLD_RTC_WAKECOUNT"
	cat "$MODEMUPRTC" > "$OLD_MODEM_WAKECOUNT"
	cat "$POWERRTC" > "$OLD_POWER_WAKECOUNT"
	cat "$COVERRTC" > "$OLD_COVER_WAKECOUNT"
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

	if [ -f "$WAKEUPRTC" ] && [ "$(cat "$WAKEUPRTC")" -gt "$(cat "$OLD_RTC_WAKECOUNT")" ] ; then
		echo "rtc"
		return
	fi

	if [ -f "$COVERRTC" ] && [ "$(cat "$COVERRTC")" -gt "$(cat "$OLD_COVER_WAKECOUNT")" ] ;then
		echo "cover"
		return
	fi

	echo "button"
}

sxmo_log "going to suspend to crust"

saveAllEventCounts

sxmo_hook_presuspend.sh

YEARS8_TO_SEC=268435455
if mnc="$(sxmo_hook_mnc.sh)"; then
	#wake up 10 seconds before the next cron event
	suspend_time="$((mnc-10))"
fi

sxmo_uniq_exec.sh sxmo_led.sh blink red

if [ -z "$suspend_time" ] || [ "$suspend_time" -ge "$((YEARS8_TO_SEC-10))" ]; then
	sxmo_log "calling suspend with no suspend time"
	sxmo_hook_suspend.sh
	#We woke up again
	UNSUSPENDREASON="$(whichWake)"
elif [ "$suspend_time" -gt 0 ]; then
	sxmo_log "calling suspend with suspend_time $suspend_time"
	sxmo_hook_suspend.sh "$suspend_time"
	#We woke up again
	UNSUSPENDREASON="$(whichWake)"
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
