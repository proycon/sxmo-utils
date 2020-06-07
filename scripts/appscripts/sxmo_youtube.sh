#!/usr/bin/env sh
menu() {
	pidof svkbd-sxmo || svkbd-sxmo &
	SEARCHTERMS="$(
		echo "Search term" |
		dmenu -p "Yt Search" -c -l 10 -fn Terminus-20
	)"
	pkill svkbd-sxmo

	IDIOTRESULTS="$(youtube-cli "$SEARCHTERMS")"
	RESULT="$(
		echo "$IDIOTRESULTS" |
		grep -Ev '^(Channelid|Atom feed|Channel title|Published|Viewcount|Userid):' |
		sed -E 's/^(URL|Duration):\s+/\t/g' |
		tr -d '\n' |
		sed 's/===/\n/g' |
		gawk -F'\t' '{ print $3 " " $1 " " $2}' |
		dmenu -c -l 10 -fn Terminus-20
	)"

	[ "CLOSE_MENU" = "$RESULT" ] && exit 0
	URL=$(echo "$RESULT" | awk -F " " '{print $NF}')
}

video() {
	menu
	st -e mpv -v --ytdl-format='[height<420]' "$URL"
}

audio() {
	menu
	st -e mpv -v --no-video "$URL"
}

$1
