#!/bin/sh

wm="$(sxmo_wm.sh)"

case "$(realpath /var/lib/tinydm/default-session.desktop)" in
	/usr/share/wayland-sessions/swmo.desktop)
		sudo tinydm-set-session -f -s /usr/share/xsessions/sxmo.desktop
		;;
	/usr/share/xsessions/sxmo.desktop)
		sudo tinydm-set-session -f -s /usr/share/wayland-sessions/swmo.desktop
		;;
esac

sudo reboot
