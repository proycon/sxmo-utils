#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script is meant to be sourced on login shells
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

_sxmo_is_running() {
	unset SXMO_WM

	_XDG_RUNTIME_DIR="$(_sxmo_find_runtime_dir)"

	if [ -f "${_XDG_RUNTIME_DIR}"/sxmo.swaysock ]; then
		if SWAYSOCK="$(cat "${_XDG_RUNTIME_DIR}"/sxmo.swaysock)" swaymsg 2>/dev/null
		then
			printf "Detected the Sway environment\n" >&2
			export SXMO_WM=sway
			unset _XDG_RUNTIME_DIR
			return 0
		fi
	fi
	unset _XDG_RUNTIME_DIR

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

	# Try something existing
	for root in /run /var/run; do
		path="$root/user/$(id -u)"
		if [ -d "$path" ] && [ -w "$path" ]; then
			printf %s "$path"
			return
		fi
	done

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

	export BEMENU_OPTS="${BEMENU_OPTS:---ab "#222222" --af "#bbbbbb" --bdr "#005577" --border 3 --cb "#222222" --center --cf "#bbbbbb" --fb "#222222" --fbb "#eeeeee" --fbf "#222222" --ff "#bbbbbb" --fixed-height --fn 'Sxmo 14' --hb "#005577" --hf "#eeeeee" --line-height 20 --list 16 --margin 40 --nb "#222222" --nf "#bbbbbb" --no-overlap --no-spacing --sb "#323232" --scb "#005577" --scf "#eeeeee" --scrollbar autohide --tb "#005577" --tf "#eeeeee" --wrap}"

	export EDITOR="${EDITOR:-vim}"
	export BROWSER="${BROWSER:-firefox}"
	export SHELL="${SHELL:-/bin/sh}"

	# The user can already force a $SXMO_DEVICE_NAME value in ~/.profile
	if [ -z "$SXMO_DEVICE_NAME" ]; then
		if [ -e /proc/device-tree/compatible ]; then
			SXMO_DEVICE_NAME="$(tr -c '\0[:alnum:].,-' '_' < /proc/device-tree/compatible |
				tr '\0' '\n' | head -n1)"
		else
			SXMO_DEVICE_NAME=desktop
		fi
	fi
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
	fi
	unset deviceprofile

	PATH="\
$XDG_CONFIG_HOME/sxmo/hooks/$SXMO_DEVICE_NAME:\
$XDG_CONFIG_HOME/sxmo/hooks:\
$(xdg_data_path "sxmo/default_hooks" 0 ':'):\
$PATH"
	export PATH
}

_sxmo_grab_session() {
	if ! _sxmo_is_running; then
		return
	fi

	XDG_RUNTIME_DIR="$(_sxmo_find_runtime_dir)"
	export XDG_RUNTIME_DIR

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
	uid=$(id -u)
	gid=$(id -g)
	mkdir -p "$XDG_RUNTIME_DIR"
	chmod 700 "$XDG_RUNTIME_DIR"
	chown "$uid:$gid" "$XDG_RUNTIME_DIR"

	mkdir -p "$XDG_CACHE_HOME/sxmo/"
	chmod 700 "$XDG_CACHE_HOME"
	chown "$uid:$gid" "$XDG_CACHE_HOME"

	mkdir -p "$XDG_STATE_HOME"
	chmod 700 "$XDG_STATE_HOME"
	chown "$uid:$gid" "$XDG_STATE_HOME"
}

_sxmo_grab_session
