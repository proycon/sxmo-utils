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
	cat "$WAKEUPRTC" > "$OLD_RTC_WAKECOUNT"
	cat "$MODEMUPRTC" > "$OLD_MODEM_WAKECOUNT"
	cat "$POWERRTC" > "$OLD_POWER_WAKECOUNT"
	# TODO: add logic for modem wakeup
}

whichWake() {
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
	if xinput list-props "$TOUCH_POINTER_ID" | grep "Device Enabled" | grep -q "0$"; then
		if xset q | grep -q "Off: 3"; then
			echo "off"
		else
			echo "lock"
		fi
	else
		echo "unlock"
	fi
}

updateLed() {
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

if [ "$1" != "getCurState" ]; then
	d=$(date)
	echo "sxmo_screenlock: transitioning to stage $1 ($d)" >&2
fi

if [ "$1" = "lock" ] ; then
	# always echo last state first so that user can use it in their hooks
	# TODO: Document LASTSTATE
	getCurState > "$LASTSTATE"
	# Do we want this hook after disabling all the input devices so users can enable certain devices?
	sxmo_hooks.sh lock

	xset dpms 0 0 0
	xset dpms force on

	# TODO: Could be improved by running xinput and disabling ALL input devices automatically but would need
	# to decide on the hook issues. Do we want a prelock and postlock? Or should users
	# be expected to edit the source code for disabling certain input devices?
	# this code allows us to not use the slock locking mechanism in the original sxmo_lock.sh
	# when combined with a working slock (see ~iv's) implementation, this should be secure.
	xinput disable "$TOUCH_POINTER_ID"
	killall lisgd

	updateLed
	exit 0
elif [ "$1" = "unlock" ] ; then
	getCurState > "$LASTSTATE"
	sxmo_hooks.sh unlock

	xset dpms 0 0 0
	xset dpms force on
	xinput enable "$TOUCH_POINTER_ID"
	sxmo_hooks.sh lisgdstart &
	echo 16000 > "$NETWORKRTCSCAN"

	updateLed
	exit 0
elif [ "$1" = "off" ] ; then
	getCurState > "$LASTSTATE"
	# TODO: document this hook
	sxmo_hooks.sh screenoff

	xset dpms 0 0 3
	xset dpms force off
	# stop responding to input
	xinput disable "$TOUCH_POINTER_ID"
	killall lisgd

	updateLed
	exit 0
elif [ "$1" = "crust" ] ; then
	getCurState > "$LASTSTATE"
	# USER MUST USE sxmo_screenlock.sh rtc rather than using rtcwake directly.
	# With this new version of lock, we dont check the exit code of the user hook. User must execute "sxmo_screenlock.sh rtc $TIME" at the end of their hook (depending on whether they want to re-rtc)
	echo 1 > "$REDLED_PATH"
	echo 0 > "$BLUELED_PATH"

	saveAllEventCounts

	sxmo_hooks.sh presuspend

	xset dpms force off
	suspend_time="$(($(mnc)-10))"
	if [ "$suspend_time" -gt 268435455 ]; then
		suspend_time=268435455
	fi
	if [ "$suspend_time" -gt 0 ]; then
		rtcwake -m mem -s "$suspend_time"
		UNSUSPENDREASON=$(whichWake)
	else
		UNSUSPENDREASON=rtc # we fake the crust for those seconds
	fi
	echo "$UNSUSPENDREASON" > "$UNSUSPENDREASONFILE"

	echo "crust" > "$LASTSTATE"

	updateLed

	d=$(date)
	echo "sxmo_screenlock: woke up from crust (reason=$UNSUSPENDREASON) ($d)" >&2

	if [ "$UNSUSPENDREASON" != "rtc" ]; then
		xset dpms force on
	fi

	if [ "$UNSUSPENDREASON" = "button" ]; then
		echo 1200 > "$NETWORKRTCSCAN"
		sxmo_hooks.sh postwake
	fi
	exit 0
elif [ "$1" = "getCurState" ] ; then
	getCurState
	exit 0
elif [ "$1" = "updateLed" ] ; then
	updateLed
	exit 0
fi


echo "usage: sxmo_screenlock.sh [lock|unlock|off|crust|rtc|getCurState|updateLed]">&2
