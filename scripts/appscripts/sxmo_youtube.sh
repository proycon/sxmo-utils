#!/usr/bin/env sh
menu() {
	pidof svkbd-sxmo || svkbd-sxmo &
	SEARCHTERMS="$(
		echo "Close Menu\n" |
		dmenu -p "Yt Search" -c -l 10 -fn Terminus-20
	)"
	pkill svkbd-sxmo
	[ "CLOSE_MENU" = "$SEARCHTERMS" ] && exit 0

	IDIOTRESULTS="$(youtube-cli "$SEARCHTERMS")"
	FMTRESULTS="$(
		echo "$IDIOTRESULTS" |
		grep -Ev '^(Channelid|Atom feed|Channel title|Published|Viewcount|Userid):' |
		sed -E 's/^(URL|Duration):\s+/\t/g' |
		tr -d '\n' |
		sed 's/===/\n/g' |
		gawk -F'\t' '{ print $3 " " $1 " " $2}'
	)"

	PICKED="$(
		printf %b "Close Menu\n$FMTRESULTS" |
		dmenu -c -l 10 -fn Terminus-20
	)"
	[ "CLOSE_MENU" = "$PICKED" ] && exit 0

	URL="$(echo "$PICKED" | awk -F " " '{print $NF}')"
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
