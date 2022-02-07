#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

xorgdpms() {
	STATE=off
	if xset q | grep -q "Off: 3"; then
		STATE=on
	fi

	if [ -z "$1" ]; then
		printf %s "$STATE"
	elif [ "$1" = on ] && [ "$STATE" != on ]; then
		xset dpms 0 0 3
		xset dpms force off
	elif [ "$1" = off ] && [ "$STATE" != off ]; then
		xset dpms 0 0 0
		xset dpms force on
	fi
}

swaydpms() {
	monitor="${SXMO_MONITOR:-"DSI-1"}"
	STATE=off
	if swaymsg -t get_outputs \
		| jq ".[] | select(.name == \"$monitor\") | .dpms" \
		| grep -q "false"; then
		STATE=on
	fi

	if [ -z "$1" ]; then
		printf %s "$STATE"
	elif [ "$1" = on ] && [ "$STATE" != on ]; then
		swaymsg -- output "$monitor" dpms false
	elif [ "$1" = off ] && [ "$STATE" != off ] ; then
		swaymsg -- output "$monitor" dpms true
	fi

}

xorginputevent() {
	if [ "$1" = "touchscreen" ]; then
		TOUCH_POINTER_ID="${SXMO_TOUCHSCREEN_ID:-8}"
	elif [ "$1" = "stylus" ]; then
		TOUCH_POINTER_ID="${SXMO_STYLUS_ID:-0}"
	fi

	STATE=off
	if xinput list-props "$TOUCH_POINTER_ID" | \
		grep "Device Enabled" | \
		grep -q "1$"; then
		STATE=on
	fi

	if [ -z "$2" ]; then
		printf %s "$STATE"
	elif [ "$2" = on ] && [ "$STATE" != on ]; then
		xinput enable "$TOUCH_POINTER_ID"
	elif [ "$2" = off ] && [ "$STATE" != off ] ; then
		xinput disable "$TOUCH_POINTER_ID"
	fi
}

swayinputevent() {
	if [ "$1" = "touchscreen" ]; then
		TOUCH_POINTER_ID="touch"
	elif [ "$1" = "stylus" ]; then
		TOUCH_POINTER_ID="tablet_tool"
	fi

	STATE=on
	if swaymsg -t get_inputs \
		| jq -r ".[] | select(.type == \"$TOUCH_POINTER_ID\" ) | .libinput.send_events" \
		| grep -q "disabled"; then
		STATE=off
	fi

	if [ -z "$2" ]; then
		printf %s "$STATE"
	elif [ "$2" = on ] && [ "$STATE" != on ]; then
		swaymsg -- input type:"$TOUCH_POINTER_ID" events enabled
	elif [ "$2" = off ] && [ "$STATE" != off ] ; then
		swaymsg -- input type:"$TOUCH_POINTER_ID" events disabled
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
	if [ -z "$DISPLAY" ]; then
		export DISPLAY=:0
	fi
	"$@" &
}

xorgexecwait() {
	if [ -z "$DISPLAY" ]; then
		export DISPLAY=:0
	fi
	exec "$@"
}

swaytogglelayout() {
	swaymsg layout toggle splith splitv tabbed
}

xorgtogglelayout() {
	if [ -z "$DISPLAY" ]; then
		export DISPLAY=:0
	fi
	xdotool key --clearmodifiers key Super+space
}

swayswitchfocus() {
	sxmo_wmmenu.sh swaywindowswitcher
}

xorgswitchfocus() {
	if [ -z "$DISPLAY" ]; then
		export DISPLAY=:0
	fi
	xdotool key --clearmodifiers Super+x
}

_swaygetcurrentworkspace() {
	swaymsg -t get_outputs  | \
		jq -r '.[] | select(.focused) | .current_workspace'
}

_swaygetnextworkspace() {
	value="$(($(_swaygetcurrentworkspace)+1))"
	if [ "$value" -eq "$((${SXMO_WORKSPACE_WRAPPING:-4}+1))" ]; then
		printf 1
	else
		printf %s "$value"
	fi
}

_swaygetpreviousworkspace() {
	value="$(($(_swaygetcurrentworkspace)-1))"
	if [ "$value" -lt 1 ]; then
		if [ "${SXMO_WORKSPACE_WRAPPING:-4}" -ne 0 ]; then
			printf %s "${SXMO_WORKSPACE_WRAPPING:-4}"
		else
			return 1 # cant have previous workspace
		fi
	else
		printf %s "$value"
	fi
}

swaynextworkspace() {
	swaymsg "workspace $(_swaygetnextworkspace)"
}

xorgnextworkspace() {
	if [ -z "$DISPLAY" ]; then
		export DISPLAY=:0
	fi
	xdotool key --clearmodifiers Super+Shift+r
}

swaypreviousworkspace() {
	_swaygetpreviousworkspace | xargs -r swaymsg -- workspace
}

xorgpreviousworkspace() {
	if [ -z "$DISPLAY" ]; then
		export DISPLAY=:0
	fi
	xdotool key --clearmodifiers Super+Shift+e
}

swaymovenextworkspace() {
	swaymsg "move container to workspace $(_swaygetnextworkspace)"
}

xorgmovenextworkspace() {
	if [ -z "$DISPLAY" ]; then
		export DISPLAY=:0
	fi
	xdotool key --clearmodifiers Super+r
}

swaymovepreviousworkspace() {
	_swaygetpreviousworkspace | xargs -r swaymsg -- move container to workspace
}

xorgmovepreviousworkspace() {
	if [ -z "$DISPLAY" ]; then
		export DISPLAY=:0
	fi
	xdotool key --clearmodifiers Super+e
}

swayworkspace() {
	swaymsg "workspace $1"
}

xorgworkspace() {
	if [ -z "$DISPLAY" ]; then
		export DISPLAY=:0
	fi
	xdotool key --clearmodifiers "Super+$1"
}

swaymoveworkspace() {
	swaymsg "move container to workspace $1"
}

xorgmoveworkspace() {
	if [ -z "$DISPLAY" ]; then
		export DISPLAY=:0
	fi
	xdotool key --clearmodifiers "Super+shift+$1"
}

swaytogglebar() {
	swaymsg bar mode toggle
}

xorgtogglebar() {
	if [ -z "$DISPLAY" ]; then
		export DISPLAY=:0
	fi
	xdotool key --clearmodifiers "Super+b"
}

action="$1"
shift
case "$SXMO_WM" in
	dwm) "xorg$action" "$@";;
	*) "$SXMO_WM$action" "$@";;
esac
