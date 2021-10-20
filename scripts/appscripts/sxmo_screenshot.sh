#!/usr/bin/env sh
# scrot refuses to work with double quotes
# shellcheck disable=SC2016


case "$(sxmo_wm.sh)" in
	sway)
		FILENAME="$(date +%Y-%m-%d-%T)_grim.png"
		SELECTION="slurp | grim -g - ~/$FILENAME"
		WHOLESCREEN="grim ~/$FILENAME"
		;;
	xorg|dwm)
		SELECTION="scrot -e 'echo $f | xsel -i -b' -d 1 -s -q 1"
		WHOLESCREEN="scrot -e 'echo $f | xsel -i -b' -d 1 -q 1"
		;;
	ssh)
		echo "cannot screenshot ssh ;)"
		exit 0
		;;
esac

if [ "$1" = "selection" ]; then
	notify-send "select an area" && eval "$SELECTION" && notify-send "screenshot saved, filename copied to clipboard"
else
	eval "$WHOLESCREEN" && notify-send "screenshot saved, filename copied to clipboard"
fi
