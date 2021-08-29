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

XPROPOUT="$(sxmo_wm.sh focusedwindow)"
WMCLASS="$(printf %s "$XPROPOUT" | grep app: | cut -d" " -f2- | tr '[:upper:]' '[:lower:]')"
WMNAME="$(printf %s "$XPROPOUT" | grep title: | cut -d" " -f2- | tr '[:upper:]' '[:lower:]')"

if [ -x "$XDG_CONFIG_HOME"/sxmo/hooks/inputhandler ]; then
	#hook script must exit with a zero exit code ONLY if it has handled the gesture!
	"$XDG_CONFIG_HOME"/sxmo/hooks/inputhandler "$WMCLASS" "$WMNAME" "$@" && exit
fi

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

if sxmo_dmenu.sh isopen; then
	case "$ACTION" in
		"volup_one")
			sxmo_type.sh -k Up
			exit
			;;
		"voldown_one")
			sxmo_type.sh -k Down
			exit
			;;
		"powerbutton_one")
			sxmo_type.sh -k Return
			exit
			;;
	esac
fi

#special context-sensitive handling
case "$WMCLASS" in
	*"foot"*)
		# First we try to handle the app running inside st:
		case "$WMNAME" in
			*"tuir"*)
				if [ "$ACTION" = "rightbottomcorner" ]; then
					sxmo_type.sh o
					exit 0
				elif [ "$ACTION" = "leftbottomcorner" ]; then
					sxmo_type.sh s
					exit 0
				fi
				;;
			*"less"*)
				case "$ACTION" in
					"leftbottomcorner")
						sxmo_type.sh q
						exit 0
						;;
					"leftrightcorner_short")
						sxmo_type.sh q
						exit 0
						;;
					*"onedown")
						sxmo_type.sh u
						exit 0
						;;
					*"oneup")
						sxmo_type.sh d
						exit 0
						;;
					*"oneleft")
						sxmo_type.sh ":n" -k Return
						exit 0
						;;
					*"oneright")
						sxmo_type.sh ":p" -k Return
						exit 0
						;;
				esac
				;;
			*"amfora"*)
				case "$ACTION" in
					"downright")
						sxmo_type.sh -k Tab
						exit 0
						;;
					"upleft")
						sxmo_type.sh -M Shift -k Tab
						exit 0
						;;
					*"onedown")
						sxmo_type.sh u
						exit 0
						;;
					*"oneup")
						sxmo_type.sh d
						exit 0
						;;
					*"oneright")
						sxmo_type.sh -k Return
						exit 0
						;;
					"upright")
						sxmo_type.sh -M Ctrl t
						exit 0
						;;
					*"oneleft")
						sxmo_type.sh b
						exit 0
						;;
					"downleft")
						sxmo_type.sh -M Ctrl w
						exit 0
						;;
				esac
				;;
		esac
		# Now we try generic st actions
		case "$ACTION" in
			*"onedown")
				sxmo_type.sh -M Shift -k Page_Up
				exit 0
				;;
			*"oneup")
				sxmo_type.sh -M Shift -k Page_Down
				exit 0
				;;
		esac
esac

#standard handling
case "$ACTION" in
	"powerbutton_one")
		if echo "$WMCLASS" | grep -i "megapixels"; then
			sxmo_type.sh -k space
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
	"voldown_one")
		swaymsg layout toggle splith splitv tabbed
		exit
		;;
	"voldown_two")
		swaymsg focus tiling
		exit
		;;
	"voldown_three")
		sxmo_killwindow.sh
		exit
		;;
	"volup_one")
		sxmo_appmenu.sh
		exit
		;;
	"volup_two")
		sxmo_appmenu.sh sys
		exit
		;;
	"volup_three")
		lock_screen
		exit
		;;
	"rightleftcorner")
		sxmo_workspace.sh previous
		exit 0
		;;
	"leftrightcorner")
		sxmo_workspace.sh next
		exit 0
		;;
	"twoleft")
		sxmo_workspace.sh move-previous
		exit 0
		;;
	"tworight")
		sxmo_workspace.sh move-next
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
		sxmo_dmenu.sh isopen || sxmo_appmenu.sh &
		exit 0
		;;
	"twodowntopcorner")
		sxmo_dmenu.sh isopen || sxmo_appmenu.sh sys &
		exit 0
		;;
	"uptopcorner")
		sxmo_dmenu.sh close
		dunstctl close-all
		exit 0
		;;
	"twodownbottomcorner")
		sxmo_killwindow.sh
		exit 0
		;;
	"uprightcorner")
		sxmo_type.sh -k Up
		exit 0
		;;
	"downrightcorner")
		sxmo_type.sh -k Down
		exit 0
		;;
	"leftrightcorner_short")
		sxmo_type.sh -k Left
		exit 0
		;;
	"rightrightcorner_short")
		sxmo_type.sh -k Right
		exit 0
		;;
	"rightbottomcorner")
		sxmo_type.sh -k Return
		exit 0
		;;
	"leftbottomcorner")
		sxmo_type.sh -k BackSpace
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
		sxmo_dmenu.sh close && lock_screen
		exit 0
		;;
	"bottomrightcorner")
		sxmo_rotate.sh &
		exit 0
		;;
esac
