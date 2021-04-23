#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

finish() {
	kill "$LOCKPID"
}
trap 'finish' TERM INT

if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/lock" ]; then
	"$XDG_CONFIG_HOME/sxmo/hooks/lock"
fi
pkill -9 lisgd
sxmo_screenlock "$@" &
LOCKPID="$!"
wait $LOCKPID
[ "$(xrandr  | grep DSI-1  | cut -d ' ' -f 5)" = "right" ] && ORIENTATION=1 || ORIENTATION=0
sxmo_lisgdstart.sh -o $ORIENTATION &
if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/unlock" ]; then
	"$XDG_CONFIG_HOME/sxmo/hooks/unlock"
fi
