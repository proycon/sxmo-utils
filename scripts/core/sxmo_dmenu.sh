#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# We still use dmenu in dwm|worgs cause pointer/touch events
# are not implemented yet in the X11 library of bemenu

# Note: Only pass parameters to this script that are unambiguous across all
# supported implementations! (dmenu, wofi, dmenu), which are only:

# -p PROMPT
# -i            (case insensitive)


# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

#prevent infinite recursion:
unalias bemenu
unalias dmenu

if [ -z "$SXMO_MENU" ]; then
	case "$SXMO_WM" in
		sway)
			SXMO_MENU=bemenu
			;;
		dwm)
			SXMO_MENU=dmenu
			;;
	esac
fi

case "$1" in
	isopen)
		case "$SXMO_MENU" in
			bemenu)
				exec pgrep bemenu >/dev/null
				;;
			wofi)
				exec pgrep wofi >/dev/null
				;;
			dmenu)
				exec pgrep dmenu >/dev/null
				;;
		esac
		;;
	close)
		case "$SXMO_MENU" in
			bemenu)
				if ! pgrep bemenu >/dev/null; then
					exit
				fi
				exec pkill bemenu >/dev/null
				;;
			wofi)
				if ! pgrep wofi >/dev/null; then
					exit
				fi
				exec pkill wofi >/dev/null
				;;
			dmenu)
				if ! pgrep dmenu >/dev/null; then
					exit
				fi
				exec pkill dmenu >/dev/null
				;;
		esac
		;;
esac

if [ -n "$WAYLAND_DISPLAY" ]; then
	if sxmo_state.sh get | grep -q unlock; then
		swaymsg mode menu -q # disable default button inputs
		cleanmode() {
			swaymsg mode default -q
		}
		trap 'cleanmode' TERM INT
	fi
fi

if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]; then
	case "$SXMO_MENU" in
		bemenu)
			bemenu -l "$(sxmo_rotate.sh isrotated > /dev/null && \
				printf %s "${SXMO_BEMENU_LANDSCAPE_LINES:-8}" || \
				printf %s "${SXMO_BEMENU_PORTRAIT_LINES:-16}")" "$@"
			returned=$?

			[ -n "$WAYLAND_DISPLAY" ] && cleanmode
			exit "$returned"
			;;
		wofi)
			#let wofi handle the number of lines dynamically
			# (wofi is a bit confused after rotating to horizontal mode though)
			# shellcheck disable=SC2046
			#  (not quoted because we want to split args here)
			wofi $(sxmo_rotate.sh isrotated > /dev/null && echo -W "${SXMO_WOFI_LANDSCAPE_WIDTH:-640}" -H "${SXMO_WOFI_LANDSCAPE_HEIGHT:-200}" -l top) "$@"
			returned=$?
			cleanmode
			exit "$returned"
			;;
		dmenu)
			# shellcheck disable=SC2086
			exec dmenu $SXMO_DMENU_OPTS -l "$(sxmo_rotate.sh isrotated > /dev/null && \
				printf %s "${SXMO_DMENU_LANDSCAPE_LINES:-5}" || \
				printf %s "${SXMO_DMENU_PORTRAIT_LINES:-12}")" "$@"
			;;
	esac
else
	#fallback to tty menu (e.g. over ssh)
	export BEMENU_BACKEND=curses
	exec bemenu -w "$@"
fi
