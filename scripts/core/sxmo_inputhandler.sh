#!/usr/bin/env sh

# This script handles input actions, it is called by lisgd for gestures
# and by dwm for button presses

ACTION="$1"

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

# this action will move the lock state $1 levels higher
lock_screen_action() {
	count="${1:-1}"

	state="$(sxmo_screenlock.sh getCurState)"
	while [ "$count" -gt 0 ]; do
		case "$state" in
			unlock)
				state=off
				;;
			off)
				state=lock
				;;
			lock)
				state=unlock
				;;
		esac
		count=$((count-1))
	done

	sxmo_screenlock.sh "$state"
}

XPROPOUT="$(sxmo_wm.sh focusedwindow)"
WMCLASS="$(printf %s "$XPROPOUT" | grep app: | cut -d" " -f2- | tr '[:upper:]' '[:lower:]')"
WMNAME="$(printf %s "$XPROPOUT" | grep title: | cut -d" " -f2- | tr '[:upper:]' '[:lower:]')"

if [ -x "$XDG_CONFIG_HOME"/sxmo/hooks/inputhandler ]; then
	#hook script must exit with a zero exit code ONLY if it has handled the gesture!
	"$XDG_CONFIG_HOME"/sxmo/hooks/inputhandler "$WMCLASS" "$WMNAME" "$@" && exit
fi

#special context-sensitive handling
case "$WMCLASS" in
	*"foot"*)
		# First we try to handle the app running inside st:
		case "$WMNAME" in
			*"tuir"*)
				if [ "$ACTION" = "rightbottomedge" ]; then
					sxmo_type.sh o
					exit 0
				elif [ "$ACTION" = "leftbottomedge" ]; then
					sxmo_type.sh s
					exit 0
				fi
				;;
			*"less"*)
				case "$ACTION" in
					"leftbottomedge")
						sxmo_type.sh q
						exit 0
						;;
					"leftrightedge_short")
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
			lock_screen_action
		fi
		exit 0
		;;
	"powerbutton_two")
		lock_screen_action 2
		exit 0
		;;
	"powerbutton_three")
		sxmo_terminal.sh
		exit 0
		;;
	"voldown_one")
		sxmo_keyboard.sh toggle
		exit
		;;
	"voldown_two")
		sxmo_wm.sh togglelayout
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
		sxmo_wm.sh switchfocus
		exit
		;;
	"rightleftedge")
		sxmo_workspace.sh previous
		exit 0
		;;
	"leftrightedge")
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
	"righttopedge")
		sxmo_brightness.sh up &
		exit 0
		;;
	"lefttopedge")
		sxmo_brightness.sh down &
		exit 0
		;;
	"upleftedge")
		sxmo_vol.sh up &
		exit 0
		;;
	"downleftedge")
		sxmo_vol.sh down &
		exit 0
		;;
	"upbottomedge")
		sxmo_keyboard.sh open
		exit 0
		;;
	"downbottomedge")
		sxmo_keyboard.sh close
		exit 0
		;;
	"downtopedge")
		sxmo_dmenu.sh isopen || sxmo_appmenu.sh &
		exit 0
		;;
	"twodowntopedge")
		sxmo_dmenu.sh isopen || sxmo_appmenu.sh sys &
		exit 0
		;;
	"uptopedge")
		sxmo_dmenu.sh close
		dunstctl close-all
		exit 0
		;;
	"twodownbottomedge")
		sxmo_killwindow.sh
		exit 0
		;;
	"uprightedge")
		sxmo_type.sh -k Up
		exit 0
		;;
	"downrightedge")
		sxmo_type.sh -k Down
		exit 0
		;;
	"leftrightedge_short")
		sxmo_type.sh -k Left
		exit 0
		;;
	"rightrightedge_short")
		sxmo_type.sh -k Right
		exit 0
		;;
	"rightbottomedge")
		sxmo_type.sh -k Return
		exit 0
		;;
	"leftbottomedge")
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
		sxmo_dmenu.sh close
		lock_screen
		exit 0
		;;
	"bottomrightcorner")
		sxmo_rotate.sh &
		exit 0
		;;
esac
