#!/bin/sh
# scrot refuses to work with double quotes
# shellcheck disable=SC2016

set -e

exitMsg() {
	printf "%s\n" "$1" > /dev/stderr
	notify-send "$1"
	exit 1
}

commandExists() {
	command -v "$1" > /dev/null
}

swayscreenshot() {
	commandExists grim || exitMsg "grim command must be available to take a screenshot."

	if [ "$1" = selection ]; then
		commandExists slurp || exitMsg "slurp command must be available to make a selection."
		notify-send "select an area"
		set -- grim -g "$(slurp)"
	else
		set -- grim
	fi

	"$@" "$FILENAME"
}

xorgscreenshot() {
	commandExists scrot || exitMsg "scrot command must be available to take a screenshot"
	if [ "$1" = "selection" ]; then
		notify-send 'select an area'
		set -- scrot -d 1 -q 1 -s
	else
		set -- scrot -d 1 -q 1
	fi

	"$@" "$FILENAME"
}

screenshot() {
	case "$SXMO_WM" in
		sway)
			swayscreenshot "$@"
			;;
		dwm)
			xorgscreenshot "$@"
			;;
		*)
			exitMsg "We dont know the WM, cannot screenshot."
			;;
	esac
}

filepathoutput() {
	printf %s "$FILENAME"
	case "$SXMO_WM" in
		sway)
			wl-copy "$FILENAME"
			;;
		dwm)
			printf %s "$FILENAME" | xsel -b -i
			;;
	esac
}

FILENAME="${SXMO_SCREENSHOT_DIR:-$HOME/$(date +%Y-%m-%d-%T).png}"

screenshot "$@"
filepathoutput
