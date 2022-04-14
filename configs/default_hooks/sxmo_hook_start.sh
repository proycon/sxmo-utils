#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(which sxmo_common.sh)"

# in case of weird crash
echo "unlock" > "$SXMO_STATE"
[ -f "$SXMO_UNSUSPENDREASONFILE" ] && rm -f "$SXMO_UNSUSPENDREASONFILE"

# Create xdg user directories, such as ~/Pictures
xdg-user-dirs-update

# Play a funky startup tune if you want (disabled by default)
#mpv --quiet --no-video ~/welcome.ogg &

sxmo_daemons.sh start daemon_manager superd -v

case "$SXMO_WM" in
	sway)
		superctl start mako
		superctl start sxmo_wob
		superctl start sxmo_menumode_toggler
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
		feh --bg-fill /usr/share/sxmo/background.jpg

		superctl start autocutsel
		superctl start autocutsel-primary
		superctl start sxmo-x11-status
		;;
esac

if [ -f "${SXMO_MMS_BASE_DIR:-"$HOME"/.mms/modemmanager}/mms" ]; then
	superctl start mmsd
fi

if [ -f "${SXMO_VVM_BASE_DIR:-"$HOME"/.vvm/modemmanager}/vvm" ]; then
	superctl start mmsd
fi

# Start the desktop widget (e.g. clock)
superctl start sxmo_desktop_widget

# Periodically update some status bar components
sxmo_hook_statusbar.sh all
sxmo_daemons.sh start statusbar_periodics sxmo_run_periodically.sh 55 \
	sxmo_hook_statusbar.sh periodics

# Monitor the battery
superctl start sxmo_battery_monitor

# It watch network changes and update the status bar icon by example
superctl start sxmo_networkmonitor

# The daemon that display notifications popup messages
superctl start sxmo_notificationmonitor

# To setup initial lock state
sxmo_hook_unlock.sh

superctl start pipewire
superctl start pipewire-pulse
superctl start wireplumber

# Verify modemmanager and eg25-manager are running
if ! sxmo_modemdaemons.sh status; then
	sxmo_notify_user.sh --urgency=critical "Warning! Modem daemons are not running."
else

	(
		sleep 5 # let some time to pipewire
		superctl start callaudiod

		# Turn on the dbus-monitors for modem-related tasks
		sxmo_daemons.sh start modem_monitor sxmo_modemmonitor.sh
	) &

	# Prevent crust for 120s if this is a reboot (uptime < 3mins)
	if [ "$(cut -d '.' -f1 < /proc/uptime)" -lt 180 ]; then
		sxmo_daemons.sh start modem_nocrust sleep 120
	fi
fi

sxmo_migrate.sh state || sxmo_notify_user.sh --urgency=critical \
	"Config needs migration" "$? file(s) in your sxmo configuration are out of date and disabled - using defaults until you migrate (run sxmo_migrate.sh)"
