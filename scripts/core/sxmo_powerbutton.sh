#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/powerbutton" ]; then
	"$XDG_CONFIG_HOME/sxmo/hooks/powerbutton"
else
	XPROPOUT="$(xprop -id "$(xdotool getactivewindow)")"
	WMCLASS="${1:-$(echo "$XPROPOUT" | grep WM_CLASS | cut -d ' ' -f3-)}"
	if echo "$WMCLASS" | grep -i "megapixels"; then
		xdotool key --clearmodifiers "space"
	else
		sxmo_keyboard.sh toggle
	fi
fi
