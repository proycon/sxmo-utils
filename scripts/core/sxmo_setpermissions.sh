#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script is executed as root
# from the init process and sets
# some device-specific permissions

if [ -e /proc/device-tree/compatible ]; then
    device="$(tr -c '\0[:alnum:].,-' '_' < /proc/device-tree/compatible |
			tr '\0' '\n' | head -n1)"
	deviceprofile="$(command -v "sxmo_deviceprofile_$device.sh")"
	# shellcheck disable=SC1090
	[ -f "$deviceprofile" ] && . "$deviceprofile"
fi

# the defaults are best guesses
# users can override this in sxmo_deviceprofile_mydevice.sh
files="${SXMO_SYS_FILES:-"/sys/power/state /sys/power/mem_sleep /dev/rtc0"}"

for file in $files /sys/power/autosleep; do
    [ -e "$file" ] && chmod a+rw "$file"
done

chmod -R a+rw /sys/class/wakeup/*
