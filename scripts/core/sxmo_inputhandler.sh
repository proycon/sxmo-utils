#!/usr/bin/env sh

# This script handles input actions, it is called by lisgd for gestures
# and by dwm for button presses

ACTION="$1"

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

lock_screen() {
	if [ "$SXMO_LOCK_SCREEN_OFF" = "1" ]; then
		sxmo_screenlock.sh off
	else
		sxmo_screenlock.sh lock
	fi
	if [ "$SXMO_LOCK_SUSPEND" = "1" ]; then
		sxmo_screenlock.sh crust
	fi
}

key() {
	xdotool windowactivate "$WIN"
	xdotool key --delay 50 --clearmodifiers "$@"
}

type() {
	xdotool windowactivate "$WIN"
	xdotool type --delay 50 --clearmodifiers "$@"
}

typeenter() {
	type "$@"
	xdotool key Return
}

if [ "$(sxmo_screenlock.sh getCurState)" != "unlock" ]; then
	case "$ACTION" in
		"volup_three")
			sxmo_screenlock.sh crust
			;;
		"voldown_three")
			if [ "$(sxmo_screenlock.sh getCurState)" = "lock" ]; then
				sxmo_screenlock.sh off
			else
				lock_screen
			fi
			;;
		"powerbutton_three")
			sxmo_screenlock.sh unlock
			;;
	esac
	exit
fi

XPROPOUT="$(xprop -id "$(xdotool getactivewindow)")"
WMCLASS="$(echo "$XPROPOUT" | grep WM_CLASS | cut -d ' ' -f3-)"
WMNAME=$(echo "$XPROPOUT" | grep -E "^WM_NAME" | cut -d ' ' -f3-)

if [ -x "$XDG_CONFIG_HOME"/sxmo/hooks/inputhandler ]; then
	#hook script must exit with a zero exit code ONLY if it has handled the gesture!
	"$XDG_CONFIG_HOME"/sxmo/hooks/inputhandler "$WMCLASS" "$WMNAME" "$@" && exit
fi

#special context-sensitive handling
case "$WMCLASS" in
	*"st-256color"*)
		# First we try to handle the app running inside st:
		case "$WMNAME" in
			*"tuir"*)
				if [ "$ACTION" = "rightbottomcorner" ]; then
					type o
					exit 0
				elif [ "$ACTION" = "leftbottomcorner" ]; then
					type s
					exit 0
				fi
				;;
			*"less"*)
				case "$ACTION" in
					"leftbottomcorner")
						type q
						exit 0
						;;
					"leftrightcorner_short")
						type q
						exit 0
						;;
					*"onedown")
						type u
						exit 0
						;;
					*"oneup")
						type  d
						exit 0
						;;
					*"oneleft")
						typeenter ":n"
						exit 0
						;;
					*"oneright")
						typeenter ":p"
						exit 0
						;;
				esac
				;;
			*"amfora"*)
				case "$ACTION" in
					"downright")
						key Tab
						exit 0
						;;
					"upleft")
						key Shift+Tab
						exit 0
						;;
					*"onedown")
						key u
						exit 0
						;;
					*"oneup")
						key d
						exit 0
						;;
					*"oneright")
						key Return
						exit 0
						;;
					"upright")
						key Ctrl+t
						exit 0
						;;
					*"oneleft")
						key b
						exit 0
						;;
					"downleft")
						key Ctrl+w
						exit 0
						;;
				esac
				;;
		esac
		# Now we try generic st actions
		case "$ACTION" in
			*"onedown")
				key Ctrl+Shift+B
				exit 0
				;;
			*"oneup")
				key Ctrl+Shift+F
				exit 0
				;;
		esac
esac

#standard handling
case "$ACTION" in
	"rightleftcorner")
		key Super+Shift+e
		exit 0
		;;
	"leftrightcorner")
		key Super+Shift+r
		exit 0
		;;
	"twoleft") # Move window previous
		key Super+e
		exit 0
		;;
	"tworight") # Move window next
		key Super+r
		exit 0
		;;
	"unmute")
		sxmo_vol.sh unmute &
		exit 0
		;;
	"mute")
		sxmo_vol.sh mute &
		exit 0
		;;
	"righttopcorner")
		sxmo_brightness.sh up &
		exit 0
		;;
	"lefttopcorner")
		sxmo_brightness.sh down &
		exit 0
		;;
	"upleftcorner")
		sxmo_vol.sh up &
		exit 0
		;;
	"downleftcorner")
		sxmo_vol.sh down &
		exit 0
		;;
	"upbottomcorner")
		sxmo_keyboard.sh open
		exit 0
		;;
	"downbottomcorner")
		sxmo_keyboard.sh close
		exit 0
		;;
	"downtopcorner")
		pidof dmenu || setsid -f sxmo_appmenu.sh &
		exit 0
		;;
	"twodowntopcorner")
		pidof dmenu || setsid -f sxmo_appmenu.sh sys &
		exit 0
		;;
	"uptopcorner")
		pkill -9 dmenu
		dunstctl close-all
		exit 0
		;;
	"twodownbottomcorner")
		sxmo_killwindow.sh
		exit 0
		;;
	"uprightcorner")
		xdotool key Up
		exit 0
		;;
	"downrightcorner")
		xdotool key Down
		exit 0
		;;
	"leftrightcorner_short")
		xdotool key Left
		exit 0
		;;
	"rightrightcorner_short")
		xdotool key Right
		exit 0
		;;
	"rightbottomcorner")
		xdotool key Return
		exit 0
		;;
	"leftbottomcorner")
		xdotool key BackSpace
		exit 0
		;;
	"powerbutton_one")
		if echo "$WMCLASS" | grep -i "megapixels"; then
			key "space"
		else
			sxmo_keyboard.sh toggle
		fi
		exit 0
		;;
	"powerbutton_two")
		sxmo_blinkled.sh blue && $TERMCMD "$SHELL"
		exit 0
		;;
	"powerbutton_three")
		sxmo_blinkled.sh blue && $BROWSER
		exit 0
		;;
	"volup_one")
		sxmo_appmenu.sh
		exit 0
		;;
	"volup_two")
		sxmo_appmenu.sh sys
		exit 0
		;;
	"volup_three")
		lock_screen
		exit 0
		;;
	"voldown_one")
		key Super+space
		exit 0
		;;
	"voldown_two")
		key Super+Return
		exit 0
		;;
	"voldown_three")
		sxmo_blinkled.sh red && sxmo_killwindow.sh
		exit 0
		;;
	"topleftcorner")
		sxmo_appmenu.sh sys &
		exit 0
		;;
	"toprightcorner")
		sxmo_appmenu.sh scripts &
		exit 0
		;;
	"bottomleftcorner")
		lock_screen
		exit 0
		;;
	"bottomrightcorner")
		sxmo_rotate.sh &
		exit 0
		;;
esac
