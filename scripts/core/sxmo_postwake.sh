#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(which sxmo_common.sh)"

UNSUSPENDREASON="$1"
if [ "$UNSUSPENDREASON" = "modem" ] || [ "$UNSUSPENDREASON" = "rtc" ]; then
	# Modem wakeup will be handled by the modemmonitor loops
	# Rtc wakeup will eventually be handled by the rtcwake script
	# We should not manage those phone lock state here
	# we will still call the postwake hook though
	sxmo_hooks.sh postwake "$UNSUSPENDREASON"
	exit 0
fi

REDLED_PATH="/sys/class/leds/red:indicator/brightness"
BLUELED_PATH="/sys/class/leds/blue:indicator/brightness"

finish() {
	kill "$BLINKPID"

	echo 0 > "$REDLED_PATH"
	echo 0 > "$BLUELED_PATH"

	# Going back to crust
	if [ "$(sxmo_screenlock.sh getCurState)" != "unlock" ]; then
		sxmo_screenlock.sh crust
	fi

	exit 0
}

trap 'finish' TERM INT EXIT

blink() {
	while [ "$(sxmo_screenlock.sh getCurState)" != "unlock" ]; do
		echo 1 > "$REDLED_PATH"
		echo 0 > "$BLUELED_PATH"
		sleep 0.25
		echo 0 > "$REDLED_PATH"
		echo 1 > "$BLUELED_PATH"
		sleep 0.25
	done
}

blink &
BLINKPID=$!

# call the user hook, but ensure we wait at least 5 seconds which is essential for
# the unlock functionality to function well
sleep 5 &
SLEEPPID=$!
sxmo_hooks.sh postwake "$UNSUSPENDREASON"
wait $SLEEPPID
