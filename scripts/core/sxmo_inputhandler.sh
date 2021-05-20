#!/usr/bin/env sh

# This script handles input actions, it is called by lisgd for gestures
# and by dwm for button presses

ACTION="$1"

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

XPROPOUT="$(xprop -id "$(xdotool getactivewindow)")"
WMCLASS="$(echo "$XPROPOUT" | grep WM_CLASS | cut -d ' ' -f3-)"
WMNAME=$(echo "$XPROPOUT" | grep -E "^WM_NAME" | cut -d ' ' -f3-)

HANDLE=1
if [ -x "$XDG_CONFIG_HOME"/sxmo/hooks/inputhandler ]; then
	#hook script must exit with a zero exit code ONLY if it has handled the gesture!
	"$XDG_CONFIG_HOME"/sxmo/hooks/inputhandler "$WMCLASS" "$WMNAME" "$@"
	HANDLE=$?
fi

if [ "$HANDLE" -ne 0 ]; then
	#special context-sensitive handling
	case "$WMCLASS" in
		"foxtrotgps")
			# E.g. just a check to ignore 1-finger gestures in foxtrotgps
			if [ "$ACTION" != "killwindow" ]; then
				HANDLE=0
			fi
			;;
		"st-256color")
			# First we try to handle the app running inside st:
			if echo "$WMNAME" | grep -i -w tuir; then
				if [ "$ACTION" = "enter" ]; then
					xdotool key o
					HANDLE=0
				elif [ "$ACTION" = "back" ]; then
					xdotool key s
					HANDLE=0
				fi
			elif echo "$WMNAME" | grep -i -E -w "(less|mless)"; then
				if [ "$ACTION" = "back" ] || [ "$ACTION" = "scrollleft_short" ]; then
					xdotool key q
					HANDLE=0
				fi
			fi
			;;
	esac
fi

if [ "$HANDLE" -ne 0 ]; then
	#standard handling
	case "$ACTION" in
		"prevdesktop")
			xdotool key --clearmodifiers Super+Shift+e
			;;
		"nextdesktop")
			xdotool key --clearmodifiers Super+Shift+r
			;;
		"moveprevdesktop")
			xdotool key --clearmodifiers Super+e
			;;
		"movenextdesktop")
			xdotool key --clearmodifiers Super+r
			;;
		"unmute")
			sxmo_vol.sh unmute &
			;;
		"mute")
			sxmo_vol.sh mute &
			;;
		"brightnessup")
			sxmo_brightness.sh up &
			;;
		"brightnessdown")
			sxmo_brightness.sh down &
			;;
		"volup")
			sxmo_vol.sh up &
			;;
		"voldown")
			sxmo_vol.sh down &
			;;
		"showkeyboard")
			sxmo_keyboard.sh open
			;;
		"hidekeyboard")
			sxmo_keyboard.sh close
			;;
		"showmenu")
			pidof dmenu || setsid -f sxmo_appmenu.sh &
			;;
		"showsysmenu")
			pidof dmenu || setsid -f sxmo_appmenu.sh sys &
			;;
		"hidemenu")
			pkill -9 dmenu
			;;
		"closewindow")
			sxmo_killwindow.sh close
			;;
		"killwindow")
			sxmo_killwindow.sh
			;;
		"scrollup_long")
			xdotool key Prior
			;;
		"scrolldown_long")
			xdotool key Next
			;;
		"scrollup_med")
			xdotool key Up Up Up
			;;
		"scrolldown_med")
			xdotool key Down Down Down
			;;
		"scrollup_short")
			xdotool key Up
			;;
		"scrolldown_short")
			xdotool key Down
			;;
		"scrollleft_short")
			xdotool key Left
			;;
		"scrollright_short")
			xdotool key Right
			;;
		"enter")
			xdotool key Return
			;;
		"back")
			xdotool key BackSpace
			;;
		"powerbutton_one")
			if echo "$WMCLASS" | grep -i "megapixels"; then
				xdotool key --clearmodifiers "space"
			else
				sxmo_keyboard.sh toggle
			fi
			;;
		"powerbutton_two")
			sxmo_blinkled.sh blue && $TERMCMD -e "$SHELL"
			;;
		"powerbutton_three")
			sxmo_blinkled.sh blue && $BROWSER
			;;
		"volup_one")
			sxmo_appmenu.sh
			;;
		"volup_two")
			sxmo_appmenu.sh sys
			;;
		"volup_three")
			sxmo_lock.sh
			;;
		"voldown_one")
			xdotool key --clearmodifiers Super+space
			;;
		"voldown_two")
			xdotool key --clearmodifiers Super+Return
			;;
		"voldown_three")
			sxmo_blinkled.sh red && sxmo_killwindow.sh
			;;
		"voldown_four")
			sxmo_blinkled.sh red & sxmo_killwindow.sh close
			;;
		"topleftcorner")
			sxmo_appmenu.sh sys &
			;;
		"toprightcorner")
			sxmo_appmenu.sh scripts &
			;;
		"bottomleftcorner")
			sxmo_lock.sh &
			;;
		"bottomrightcorner")
			sxmo_rotate.sh &
			;;
		*)
			#fallback, just execute the command
			"$@"
			;;
	esac
fi
