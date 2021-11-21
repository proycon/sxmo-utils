#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

TOUCH_POINTER_ID="${TOUCH_POINTER_ID:-"8"}"

xorgdpms() {
	STATE=off
	if xset q | grep -q "Off: 3"; then
		STATE=on
	fi

	if [ "$1" = on ] && [ "$STATE" != on ]; then
		xset dpms 0 0 3
		xset dpms force off
	elif [ "$1" = off ] && [ "$STATE" != off ] ; then
		xset dpms 0 0 0
		xset dpms force on
	else
		printf %s "$STATE"
	fi
}

swaydpms() {
	STATE=off
	if swaymsg -t get_outputs \
		| jq '.[] | select(.name == "DSI-1") | .dpms' \
		| grep -q "false"; then
		STATE=on
	fi

	if [ "$1" = on ] && [ "$STATE" != on ]; then
		swaymsg -- output DSI-1 dpms false
	elif [ "$1" = off ] && [ "$STATE" != off ] ; then
		swaymsg -- output DSI-1 dpms true
	else
		printf %s "$STATE"
	fi
}

xorginputevent() {
	STATE=off
	if xinput list-props "$TOUCH_POINTER_ID" | \
		grep "Device Enabled" | \
		grep -q "1$"; then
		STATE=on
	fi

	if [ "$1" = on ] && [ "$STATE" != on ]; then
		xinput enable "$TOUCH_POINTER_ID"
	elif [ "$1" = off ] && [ "$STATE" != off ] ; then
		xinput disable "$TOUCH_POINTER_ID"
	else
		printf %s "$STATE"
	fi
}

swayinputevent() {
	STATE=on
	if swaymsg -t get_inputs \
		| jq -r '.[] | select(.type == "touch" ) | .libinput.send_events' \
		| grep -q "disabled"; then
		STATE=off
	fi

	if [ "$1" = on ] && [ "$STATE" != on ]; then
		swaymsg -- input type:touch events enabled
	elif [ "$1" = off ] && [ "$STATE" != off ] ; then
		swaymsg -- input type:touch events disabled
	else
		printf %s "$STATE"
	fi
}

xorgfocusedwindow() {
	activeoutput="$(xprop -id "$(xdotool getactivewindow 2>/dev/null)" 2>/dev/null)"
	printf %s "$activeoutput" | \
		grep ^WM_CLASS | cut -d" " -f3- | cut -d"," -f1 | \
		xargs printf 'app: %s'
	printf "\n"
	printf %s "$activeoutput" | \
		grep ^WM_NAME | cut -d" " -f3- | cut -d"," -f1 |
		xargs printf 'title: %s'
}

swayfocusedwindow() {
	swaymsg -t get_tree \
		| jq -r '
			recurse(.nodes[]) |
			select(.focused == true) |
			{app_id: .app_id, name: .name} |
			"app: " + .app_id, "title: " + .name
		'
}

swayexec() {
	swaymsg exec -- "$@"
}

swayexecwait() {
	PIDFILE="$(mktemp)"
	printf '"%s" & printf %%s "$!" > "%s"' "$*" "$PIDFILE" \
		| xargs swaymsg exec -- sh -c
	while : ; do
		sleep 0.5
		kill -0 "$(cat "$PIDFILE")" 2> /dev/null || break
	done
	rm "$PIDFILE"
}

xorgexec() {
	"$@" &
}

xorgexecwait() {
	exec "$@"
}

swaytogglelayout() {
	swaymsg layout toggle splith splitv tabbed
}

xorgtogglelayout() {
	xdotool key --clearmodifiers key Super+space
}

swayswitchfocus() {
	sxmo_sws.sh
}

xorgswitchfocus() {
	xdotool key --clearmodifiers Super+x
}

guesswm() {
	if [ -n "$SWAYSOCK" ]; then
		printf "sway"
	elif [ -n "$DISPLAY" ]; then
		printf "dwm"
	elif [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
		printf "ssh"
	else
		printf "none"
	fi
}

wm="$(guesswm)"

if [ -z "$1" ]; then
	printf %s "$wm"
	exit
fi

action="$1"
shift
case "$wm" in
	dwm|xorg) "xorg$action" "$@";;
	*) "$wm$action" "$@";;
esac
