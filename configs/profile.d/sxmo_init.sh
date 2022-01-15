#!/bin/sh

# This script is meant to be sourced on login shells

# we disable shellcheck SC2034 (variable not used)
# for all the variables we define here
# shellcheck disable=SC2034

# Determine current operating system see os-release(5)
# https://www.linux.org/docs/man5/os-release.html
if [ -e /etc/os-release ]; then
	# shellcheck source=/dev/null
	. /etc/os-release
elif [ -e /usr/lib/os-release ]; then
	# shellcheck source=/dev/null
	. /usr/lib/os-release
fi
export OS="${ID:-unknown}"

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/dev/shm/user/$(id -u)}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export NOTIFDIR="${XDG_DATA_HOME:-$HOME/.local/share}"/sxmo/notifications
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export CACHEDIR="$XDG_CACHE_HOME"/sxmo
export DEBUGLOG="$CACHEDIR/sxmo.log"
export LOGDIR="${XDG_DATA_HOME:-$HOME/.local/share}"/sxmo/modem
export BLOCKDIR="${XDG_DATA_HOME:-$HOME/.local/share}"/sxmo/block
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export CONTACTFILE="$XDG_CONFIG_HOME/sxmo/contacts.tsv"
export BLOCKFILE="$XDG_CONFIG_HOME/sxmo/block.tsv"
export UNSUSPENDREASONFILE="$XDG_RUNTIME_DIR/sxmo.suspend.reason"
export LASTSTATE="$XDG_RUNTIME_DIR/sxmo.suspend.laststate"

export BEMENU_OPTS='--fn "Monospace 14" --scrollbar autohide -s -n -w -c -l8 -M 40 -H 20'

device="$(cut -d ',' -f 2 < /sys/firmware/devicetree/base/compatible | tr -d '\0')"
deviceprofile="$(which "sxmo_deviceprofile_$device.sh")"
# shellcheck disable=SC1090
[ -f "$deviceprofile" ] && . "$deviceprofile"

sxmo_setup_wm() {
	if [ -f "$CACHEDIR"/dbus.bus ]; then
		DBUS_SESSION_BUS_ADDRESS="$(cat "$CACHEDIR"/dbus.bus)"
		export DBUS_SESSION_BUS_ADDRESS
		if ! dbus-send --dest=org.freedesktop.DBus \
			/org/freedesktop/DBus org.freedesktop.DBus.ListNames \
			2> /dev/null; then
				printf "dbus (%s) failed, unsetting...\n" "$DBUS_SESSION_BUS_ADDRESS" >&2
				unset DBUS_SESSION_BUS_ADDRESS
		fi
	else
		printf "no dbus cache file: %s/dbus.bus...\n" "$CACHEDIR" >&2
	fi

	if [ -f "$CACHEDIR"/sxmo.swaysock ]; then
		SWAYSOCK="$(cat "$CACHEDIR"/sxmo.swaysock)"
		export SWAYSOCK
		if swaymsg 2>/dev/null; then
			printf "Detected the Sway environment\n" >&2
			export SXMO_WM=sway
			return
		fi
		unset SWAYSOCK
	fi

	export DISPLAY=:0
	if xrandr >/dev/null 2>&1; then
		printf "Detected the Dwm environment\n" >&2
		export SXMO_WM=dwm
	fi
	unset DISPLAY
}

mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
chown "$USER:$USER" "$XDG_RUNTIME_DIR"

mkdir -p "$XDG_CACHE_HOME/sxmo/"
chmod 700 "$XDG_CACHE_HOME"
chown "$USER:$USER" "$XDG_CACHE_HOME"


# Maybe sxmo is already running ? (ssh, tty)
if [ -z "$SXMO_WM" ]; then
	sxmo_setup_wm
fi
