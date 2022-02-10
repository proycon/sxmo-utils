#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(which sxmo_common.sh)"

sxmo_log "transitioning to stage lock"
printf lock > "$SXMO_STATE"

# This hook is called when the system reaches a locked state
sxmo_led.sh blink blue &
LEDPID=$!

sxmo_wm.sh dpms off
[ -z "$SXMO_TOUCHSCREEN_ID" ] || sxmo_wm.sh inputevent touchscreen off
[ -z "$SXMO_STYLUS_ID" ] || sxmo_wm.sh inputevent stylus off
if [ -n "$SXMO_STYLUS_ID" ] || [ -n "$SXMO_TOUCHSCREEN_ID" ]; then
	sxmo_daemons.sh stop lisgd
fi

sxmo_hook_statusbar.sh state_change
sxmo_hook_statusbar.sh locked

wait "$LEDPID"

# Go to screenoff after 8 seconds of inactivity
if ! [ -e "$XDG_CACHE_HOME/sxmo/sxmo.noidle" ]; then
	sxmo_daemons.sh start idle_locker sxmo_idle.sh -w \
		timeout 8 "sxmo_hook_screenoff.sh"
fi

sxmo_daemons.sh signal desktop_widget -12
