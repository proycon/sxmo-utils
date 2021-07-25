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
		echo "sxmo_rtcwake: returning without crust ($(date))" >&2
	fi

	exit 0
}


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

if [ "$1" = "--strict" ]; then
	shift
	#don't run if we're not in crust or not waked by rtc
	if ! grep -q crust "$LASTSTATE" || ! grep -q rtc "$UNSUSPENDREASONFILE"; then
		exit 0
	fi
fi

trap 'finish' TERM INT EXIT

blink &
BLINKPID=$!

echo "sxmo_rtcwake: Running sxmo_rtcwake for $* ($(date))" >&2
"$@"
