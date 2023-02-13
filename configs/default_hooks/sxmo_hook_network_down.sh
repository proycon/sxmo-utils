#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2023 Sxmo Contributors

# This is called when any network goes down.
# $1 = device name (eg. wlan0)
# $2 = device type (eg. wifi)

# Some examples:

# Notify the user when a network goes down.
# sxmo_notify_user.sh "$2 ($1) down."

# Toggle the data connection when wifi goes down.
#if [ "$2" = "wifi" ]; then
#	nmcli c down MYMINT
#	nmcli c up MYMINT
#fi
