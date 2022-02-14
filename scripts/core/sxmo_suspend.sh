#!/bin/sh

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
if [ -z "$suspend_time" ] || [ "$suspend_time" -gt "$YEARS8_TO_SEC" ]; then
	suspend_time="$YEARS8_TO_SEC"
fi

sxmo_led.sh blink red

if [ "$suspend_time" -gt 0 ]; then
	sxmo_log "real crusting now (suspendtime=$suspend_time)"
	rtcwake -m mem -s "$suspend_time" >&2
	#We woke up again
	UNSUSPENDREASON="$(whichWake)"
else
	sxmo_log "fake crusting now (suspendtime=$suspend_time)"
	UNSUSPENDREASON=rtc # we fake the crust for those seconds
fi
echo "$UNSUSPENDREASON" > "$SXMO_UNSUSPENDREASONFILE"

sxmo_log "woke up from crust (reason=$UNSUSPENDREASON)"

if [ "$UNSUSPENDREASON" = "rtc" ]; then
	sxmo_mutex.sh can_suspend lock "Waiting for cronjob"
fi

sxmo_hook_postwake.sh "$UNSUSPENDREASON"
