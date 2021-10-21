#!/usr/bin/env sh
# scrot refuses to work with double quotes
# shellcheck disable=SC2016

exitMsg(){
	echo "$1" > /dev/stderr
	notify-send "$1"
	exit 1
}

commandExists(){
	command -v "$1" 2>/dev/null
}

case "$(sxmo_wm.sh)" in
	sway)
		commandExists grim || exitMsg "grim command must be available to take a screenshot."
		FILENAME="$(date +%Y-%m-%d-%T)_grim.png"
		if [ "$1" = "selection" ]; then
			commandExists slurp || exitMsg "slurp command must be available to make a selection."
			COMMAND="notify-send 'select an area' && slurp | grim -g - ~/$FILENAME && (printf ~/$FILENAME | wl-copy)"
		else
			COMMAND="grim ~/$FILENAME && (printf ~/$FILENAME | wl-copy)"
		fi
		;;
	xorg|dwm)
		commandExists scrot || exitMsg "scrot command must be available to take a screenshot"
		f='$f'
		if [ "$1" = "selection" ]; then
			COMMAND="notify-send 'select an area' && scrot -e 'echo $f | xsel -i -b' -d 1 -s -q 1"
		else
			COMMAND="scrot -e 'echo $f | xsel -i -b' -d 1 -q 1"
		fi
		;;
	ssh)
		exitMsg "cannot screenshot ssh ;)"
		;;
esac


eval "$COMMAND" && notify-send "screenshot saved, filename copied to clipboard" && exit 0
exitMsg "Screenshot process failure."
