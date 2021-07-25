#!/usr/bin/env sh

# shellcheck disable=SC1090
. "$(which sxmo_common.sh)"

REDLED_PATH="/sys/class/leds/red:indicator/brightness"
BLUELED_PATH="/sys/class/leds/blue:indicator/brightness"

finish() {
	kill "$BLINKPID"

	sxmo_screenlock.sh updateLed

	if grep -q crust "$LASTSTATE" \
		&& grep -q rtc "$UNSUSPENDREASONFILE" \
		&& [ "$(sxmo_screenlock.sh getCurState)" != "unlock" ]; then
		echo "sxmo_rtcwake: going back to crust ($(date))" >&2
		sxmo_screenlock.sh crust
	else
		echo "sxmo_rtcwake: not returning to crust ($(date))" >&2
	fi

	exit 0
}

trap 'finish' TERM INT EXIT

blink() {
	while [ "$(sxmo_screenlock.sh getCurState)" != "unlock" ]; do
		echo 1 > "$REDLED_PATH"
		echo 0 > "$BLUELED_PATH"
		sleep 0.25
		echo 1 > "$REDLED_PATH"
		echo 1 > "$BLUELED_PATH"
		sleep 0.25
	done
}

blink &
BLINKPID=$!

echo "sxmo_rtcwake: Running sxmo_rtcwake for $* ($(date))" >&2
"$@"
