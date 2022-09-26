#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

# in case of weird crash
echo "unlock" > "$SXMO_STATE"
[ -f "$SXMO_UNSUSPENDREASONFILE" ] && rm -f "$SXMO_UNSUSPENDREASONFILE"

# Create xdg user directories, such as ~/Pictures
xdg-user-dirs-update

# Play a funky startup tune if you want (disabled by default)
#mpv --quiet --no-video ~/welcome.ogg &

sxmo_daemons.sh start daemon_manager superd -v

sleep 2 # let time to superd to start correctly

superctl start pipewire
superctl start pipewire-pulse
superctl start wireplumber

# let pipewire load and settle
count=0
while ! pactl info; do
	if [ "$count" -gt 10 ]; then
		sxmo_log "ERR: NO SOUND"
		continue
	fi
	count=$((count + 1))
	sleep 1s
done
sleep 2

case "$SXMO_WM" in
	sway)
		superctl start mako
		superctl start sxmo_wob
		superctl start sxmo_menumode_toggler
		superctl start bonsaid
		;;
	dwm)
		superctl start dunst

		# Auto hide cursor with touchscreen, Show it with a mouse
		if command -v "unclutter-xfixes" > /dev/null; then
			set -- unclutter-xfixes
		else
			set -- unclutter
		fi
		superctl start "$1"

		# Set a pretty wallpaper
		feh --bg-fill "$(xdg_data_path sxmo/background.jpg)"

		superctl start autocutsel
		superctl start autocutsel-primary
		superctl start sxmo-x11-status
		[ -n "$SXMO_MONITOR" ] && xrandr --output "$SXMO_MONITOR" --primary
		;;
esac

if [ -f "${SXMO_MMS_BASE_DIR:-"$HOME"/.mms/modemmanager}/mms" ]; then
	superctl start mmsd
fi

if [ -f "${SXMO_VVM_BASE_DIR:-"$HOME"/.vvm/modemmanager}/vvm" ]; then
	superctl start vvmd
fi

superctl start callaudiod

# Start the desktop widget (e.g. clock)
superctl start sxmo_desktop_widget

# Monitor the battery
superctl start sxmo_battery_monitor

# It watch network changes and update the status bar icon by example
superctl start sxmo_networkmonitor

# The daemon that display notifications popup messages
superctl start sxmo_notificationmonitor

# monitor for headphone for statusbar
superctl start sxmo_soundmonitor

# To setup initial lock state
sxmo_hook_unlock.sh

# Turn on the dbus-monitors for modem-related tasks
sxmo_daemons.sh start modem_monitor sxmo_modemmonitor.sh

deviceprofile="$(command -v "sxmo_deviceprofile_$SXMO_DEVICE_NAME.sh")"

[ -f "$deviceprofile" ] || sxmo_notify_user.sh --urgency=critical \
	"No deviceprofile found $SXMO_DEVICE_NAME. See: https://sxmo.org/deviceprofile"

# Periodically update some status bar components
sxmo_hook_statusbar.sh all
sxmo_daemons.sh start statusbar_periodics sxmo_run_aligned.sh 60 \
	sxmo_hook_statusbar.sh periodics

sxmo_migrate.sh state || sxmo_notify_user.sh --urgency=critical \
	"Config needs migration" "$? file(s) in your sxmo configuration are out of date and disabled - using defaults until you migrate (run sxmo_migrate.sh)"
