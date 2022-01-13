#!/bin/sh

# shellcheck source=configs/profile.d/sxmo_init.sh
. /etc/profile.d/sxmo_init.sh

finish() {
	if grep -q crust "$LASTSTATE" \
		&& grep -q rtc "$UNSUSPENDREASONFILE" \
		&& [ "$(sxmo_screenlock.sh getCurState)" != "unlock" ]; then
		WAKEPROCS=$(pgrep -f sxmo_rtcwake.sh | wc -l)
		if [ "$WAKEPROCS" -gt 2 ]; then
			#each process also spawns a blink subprocess, so we check if there are more than two rather than one:
			echo "sxmo_rtcwake: returning without crust, other sxmo_rtcwake process is still running ($(date))" >&2
		else
			echo "sxmo_rtcwake: going back to crust ($(date))" >&2
			sxmo_screenlock.sh crust
		fi
	else
		echo "sxmo_rtcwake: returning without crust ($(date))" >&2
	fi

	exit 0
}

if [ "$1" = "--strict" ]; then
	shift
	#don't run if we're not in crust or not waked by rtc
	if ! grep -q crust "$LASTSTATE" || ! grep -q rtc "$UNSUSPENDREASONFILE"; then
		exit 0
	fi
fi


trap 'finish' TERM INT EXIT

echo "sxmo_rtcwake: Running sxmo_rtcwake for $* ($(date))" >&2
"$@"
