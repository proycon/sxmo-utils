#!/bin/sh

# This script is meant to be sourced on login shells

_sxmo_is_running() {
	unset SXMO_WM

	if [ -f "${XDG_RUNTIME_DIR:-/dev/shm/user/$(id -u)}"/sxmo.swaysock ]; then
		if SWAYSOCK="$(cat "${XDG_RUNTIME_DIR:-/dev/shm/user/$(id -u)}"/sxmo.swaysock)" \
			swaymsg 2>/dev/null; then
			printf "Detected the Sway environment\n" >&2
			export SXMO_WM=sway
			return 0
		fi
	fi

	if DISPLAY=:0 xrandr >/dev/null 2>&1; then
		printf "Detected the Dwm environment\n" >&2
		export SXMO_WM=dwm
		return 0
	fi

	printf "Sxmo is not running\n" >&2
	return 1
}

_sxmo_load_environments() {
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

	export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
	export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
	export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
	export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/dev/shm/user/$(id -u)}"

	export SXMO_CACHEDIR="$XDG_CACHE_HOME"/sxmo
	export SXMO_DEBUGLOG="${XDG_STATE_HOME:-$HOME/.local/state}/tinydm.log"

	export SXMO_BLOCKDIR="$XDG_DATA_HOME/sxmo/block"
	export SXMO_BLOCKFILE="$XDG_CONFIG_HOME/sxmo/block.tsv"
	export SXMO_CONTACTFILE="$XDG_CONFIG_HOME/sxmo/contacts.tsv"
	export SXMO_LASTSTATE="$XDG_RUNTIME_DIR/sxmo.suspend.laststate"
	export SXMO_LOGDIR="$XDG_DATA_HOME/sxmo/modem"
	export SXMO_NOTIFDIR="$XDG_DATA_HOME/sxmo/notifications"
	export SXMO_UNSUSPENDREASONFILE="$XDG_RUNTIME_DIR/sxmo.suspend.reason"

	export BEMENU_OPTS="${BEMENU_OPTS:---fn 'Monospace 14' --scrollbar autohide -s -n -w -c -l8 -M 40 -H 20}"

	export EDITOR="${EDITOR:-vis}"

	device="$(cut -d ',' -f 2 < /sys/firmware/devicetree/base/compatible | tr -d '\0')"
	deviceprofile="$(which "sxmo_deviceprofile_$device.sh")"
	# shellcheck disable=SC1090
	[ -f "$deviceprofile" ] && . "$deviceprofile"
}

_sxmo_check_and_move_config() {
	# if user needs to migrate configs, move them and alert the user
	REQUIRED_VER="$(cat /usr/share/sxmo/configversion)"

	# First start
	if ! [ -d "$XDG_CONFIG_HOME/sxmo" ]; then
		mkdir -p "$XDG_CONFIG_HOME/sxmo"
		printf %s "$REQUIRED_VER" > "$XDG_CONFIG_HOME/sxmo/.configversion"
		return
	fi

	if [ -f "$XDG_CONFIG_HOME/sxmo/.configversion" ]; then
		CUR_VER="$(cat "$XDG_CONFIG_HOME/sxmo/.configversion")"
	else
		CUR_VER="UNKNOWN"
	fi

	if [ "$REQUIRED_VER" != "$CUR_VER" ]; then
		mv "$XDG_CONFIG_HOME/sxmo" "$XDG_CONFIG_HOME/sxmo.old-$CUR_VER"
		mkdir -p "$XDG_CONFIG_HOME/sxmo"
		printf %s "$REQUIRED_VER" > "$XDG_CONFIG_HOME/sxmo/.configversion"
	fi
}

_sxmo_grab_session() {
	if ! _sxmo_is_running; then
		unset SWAYSOCK
		return
	fi

	_sxmo_load_environments

	if [ -f "$XDG_RUNTIME_DIR"/dbus.bus ]; then
		DBUS_SESSION_BUS_ADDRESS="$(cat "$XDG_RUNTIME_DIR"/dbus.bus)"
		export DBUS_SESSION_BUS_ADDRESS
		if ! dbus-send --dest=org.freedesktop.DBus \
			/org/freedesktop/DBus org.freedesktop.DBus.ListNames \
			2> /dev/null; then
				printf "WARNING: The dbus-send test failed with DBUS_SESSION_BUS_ADDRESS=%s. Unsetting...\n" "$DBUS_SESSION_BUS_ADDRESS" >&2
				unset DBUS_SESSION_BUS_ADDRESS
		fi
	else
		printf "WARNING: No dbus cache file found at %s/dbus.bus.\n" "$XDG_RUNTIME_DIR" >&2
	fi

	# We dont export DISPLAY and WAYLAND_DISPLAY on purpose
	case "$SXMO_WM" in
		sway)
			if [ -f "$XDG_RUNTIME_DIR"/sxmo.swaysock ]; then
				SWAYSOCK="$(cat "$XDG_RUNTIME_DIR"/sxmo.swaysock)"
				export SWAYSOCK
			fi
			;;
	esac
}

_sxmo_prepare_dirs() {
	mkdir -p "$XDG_RUNTIME_DIR"
	chmod 700 "$XDG_RUNTIME_DIR"
	chown "$USER:$USER" "$XDG_RUNTIME_DIR"

	mkdir -p "$XDG_CACHE_HOME/sxmo/"
	chmod 700 "$XDG_CACHE_HOME"
	chown "$USER:$USER" "$XDG_CACHE_HOME"
}

_sxmo_grab_session
