#!/bin/sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

current() {
	swaymsg -t get_outputs  | \
		jq -r '.[] | select(.focused == true) | .current_workspace'
}

next() {
	value="$(($(current)+1))"
	if [ "$value" -eq "$((${SXMO_WORKSPACE_WRAPPING:-4}+1))" ]; then
		printf 1
	else
		printf %s "$value"
	fi
}

previous() {
	value="$(($(current)-1))"
	if [ "$value" -lt 1 ]; then
		if [ "${SXMO_WORKSPACE_WRAPPING:-4}" -ne 0 ]; then
			printf %s "${SXMO_WORKSPACE_WRAPPING:-4}"
		fi
	else
		printf %s "$value"
	fi
}

sway() {
	case "$1" in
		next)
			printf "workspace "
			next;;
		previous)
			printf "workspace "
			previous;;
		move-next)
			printf "move container to workspace "
			next;;
		move-previous)
			printf "move container to workspace "
			previous;;
	esac | xargs swaymsg
}

dwm() {
	case "$1" in
		next)
			xdotool key --clearmodifiers Super+Shift+r
			;;
		previous)
			xdotool key --clearmodifiers Super+Shift+e
			;;
		move-next)
			xdotool key --clearmodifiers Super+r
			;;
		move-previous)
			xdotool key --clearmodifiers Super+e
			;;
	esac
}

"$SXMO_WM" "$@"
