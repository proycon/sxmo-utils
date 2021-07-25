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
	if xinput list-props "$TOUCH_POINTER_ID" | grep "Device Enabled" | grep -q "0$"; then
		if xset q | grep -q "Off: 3"; then
			echo "off" #locked, and screen off
		else
			echo "lock" #locked, but screen on
		fi
	else
		echo "unlock" #normal mode, not locked
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

if [ "$1" != "getCurState" ]; then
	d=$(date)
	echo "sxmo_screenlock: transitioning to stage $1 ($d)" >&2
fi

if [ "$1" = "lock" ] ; then
	#locked state with screen on

	# always echo last state first so that user can use it in their hooks
	# TODO: Document LASTSTATE
	getCurState > "$LASTSTATE"
	# Do we want this hook after disabling all the input devices so users can enable certain devices?
	sxmo_hooks.sh lock

	#turn screen on
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
	#normal unlocked state, screen on

	getCurState > "$LASTSTATE"
	sxmo_hooks.sh unlock

	#turn screen back on
	xset dpms 0 0 0
	xset dpms force on

	#start responding to touch input again
	xinput enable "$TOUCH_POINTER_ID"
	sxmo_hooks.sh lisgdstart &
	echo 16000 > "$NETWORKRTCSCAN"

	updateLed
	exit 0
elif [ "$1" = "off" ] ; then
	#locked state with screen off

	getCurState > "$LASTSTATE"
	# TODO: document this hook
	sxmo_hooks.sh screenoff

	#turn screen off, but have dpms temporarily enable
	#the screen when a button is pressed
	xset dpms 0 0 3
	xset dpms force off

	# stop responding to touch input
	xinput disable "$TOUCH_POINTER_ID"
	killall lisgd

	updateLed
	exit 0
elif [ "$1" = "crust" ] ; then
	getCurState > "$LASTSTATE"
	# USER MUST USE sxmo_screenlock.sh rtc rather than using rtcwake directly.
	echo 1 > "$REDLED_PATH"
	echo 0 > "$BLUELED_PATH"

	saveAllEventCounts

	sxmo_hooks.sh presuspend

	#turn screen off
	xset dpms force off
	suspend_time="$(($(mnc)-10))"

	YEARS8_TO_SEC=268435455
	if [ "$suspend_time" -gt "$YEARS8_TO_SEC" ]; then
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

	if [ "$UNSUSPENDREASON" != "rtc" ]; then
		#turn screen on only when we didn't wake up from an rtc event
		xset dpms force on
	fi

	if [ "$UNSUSPENDREASON" != "modem" ]; then
		echo 1200 > "$NETWORKRTCSCAN"
	fi
	#this will in turn invoke the postwake hook
	sxmo_postwake.sh "$UNSUSPENDREASON"
	exit 0
elif [ "$1" = "getCurState" ] ; then
	getCurState
	exit 0
elif [ "$1" = "updateLed" ] ; then
	updateLed
	exit 0
fi


echo "usage: sxmo_screenlock.sh [lock|unlock|off|crust|rtc|getCurState|updateLed]">&2
