#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

FORK="$2"

if [ -n "$1" ]
then
	# E.g. passed liked: sxmo_urlhandler.sh http://foo.com
	URL="$1"
else
	# Surf
	WINDOW="$(xprop -root | sed -n '/^_NET_ACTIVE_WINDOW/ s/.* //p')"
	SURFURL="$(xprop -id "$WINDOW" | grep URI | awk '{print $3}' | sed 's/\"//g')"
	if [ -n "$SURFURL" ]; then
		URL="$SURFURL"
	fi

	# Is normal browser? (FF or Netsurf) - use Ctrl-L Ctrl-C to copy URL
	ISNORMBROWS="$(xprop -id "$(xdotool getactivewindow)" | grep -E 'WM_CLASS.*(Netsurf|Firefox)')"
	if [ -n "$ISNORMBROWS" ]; then
		xdotool key --clearmodifiers --delay 20 "ctrl+l" "ctrl+c"
		sleep 0.2
		URL="$(xclip -o)"
	fi
fi

COMMAND=$(
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
		dmenu -p "Pipe URL"
)

[ "$COMMAND" = "Close Menu" ] && exit 1
[ -z "$COMMAND" ] && exit 1
RUN=$(echo "$URL" | xargs -IURL echo "$COMMAND")
if [ "$FORK" = fork ]; then
	sxmo_terminal.sh sh -c "$RUN" &
else
	sxmo_terminal.sh sh -c "$RUN"
fi
