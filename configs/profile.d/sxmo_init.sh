#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script is meant to be sourced on login shells
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

_sxmo_is_running() {
	unset SXMO_WM

	if [ -f "${XDG_RUNTIME_DIR}"/sxmo.swaysock ]; then
		unset SWAYSOCK
		if SWAYSOCK="$(cat "${XDG_RUNTIME_DIR}"/sxmo.swaysock)" \
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

_sxmo_find_runtime_dir() {
	# Take what we gave to you
	if [ -n "$XDG_RUNTIME_DIR" ]; then
		printf %s "$XDG_RUNTIME_DIR"
		return
	fi

	if [ -d "/var/run/user/$(id -u)" ]; then
		printf "/var/run/user/%s" "$(id -u)"
		return
	fi

	# Fallback to a shared memory location
	printf "/dev/shm/user/%s" "$(id -u)"
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
	export SXMO_OS="${ID:-unknown}"

	export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
	export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
	export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
	XDG_RUNTIME_DIR="$(_sxmo_find_runtime_dir)"
	export XDG_RUNTIME_DIR
	export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
	export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

	export SXMO_CACHEDIR="${SXMO_CACHEDIR:-$XDG_CACHE_HOME/sxmo}"

	export SXMO_BLOCKDIR="${SXMO_BLOCKDIR:-$XDG_DATA_HOME/sxmo/block}"
	export SXMO_BLOCKFILE="${SXMO_BLOCKFILE:-$XDG_CONFIG_HOME/sxmo/block.tsv}"
	export SXMO_CONTACTFILE="${SXMO_CONTACTFILE:-$XDG_CONFIG_HOME/sxmo/contacts.tsv}"
	export SXMO_STATE="${SXMO_STATE:-$XDG_RUNTIME_DIR/sxmo.state}"
	export SXMO_LOGDIR="${SXMO_LOGDIR:-$XDG_DATA_HOME/sxmo/modem}"
	export SXMO_NOTIFDIR="${SXMO_NOTIFDIR:-$XDG_DATA_HOME/sxmo/notifications}"
	export SXMO_UNSUSPENDREASONFILE="${SXMO_UNSUSPENDREASONFILE:-$XDG_RUNTIME_DIR/sxmo.suspend.reason}"

	export BEMENU_OPTS="${BEMENU_OPTS:---fn 'Sxmo 14' --scrollbar autohide -s -n -w -c -l8 -M 40 -H 20 --cb "#222222" --cf "#bbbbbb" --tb "#005577" --tf "#eeeeee" --fb "#222222" --ff "#bbbbbb" --nb "#222222" --af "#bbbbbb" --ab "#222222" --nf "#bbbbbb" --hb "#005577" --hf "#eeeeee" --scb "#005577" --scf "#eeeeee" --fbb "#eeeeee" --fbf "#222222"}"

	export EDITOR="${EDITOR:-vim}"
	export BROWSER="${BROWSER:-firefox}"
	export SHELL="${SHELL:-/bin/sh}"

	# The user can already forced a $SXMO_DEVICE_NAME value
	if [ -z "$SXMO_DEVICE_NAME" ] && [ -e /proc/device-tree/compatible ]; then
		SXMO_DEVICE_NAME="$(tr -c '\0[:alnum:].,-' '_' < /proc/device-tree/compatible |
			tr '\0' '\n' | head -n1)"
		export SXMO_DEVICE_NAME
		deviceprofile="$(command -v "sxmo_deviceprofile_$SXMO_DEVICE_NAME.sh")"
		# shellcheck disable=SC1090
		if [ -f "$deviceprofile" ]; then
			. "$deviceprofile"
			printf "deviceprofile file %s loaded.\n" "$deviceprofile"
		else
			printf "WARNING: deviceprofile file not found for %s. Most device functions will not work. Please read: https://sxmo.org/deviceprofile \n" "$SXMO_DEVICE_NAME"

			# on a new device, power button won't work
			# so make sure we don't go into screenoff
			# or suspend
			touch "$XDG_CACHE_HOME"/sxmo/sxmo.nosuspend
			touch "$XDG_CACHE_HOME"/sxmo/sxmo.noidle

			SXMO_DEVICE_NAME=unknown
		fi
		unset deviceprofile
	fi

	if [ -n "$SXMO_DEVICE_NAME" ]; then
		_device_hooks_path="$(xdg_data_path "sxmo/default_hooks/$SXMO_DEVICE_NAME" 0 ':')"
		if [ -z "$_device_hooks_path" ]; then
			_device_hooks_path="$(xdg_data_path "sxmo/default_hooks/three_button_touchscreen" 0 ':')"
		fi

		PATH="\
$XDG_CONFIG_HOME/sxmo/hooks/$SXMO_DEVICE_NAME:\
$XDG_CONFIG_HOME/sxmo/hooks:\
$_device_hooks_path:\
$(xdg_data_path "sxmo/default_hooks" 0 ':'):\
$PATH"
		export PATH
	else
		default_hooks_path=$(xdg_data_path sxmo/default_hooks 0 ':')
		export PATH="$XDG_CONFIG_HOME/sxmo/hooks:$default_hooks_path:$PATH"
	fi
}

_sxmo_grab_session() {
	XDG_RUNTIME_DIR="$(_sxmo_find_runtime_dir)"
	export XDG_RUNTIME_DIR
	if ! _sxmo_is_running; then
		unset XDG_RUNTIME_DIR
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
