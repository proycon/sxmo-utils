#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

set -e

LOCK=0
OFF=0
SUSPEND=0

readconfig() {
	if [ ! -f "$CACHEDIR"/sxmo.idle.state ]; then
		printf "LOCK 0\nOFF 0\nSUSPEND 0\n" >"$CACHEDIR"/sxmo.idle.state
	fi
	IDLE_STATE="$(cat "$CACHEDIR"/sxmo.idle.state)"

	LOCK="$(
		printf %s "$IDLE_STATE" |
			grep ^LOCK |
			cut -d' ' -f2
		)"

	OFF="$(
		printf %s "$IDLE_STATE" |
			grep ^OFF |
			cut -d' ' -f2
		)"

	SUSPEND="$(
		printf %s "$IDLE_STATE" |
			grep ^SUSPEND |
			cut -d' ' -f2
		)"
}

start() {
	if pgrep swayidle; then
		notify-send "Already running !"
		exit 1
	fi

	set --

	if [ "$LOCK" -gt 0 ]; then
		set -- "$@" timeout "$LOCK" "sxmo_screenlock.sh lock"
	fi

	if [ "$OFF" -gt 0 ]; then
		set -- "$@" timeout "$OFF" "sxmo_screenlock.sh off"
	fi

	if [ "$SUSPEND" -gt 0 ]; then
		set -- "$@" timeout "$SUSPEND" "sxmo_screenlock.sh off"
	fi

	if [ "$#" -eq 0 ]; then
		notify-send "Idle monitor disabled"
		exit 1
	fi

	exec swayidle "$@"
}

stop() {
	pkill swayidle || return 0
	sleep 1
}

configmenu() {
	PICKED="$(
		printf "LOCK %d\nOFF %d\nSUSPEND %d\n" "$LOCK" "$OFF" "$SUSPEND" | \
			sxmo_dmenu_with_kb.sh
	)"

	target="$(printf %s "$PICKED" | cut -d" " -f1)"
	old_value="$(printf %s "$PICKED" | cut -d" " -f2)"

	while [ -z "$new_value" ]; do
		new_value="$(
			printf "" | \
				sxmo_dmenu_with_kb.sh -p "New value"
		)"
		[ "$new_value" -gt 5 ] || unset new_value
	done

	sed -i "s|$target $old_value|$target $new_value|" "$CACHEDIR"/sxmo.idle.state
}

readconfig

action="${1:-start}"
case "$action" in
	start)
		start
		sleep 1
		if pgrep swayidle; then
			notify-send "Dpms Started"
		fi
		;;
	stop)
		stop
		sleep 1
		if ! pgrep swayidle; then
			notify-send "Dpms Stopped"
		fi
		;;
	restart)
		stop
		swaymsg exec "$(basename "$0")" start
		sleep 1
		if pgrep swayidle; then
			notify-send "Dpms Restarted"
		fi
		;;
	config)
		configmenu
		swaymsg exec "$(basename "$0")" restart
		;;
esac

