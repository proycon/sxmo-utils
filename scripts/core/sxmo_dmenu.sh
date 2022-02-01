#!/bin/sh

# We still use dmenu in dwm|worgs cause pointer/touch events
# are not implemented yet in the X11 library of bemenu

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
				exec pkill bemenu >/dev/null
				;;
			dwm)
				exec pkill dmenu >/dev/null
				;;
		esac
		;;
esac

if [ -n "$WAYLAND_DISPLAY" ]; then
	swaymsg mode menu -q # disable default button inputs
	cleanmode() {
		swaymsg mode default -q
	}
	trap 'cleanmode' TERM INT

	bemenu -l "$(sxmo_rotate.sh isrotated > /dev/null && \
		printf %s "${SXMO_BMENU_LANDSCAPE_LINES:-8}" || \
		printf %s "${SXMO_BMENU_PORTRAIT_LINES:-15}")" "$@"
	returned=$?

	cleanmode
	exit "$returned"
fi

if [ -n "$DISPLAY" ]; then

	# TODO: kill dmenu?

	if sxmo_keyboard.sh isopen; then
		exec dmenu -c -l "$(sxmo_rotate.sh isrotated > /dev/null && \
			printf %s "${SXMO_DMENU_WITH_KB_LANDSCAPE_LINES:-5}" || \
			printf %s "${SXMO_DMENU_WITH_KB_PORTRAIT_LINES:-12}")" "$@"
	else
		exec dmenu -c -l "$(sxmo_rotate.sh isrotated > /dev/null && \
			printf %s "${SXMO_DMENU_LANDSCAPE_LINES:-7}" || \
			printf %s "${SXMO_DMENU_PORTRAIT_LINES:-15}")" "$@"
	fi
	exit
fi

export BEMENU_BACKEND=curses
exec bemenu -w "$@"
