#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# We still use dmenu in dwm|worgs cause pointer/touch events
# are not implemented yet in the X11 library of bemenu

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

#prevent infinite recursion:
unalias bemenu
unalias dmenu

case "$1" in
	isopen)
		case "$SXMO_WM" in
			sway)
				exec pgrep bemenu >/dev/null
				;;
			dwm)
				exec pgrep dmenu >/dev/null
				;;
		esac
		;;
	close)
		case "$SXMO_WM" in
			sway)
				if ! pgrep bemenu >/dev/null; then
					exit
				fi
				exec pkill bemenu >/dev/null
				;;
			dwm)
				if ! pgrep dmenu >/dev/null; then
					exit
				fi
				exec pkill dmenu >/dev/null
				;;
		esac
		;;
esac

if [ -n "$WAYLAND_DISPLAY" ]; then
	if grep -q unlock "$SXMO_STATE"; then
		swaymsg mode menu -q # disable default button inputs
		cleanmode() {
			swaymsg mode default -q
		}
		trap 'cleanmode' TERM INT
	fi

	bemenu -l "$(sxmo_rotate.sh isrotated > /dev/null && \
		printf %s "${SXMO_BEMENU_LANDSCAPE_LINES:-8}" || \
		printf %s "${SXMO_BEMENU_PORTRAIT_LINES:-16}")" "$@"
	returned=$?

	cleanmode
	exit "$returned"
fi

if [ -n "$DISPLAY" ]; then

	# TODO: kill dmenu?

	if sxmo_keyboard.sh isopen; then
		# shellcheck disable=SC2086
		exec dmenu $SXMO_DMENU_OPTS -l "$(sxmo_rotate.sh isrotated > /dev/null && \
			printf %s "${SXMO_DMENU_WITH_KB_LANDSCAPE_LINES:-5}" || \
			printf %s "${SXMO_DMENU_WITH_KB_PORTRAIT_LINES:-12}")" "$@"
	else
		# shellcheck disable=SC2086
		exec dmenu $SXMO_DMENU_OPTS -l "$(sxmo_rotate.sh isrotated > /dev/null && \
			printf %s "${SXMO_DMENU_LANDSCAPE_LINES:-7}" || \
			printf %s "${SXMO_DMENU_PORTRAIT_LINES:-15}")" "$@"
	fi
	exit
fi

export BEMENU_BACKEND=curses
exec bemenu -w "$@"
