#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

# define these in deviceprofile, or default to pinephone
WAKEUPRTC="/sys/class/wakeup/wakeup${SXMO_WAKEUPRTC:-1}/active_count"
MODEMUPRTC="/sys/class/wakeup/wakeup${SXMO_MODEMRTC:-10}/active_count"
POWERRTC="/sys/class/wakeup/wakeup${SXMO_POWERRTC:-10}/active_count"

OLD_RTC_WAKECOUNT="$XDG_RUNTIME_DIR/wakeup.rtc.count"
OLD_MODEM_WAKECOUNT="$XDG_RUNTIME_DIR/wakeup.modem.count"
OLD_POWER_WAKECOUNT="$XDG_RUNTIME_DIR/wakeup.power.count"

saveAllEventCounts() {
	#these help us determine the reason of the next wakeup
	cat "$WAKEUPRTC" > "$OLD_RTC_WAKECOUNT"
	cat "$MODEMUPRTC" > "$OLD_MODEM_WAKECOUNT"
	cat "$POWERRTC" > "$OLD_POWER_WAKECOUNT"
	# TODO: add logic for modem wakeup
}

whichWake() {
	#attempt to find the reason why we woke up:
	if [ "$(cat "$POWERRTC")" -gt "$(cat "$OLD_POWER_WAKECOUNT")" ] ; then
		echo "usb power"
	elif [ "$(cat "$MODEMUPRTC")" -gt "$(cat "$OLD_MODEM_WAKECOUNT")" ] ; then
		echo "modem"
	elif [ "$(cat "$WAKEUPRTC")" -gt "$(cat "$OLD_RTC_WAKECOUNT")" ] ; then
		echo "rtc"
	else
		echo "button"
	fi
}

getCurState() {
	#get the current state of the lock
	if sxmo_wm.sh inputevent touchscreen | grep -q on ; then
		printf "unlock" #normal mode, not locked
	elif [ -n "$SXMO_STYLUS_ID" ] && sxmo_wm.sh inputevent stylus | grep -q on; then
		printf "unlock"
	elif sxmo_wm.sh dpms | grep -q off; then
		printf "lock" #locked, but screen on
	else
		printf "off" #locked, and screen off
	fi
}

lock() {
	#locked state with screen on
	sxmo_log "transitioning from $(getCurState) to stage lock"
	getCurState > "$SXMO_LASTSTATE"
	sxmo_hooks.sh lock
}

unlock() {
	#normal unlocked state, screen on
	sxmo_log "transitioning from $(getCurState) to stage unlock"
	getCurState > "$SXMO_LASTSTATE"
	sxmo_hooks.sh unlock
}

off() {
	#locked state with screen off
	sxmo_log "transitioning from $(getCurState) to stage off"
	getCurState > "$SXMO_LASTSTATE"
	sxmo_hooks.sh screenoff
}

crust() {
	sxmo_log "transitioning from $(getCurState) to stage crust"

	getCurState > "$SXMO_LASTSTATE"

	sxmo_led.sh blink red

	saveAllEventCounts

	sxmo_hooks.sh presuspend

	YEARS8_TO_SEC=268435455
	if mnc="$(sxmo_hooks.sh mnc)"; then
		#wake up 10 seconds before the next cron event
		suspend_time="$((mnc-10))"
	fi
	if [ -z "$suspend_time" ] || [ "$suspend_time" -gt "$YEARS8_TO_SEC" ]; then
		suspend_time="$YEARS8_TO_SEC"
	fi
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

	echo "crust" > "$SXMO_LASTSTATE"

	sxmo_log "woke up from crust (reason=$UNSUSPENDREASON)"

	sxmo_hooks.sh postwake "$UNSUSPENDREASON"
}

case "$1" in
	unlock|lock|off|crust|getCurState)
		"$@"
		exit 0
		;;
	*)
		echo "usage: sxmo_screenlock.sh [lock|unlock|off|crust|rtc|getCurState]">&2
		exit 1
		;;
esac

