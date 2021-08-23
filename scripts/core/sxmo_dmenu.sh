#!/usr/bin/env sh

# We still use dmenu in dwm|worgs cause pointer/touch events
# are not implemented yet in the X11 library of bemenu

case "$1" in
	isopen)
		case "$(sxmo_wm.sh)" in
			sway|ssh)
				exec pgrep bemenu
				;;
			xorg|dwm)
				exec pgrep dmenu
				;;
		esac
		;;
	close)
		case "$(sxmo_wm.sh)" in
			sway|ssh)
				exec pkill bemenu
				;;
			xorg|dwm)
				exec pkill dmenu
				;;
		esac
		;;
esac > /dev/null

case "$(sxmo_wm.sh)" in
	sway)
		exec bemenu --scrollbar autohide -n -w -c -l "$(sxmo_rotate.sh isrotated && printf 5 ||  printf 15)" "$@"
		;;
	xorg|dwm)
		exec dmenu -c -l "$(sxmo_rotate.sh isrotated && printf 7 || printf 23)" "$@"
		;;
	ssh)
		export BEMENU_BACKEND=curses
		exec bemenu -w "$@"
		;;
esac
