#!/bin/sh

not_ready_yet() {
	notify-send "Your device looks not ready yet"
	exit 1
}

case "$(realpath /var/lib/tinydm/default-session.desktop)" in
	/usr/share/wayland-sessions/swmo.desktop)
		command -v dwm || not_ready_yet
		sudo tinydm-set-session -f -s /usr/share/xsessions/sxmo.desktop
		pkill sway
		;;
	/usr/share/xsessions/sxmo.desktop)
		command -v sway || not_ready_yet
		sudo tinydm-set-session -f -s /usr/share/wayland-sessions/swmo.desktop
		pkill dwm
		;;
esac
