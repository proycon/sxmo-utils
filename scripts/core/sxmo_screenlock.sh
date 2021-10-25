#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

# Run xinput and get touchscreen id
TOUCH_POINTER_ID="${TOUCH_POINTER_ID:-"8"}"

REDLED_PATH="/sys/class/leds/red:indicator/brightness"
BLUELED_PATH="/sys/class/leds/blue:indicator/brightness"

WAKEUPRTC="/sys/class/wakeup/wakeup1/active_count"
MODEMUPRTC="/sys/class/wakeup/wakeup10/active_count"
NETWORKRTCSCAN="/sys/module/8723cs/parameters/rtw_scan_interval_thr"
POWERRTC="/sys/class/wakeup/wakeup5/active_count"

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
		# button does not have a active count so if it's none of the above, it has to be the button
		echo "button"
	fi
}

getCurState() {
	#get the current state of the lock
	if sxmo_wm.sh inputevent | grep -q on ; then
		printf "unlock" #normal mode, not locked
	elif sxmo_wm.sh dpms | grep -q off; then
		printf "lock" #locked, but screen on
	else
		printf "off" #locked, and screen off
	fi
}

updateLed() {
	#set the LED to reflect the current lock state
	case "$(getCurState)" in
		"off")
			echo 1 > "$REDLED_PATH"
			echo 1 > "$BLUELED_PATH"
			;;
		"lock")
			echo 0 > "$REDLED_PATH"
			echo 1 > "$BLUELED_PATH"
			;;
		"unlock")
			echo 0 > "$REDLED_PATH"
			echo 0 > "$BLUELED_PATH"
			;;
	esac
}

if [ "$1" != "getCurState" ] && [ "$1" != "updateLed" ]; then
	d=$(date)
	echo "sxmo_screenlock: transitioning to stage $1 ($d)" >&2
fi

lock() {
	#locked state with screen on

	# always echo last state first so that user can use it in their hooks
	# TODO: Document LASTSTATE
	getCurState > "$LASTSTATE"

	sxmo_wm.sh dpms off
	sxmo_wm.sh inputevent off
	killall lisgd

	updateLed

	# Do we want this hook after disabling all the input devices so users can enable certain devices?
	sxmo_hooks.sh lock
}

unlock() {
	#normal unlocked state, screen on

	getCurState > "$LASTSTATE"

	sxmo_wm.sh dpms off
	sxmo_wm.sh inputevent on
	sxmo_hooks.sh lisgdstart &

	echo 16000 > "$NETWORKRTCSCAN"

	updateLed

	sxmo_hooks.sh unlock
}

off() {
	#locked state with screen off

	getCurState > "$LASTSTATE"

	sxmo_wm.sh dpms on
	sxmo_wm.sh inputevent off
	killall lisgd

	updateLed

	sxmo_hooks.sh screenoff
	exit 0
}

crust() {
	getCurState > "$LASTSTATE"
	# USER MUST USE sxmo_screenlock.sh rtc rather than using rtcwake directly.
	echo 1 > "$REDLED_PATH"
	echo 0 > "$BLUELED_PATH"

	saveAllEventCounts

	sxmo_hooks.sh presuspend

	YEARS8_TO_SEC=268435455
	if command -v mnc > /dev/null; then
		#wake up 10 seconds before the next cron event
		suspend_time="$(($(crontab -l | grep sxmo_rtcwake | mnc)-10))"
	fi
	if [ -z "$suspend_time" ] || [ "$suspend_time" -gt "$YEARS8_TO_SEC" ]; then
		suspend_time="$YEARS8_TO_SEC"
	fi
	if [ "$suspend_time" -gt 0 ]; then
		#The actual suspension to crust happens here, mediated by rtcwake
		rtcwake -m mem -s "$suspend_time"
		#We woke up again
		UNSUSPENDREASON=$(whichWake)
	else
		UNSUSPENDREASON=rtc # we fake the crust for those seconds
	fi
	echo "$UNSUSPENDREASON" > "$UNSUSPENDREASONFILE"

	echo "crust" > "$LASTSTATE"

	updateLed

	d=$(date)
	echo "sxmo_screenlock: woke up from crust (reason=$UNSUSPENDREASON) ($d)" >&2
	if [ "$UNSUSPENDREASON" != "modem" ]; then
		echo 1200 > "$NETWORKRTCSCAN"
	fi

	if [ "$UNSUSPENDREASON" != "rtc" ]; then
		pkill -10 -f sxmo_lock_idle.sh
	fi

	sxmo_hooks.sh postwake "$UNSUSPENDREASON"
}

case "$1" in
	unlock|lock|off|crust|getCurState|updateLed)
		"$@"
		exit 0
		;;
	*)
		echo "usage: sxmo_screenlock.sh [lock|unlock|off|crust|rtc|getCurState|updateLed]">&2
		exit 1
		;;
esac

