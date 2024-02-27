#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

envvars() {
	export SXMO_WM=dwm
	export XDG_CURRENT_DESKTOP=dwm
	# shellcheck disable=SC2086
	command -v $SXMO_TERMINAL "" >/dev/null || export SXMO_TERMINAL="st"
	command -v "$KEYBOARD" >/dev/null || defaultkeyboard
	[ -z "$MOZ_USE_XINPUT2" ] && export MOZ_USE_XINPUT2=1
}

defaults() {
	xmodmap "$(xdg_data_path sxmo/appcfg/xmodmap_caps_esc)"
	xsetroot -mod 29 29 -fg '#0b3a4c' -bg '#082430'
	xset s off -dpms
	[ -e "$HOME"/.Xresources ] && xrdb -merge "$HOME"/.Xresources
	SCREENWIDTH=$(xrandr | grep "Screen 0" | cut -d" " -f 8)
	SCREENHEIGHT=$(xrandr | grep "Screen 0" | cut -d" " -f 10 | tr -d ",")
	if [ "$SCREENWIDTH" -lt 1024 ] || [ "$SCREENHEIGHT" -lt 768 ]; then
		gsettings set org.gtk.Settings.FileChooser window-size "($SCREENWIDTH,$((SCREENHEIGHT / 2)))"
	fi
}

defaultkeyboard() {
	if command -v svkbd-mobile-intl >/dev/null; then
		export KEYBOARD=svkbd-mobile-intl
	elif command -v svkbd-mobile-plain >/dev/null; then
		export KEYBOARD=svkbd-mobile-plain
	else
		#legacy
		export KEYBOARD=svkbd-sxmo
	fi
}

with_dbus() {
	echo "$DBUS_SESSION_BUS_ADDRESS" > "$XDG_RUNTIME_DIR"/dbus.bus
	# shellcheck source=configs/appcfg/xinit_template
	. "$XDG_CONFIG_HOME"/sxmo/xinit
	exec dwm
}

cleanup() {
	sxmo_jobs.sh stop all
	pkill svkbd
	pkill dmenu
	pkill superd
}

# shellcheck source=scripts/core/sxmo_init.sh
. sxmo_init.sh
