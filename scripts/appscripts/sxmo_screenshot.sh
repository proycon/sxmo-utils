#!/usr/bin/env sh
# scrot refuses to work with double quotes
# shellcheck disable=SC2016

if [ "$1" = "selection" ]; then
	notify-send "select an area" && scrot -e 'echo $f | xsel -i -b' -d 1 -s -q 1 && notify-send "screenshot saved, filename copied to clipboard"
else
	scrot -e 'echo $f | xsel -i -b' -d 1 -q 1 && notify-send "screenshot saved, filename copied to clipboard"
fi
