#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

keyboard_opened() {
	if sxmo_rotate.sh isrotated ; then
		sxmo_rotate.sh rotnormal
	fi
}

keyboard_closed() {
	if [ "$(sxmo_rotate.sh isrotated)" != "left" ]; then
		sxmo_rotate.sh rotleft
	fi
}

evtest "$SXMO_KEYBOARD_SLIDER_EVENT_DEVICE" | while read -r line; do
	# shellcheck disable=SC2254
	case $line in
		($SXMO_KEYBOARD_SLIDER_CLOSE_EVENT) keyboard_closed ;;
		($SXMO_KEYBOARD_SLIDER_OPEN_EVENT)  keyboard_opened ;;
	esac
done
