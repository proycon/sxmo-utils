#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/powerbutton" ]; then
	"$XDG_CONFIG_HOME/sxmo/hooks/powerbutton"
else
	sxmo_keyboard.sh toggle
fi
