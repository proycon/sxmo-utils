#!/usr/bin/env sh

# The goal of this script is to handle post hibernation behavior
# If we woke up cause of the button :
# We want to trigger the hook and wait for it to finish while blinking.
# Or at least, blink for some seconds.
# If we woke up cause of the modem or rtc :
# The modem monitor or rtcwake scripts will handle everything
# We still trigger the hooks without doing anything else

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(which sxmo_common.sh)"

UNSUSPENDREASON="$1"
if [ "$UNSUSPENDREASON" = "modem" ] || [ "$UNSUSPENDREASON" = "rtc" ]; then
	# Modem wakeup will be handled by the modemmonitor loops
	# Rtc wakeup will eventually be handled by the rtcwake script
	# We should not manage those phone lock state here
	# we will still call the postwake hook though
	echo "sxmo_postwake: invoking postwake hook after wakeup (reason=$UNSUSPENDREASON, 2, $(date))" >&2
	sxmo_hooks.sh postwake "$UNSUSPENDREASON"
	exit 0
fi

REDLED_PATH="/sys/class/leds/red:indicator/brightness"
BLUELED_PATH="/sys/class/leds/blue:indicator/brightness"

finish() {
	kill "$SLEEPPID"
	kill "$CHECKPID"
	kill "$BLINKPID"

	echo 0 > "$REDLED_PATH"
	echo 0 > "$BLUELED_PATH"

	wait $HOOKPID

	# Going back to crust
	if [ "$(sxmo_screenlock.sh getCurState)" != "unlock" ]; then
		echo "[$(date)] Going back to crust" >&2
		sxmo_screenlock.sh crust
	fi

	exit 0
}

trap 'finish' TERM INT EXIT

blink() {
	while : ; do
		echo 1 > "$REDLED_PATH"
		echo 0 > "$BLUELED_PATH"
		sleep 0.25
		echo 1 > "$REDLED_PATH"
		echo 1 > "$BLUELED_PATH"
		sleep 0.25
	done
}

checkstate() {
	while [ "$(sxmo_screenlock.sh getCurState)" != "unlock" ] ; do
		sleep 0.25
	done
	finish
}

sxmo_wm.sh dpms off

# call the user hook, but ensure we wait at least 5 seconds which is essential for
# the unlock functionality to function well
sleep 5 &
SLEEPPID=$!

blink &
BLINKPID=$!

echo "sxmo_postwake: invoking postwake hook after wakeup (reason=$UNSUSPENDREASON, 1, $(date))" >&2
sxmo_hooks.sh postwake "$UNSUSPENDREASON" &
HOOKPID=$!

checkstate &
CHECKPID=$!

wait $SLEEPPID
wait $HOOKPID
