#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

set -e

finish_blinking() {
	sxmo_wakelock.sh unlock sxmo_playing_with_leds
	trap - INT TERM EXIT
}

blink_leds() {
	sxmo_wakelock.sh lock sxmo_playing_with_leds 2s
	trap 'finish_blinking' TERM INT EXIT
	sxmo_status_led blink "$@"
}

[ -z "$SXMO_DISABLE_LEDS" ] || exit 1

exec 3<> "${XDG_RUNTIME_DIR:-$HOME}/sxmo.led.lock"

cmd="$1"
shift
case "$cmd" in
	set)
		flock -x 3
		sxmo_status_led set "$@"
		;;
	blink)
		flock -x 3
		blink_leds "$@"
		;;
esac
