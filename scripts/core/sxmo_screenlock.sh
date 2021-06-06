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

OLD_RTC_WAKECOUNT="$XDG_RUNTIME_DIR/wakeup.rtc.count"
OLD_MODEM_WAKECOUNT="$XDG_RUNTIME_DIR/wakeup.modem.count"

saveAllEventCounts() {
	cat "$WAKEUPRTC" > "$OLD_RTC_WAKECOUNT"
	cat "$MODEMUPRTC" > "$OLD_MODEM_WAKECOUNT"
	# TODO: add logic for modem wakeup
}

whichWake() {
	if [ "$(cat "$WAKEUPRTC")" -gt "$(cat "$OLD_RTC_WAKECOUNT")" ] ; then
		echo "rtc"
	elif [ "$(cat "$MODEMUPRTC")" -gt "$(cat "$OLD_MODEM_WAKECOUNT")" ] ; then
		echo "modem"
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

if [ "$1" = "lock" ] ; then
	# always echo last state first so that user can use it in their hooks
	# TODO: Document LASTSTATE
	getCurState > "$LASTSTATE"
	# Do we want this hook after disabling all the input devices so users can enable certain devices?
	if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/lock" ]; then
		"$XDG_CONFIG_HOME/sxmo/hooks/lock"
	fi

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
	if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/unlock" ]; then
		"$XDG_CONFIG_HOME/sxmo/hooks/unlock"
	fi

	xset dpms 0 0 0
	xset dpms force on
	xinput enable "$TOUCH_POINTER_ID"
	sxmo_lisgdstart.sh

	updateLed
	exit 0
elif [ "$1" = "off" ] ; then
	getCurState > "$LASTSTATE"
	# TODO: document this hook
	if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/screenoff" ]; then
		"$XDG_CONFIG_HOME/sxmo/hooks/screenoff"
	fi

	xset dpms 0 0 3
	xset dpms force off
	# stop responding to input
	xinput disable "$TOUCH_POINTER_ID"
	killall lisgd

	updateLed
	exit 0
elif [ "$1" = "crust" ] ; then
	getCurState > "$LASTSTATE"

	if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/presuspend" ]; then
		"$XDG_CONFIG_HOME/sxmo/hooks/presuspend"
	fi

	echo 1 > "$REDLED_PATH"
	echo 0 > "$BLUELED_PATH"
	xset dpms force off

	# configure crust
	# TODO: disable all wakeup sources other than button, rtc, and modem.
	# TODO: make sure there is logic in whichWake and saveAllEventCounts functions
	# Do I need to unbind? https://git.sr.ht/~mil/sxmo-utils/commit/bcf4f5c24968df0055d15a9fca649f67de9ced6a
	echo "deep" > /sys/power/mem_sleep # deep sleep

	echo "mem" > /sys/power/state

	echo "crust" > "$LASTSTATE"

	updateLed
	xset dpms force on

	# all we know is it's not the rtc. Maybe modem?
	# TODO: Check mmcli or something or sxmo's notifs when
	# https://gitlab.freedesktop.org/mobile-broadband/ModemManager/-/issues/356
	# https://gitlab.com/postmarketOS/pmaports/-/merge_requests/2066
	# fixed
	# TODO: Document UNSUSPENDREASONFILE
	echo "nonrtc" > "$UNSUSPENDREASONFILE"

	if [ "$(whichWake)" = "button" ] && [ -x "$XDG_CONFIG_HOME/sxmo/hooks/postwake" ]; then
		"$XDG_CONFIG_HOME/sxmo/hooks/postwake"
	fi

	exit 0
elif [ "$1" = "rtc" ] ; then
	getCurState > "$LASTSTATE"
	# USER MUST USE sxmo_screenlock.sh rtc rather than using rtcwake directly.
	# With this new version of lock, we dont check the exit code of the user hook. User must execute "sxmo_screenlock.sh rtc $TIME" at the end of their hook (depending on whether they want to re-rtc)
	echo 1 > "$REDLED_PATH"
	echo 0 > "$BLUELED_PATH"

	saveAllEventCounts

	if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/presuspend" ]; then
		"$XDG_CONFIG_HOME/sxmo/hooks/presuspend"
	fi

	xset dpms force off
	rtcwake -m mem -s "$2"
	whichWake > "$UNSUSPENDREASONFILE"

	echo "crust" > "$LASTSTATE"

	updateLed

	if [ "$(whichWake)" = "rtc" ]; then
		WAKEHOOK="$XDG_CONFIG_HOME/sxmo/hooks/rtcwake";
	elif [ "$(whichWake)" = "button" ]; then
		WAKEHOOK="$XDG_CONFIG_HOME/sxmo/hooks/postwake";
	fi

	if [ "$(whichWake)" != "rtc" ]; then
		xset dpms force on
	fi

	if [ -x "$WAKEHOOK" ]; then
		echo 1200 > "$NETWORKRTCSCAN"
		"$WAKEHOOK"
		echo 16000 > "$NETWORKRTCSCAN"
	fi
	exit 0
elif [ "$1" = "getCurState" ] ; then
	getCurState
	exit 0
fi


echo "usage: sxmo_screenlock.sh [lock|unlock|off|crust|rtc|getCurState]"
