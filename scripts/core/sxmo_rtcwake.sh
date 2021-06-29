#!/usr/bin/env sh

# shellcheck disable=SC1090
. "$(which sxmo_common.sh)"

REDLED_PATH="/sys/class/leds/red:indicator/brightness"
BLUELED_PATH="/sys/class/leds/blue:indicator/brightness"

finish() {
	kill "$BLINKPID"

	sxmo_screenlock.sh updateLed

	if grep -q rtc "$UNSUSPENDREASONFILE"; then
		# Going back to crust
		if [ "$(sxmo_screenlock.sh getCurState)" != "unlock" ]; then
			sxmo_screenlock.sh crust
		fi
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

"$@"
