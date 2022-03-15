#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

FORK="$2"

if [ -n "$1" ]
then
	# E.g. passed liked: sxmo_urlhandler.sh http://foo.com
	URL="$1"
else
	if [ "$SXMO_WM" = "dwm" ]; then
		# Surf
		WINDOW="$(xprop -root | sed -n '/^_NET_ACTIVE_WINDOW/ s/.* //p')"
		SURFURL="$(xprop -id "$WINDOW" | grep URI | awk '{print $3}' | sed 's/\"//g')"
		if [ -n "$SURFURL" ]; then
			URL="$SURFURL"
		fi
	fi

	# Is normal browser? (FF or Netsurf) - use Ctrl-L Ctrl-C to copy URL
	if sxmo_wm.sh focusedwindow | grep -i -E '(netsurf|firefox)'; then
		sxmo_type.sh -M Ctrl l
		sleep 0.3
		sxmo_type.sh -M Ctrl c
		sleep 0.3

		URL="$(sxmo_wm.sh paste)"
	fi
fi

COMMAND="$(
	echo "
		Close Menu
		$(command -v w3m        >/dev/null && echo 'w3m URL')
		$(command -v mpv        >/dev/null && echo 'mpv -v URL')
		$(command -v mpv        >/dev/null && echo 'mpv -v --ytdl-format="[height<420]" URL')
		$(command -v firefox    >/dev/null && echo 'firefox -new-window URL')
		$(command -v netsurf    >/dev/null && echo 'netsurf URL')
		$(command -v surf       >/dev/null && echo 'surf URL')
		$(command -v echo       >/dev/null && echo 'echo URL | xsel -i')
		$(command -v youtube-dl >/dev/null && echo 'youtube-dl -o- URL | mpv -ao=alsa -v -')
		$(command -v youtube-dl >/dev/null && echo 'youtube-dl URL')
		$(command -v curl       >/dev/null && echo "curl URL | $EDITOR -")
		$(command -v wget       >/dev/null && echo 'wget URL')
		$(command -v aria2c     >/dev/null && echo 'aria2c URL')
	" |
		sed "s/URL/'URL'/g" |
		sed -e '/^\s*$/d' |
		sed -e 's/^\s*//' |
		sxmo_dmenu.sh -p "Pipe URL"
)"

if [ -z "$COMMAND" ] || [ "$COMMAND" = "Close Menu" ]; then
	exit 0
fi

# TODO: a malformed url here will lead to code injection
RUN=$(echo "$URL" | xargs -IURL echo "$COMMAND")
if [ "$FORK" = fork ]; then
	sxmo_terminal.sh sh -c "$RUN" &
else
	sxmo_terminal.sh sh -c "$RUN"
fi
