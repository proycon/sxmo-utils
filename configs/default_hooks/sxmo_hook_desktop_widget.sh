#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This hook launches a desktop widget (e.g. a clock) (blocking)
# It could be used on Wayland

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

pangodraw() {
	date +"<big><big><b>%H</b>:%M</big></big>" #date with some pango markup syntax (https://docs.gtk.org/Pango/pango_markup.html)
	date +"<small><small>%a %d %b %Y</small></small>"

	# here you can output whatever you want to end up in the widget
	# make sure to use pango markup syntax if you want colours etc, ANSI is not supported by wayout
	# for instance, you can show details about the activated network connections:
	#nmcli -w 3 -c no -p -f DEVICE,STATE,NAME,TYPE con show | grep activated | sed 's/activated/   /' | sed '/^\s*$/d' 2> /dev/null
	# make sure to end with an empty line, to denote the end of data for wayout
	echo
}

trap 'kill -- $WAYOUT' TERM INT EXIT

# For wayland we use wayout:
(
	sleep 1 # wayout misses output sent to it as it's starting
	while : ; do
		pangodraw
		sxmo_aligned_sleep 60
	done
) | wayout --font "Sxmo" \
	--foreground-color "#ffffff" \
	--fontsize "60" \
	--height 500  \
	--feed-par &
WAYOUT="$!"
wait
