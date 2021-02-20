#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/lock" ]; then
	"$XDG_CONFIG_HOME/sxmo/hooks/lock"
fi
pkill -9 lisgd
sxmo_screenlock "$@"
sxmo_lisgdstart.sh &
if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/unlock" ]; then
	"$XDG_CONFIG_HOME/sxmo/hooks/unlock"
fi
