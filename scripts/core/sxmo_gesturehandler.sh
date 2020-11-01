#!/usr/bin/env sh
ACTION="$1"

XPROPOUT="$(xprop -id "$(xdotool getactivewindow)")"
WMCLASS="$(echo "$XPROPOUT" | grep WM_CLASS | cut -d ' ' -f3- | cut -d ' ' -f1 | tr -d '\",')"

HANDLE=1
if [ -x "$XDG_CONFIG_HOME"/sxmo/hooks/gesture ]; then
	#hook script must exit with a zero exit code ONLY if it has handled the gesture!
	"$XDG_CONFIG_HOME"/sxmo/hooks/gesture "$WMCLASS" "$@"
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
			WMNAME=$(echo "$XPROPOUT" | grep -E "^WM_NAME" | cut -d ' ' -f3-)
			if echo "$WMNAME" | grep -i -w tuir; then
				if [ "$ACTION" = "enter" ]; then
					xdotool key o
					HANDLE=0
				elif [ "$ACTION" = "back" ]; then
					xdotool key s
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
			xdotool key --clearmodifiers Alt+Shift+e
			;;
		"nextdesktop")
			xdotool key --clearmodifiers Alt+Shift+r
			;;
		"moveprevdesktop")
			xdotool key --clearmodifiers Alt+e
			;;
		"movenextdesktop")
			xdotool key --clearmodifiers Alt+r
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
			pidof "$KEYBOARD" || "$KEYBOARD" &
			;;
		"hidekeyboard")
			pkill -9 "$KEYBOARD"
			;;
		"showmenu")
			pidof dmenu || sxmo_appmenu.sh &
			;;
		"showsysmenu")
			sxmo_appmenu.sh sys &
			;;
		"hidemenu")
			pkill -9 dmenu
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
		*)
			#fallback, just execute the command
			"$@"
			;;
	esac
fi
