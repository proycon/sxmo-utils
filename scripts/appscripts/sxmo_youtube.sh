#!/bin/sh
# title="$icon_ytb YouTube"
# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

HISTORY_FILE="$XDG_CACHE_HOME"/sxmo/youtubehistory.tsv
AUDIOONLY=0

youtubesearch() {
	QUERY="$1"
	youtube-cli "$QUERY" |
		grep -Ev '^(Channelid|Atom feed|Channel title|Published|Viewcount|Userid):' |
		sed -E 's/^(URL|Duration):\s+/\t/g' |
		tr -d '\n' |
		sed 's/===/\n/g' |
		gawk -F'\t' '{ print $3 " " $1 " " $2}'
}

searchmenu() {
	HISTORY="$(
		tac "$HISTORY_FILE" | nl | sort -uk 2 | sort -k 1 | cut -f 2 | grep . |
		sed "s#^#History: #g"
	)"

	while true; do
		ENTRY="$(
			printf %b "
				Close Menu
				$HISTORY
			" |
				xargs -0 echo |
				sed '/^[[:space:]]*$/d' |
				awk '{$1=$1};1' |
				sxmo_dmenu_with_kb.sh -p "Yt Search"
		)" || exit 0

		if [ "Close Menu" = "$ENTRY" ]; then
			exit 0
		else
			ENTRY="$(echo "$ENTRY" | sed 's#^History: ##')"
			printf %b "$ENTRY\n" >> "$HISTORY_FILE"
			youtubesearch "$ENTRY" | resultsmenu
		fi
	done
}

resultsmenu() {
	RESULTS="$(cat)"

	while true; do
		PICKED="$(
			printf %b "
				Close Menu\n
				Change Search\n
				$RESULTS
			" |
				xargs -0 echo |
				sed '/^[[:space:]]*$/d' |
				awk '{$1=$1};1' |
				sxmo_dmenu.sh -p "Results"
		)" || exit 0

		if [ "Change Search" = "$PICKED" ]; then
			return
		elif [ "Close Menu" = "$PICKED" ]; then
			exit 0
		elif [ "$AUDIOONLY" = 1 ]; then
			URL="$(echo "$PICKED" | awk -F " " '{print $NF}')"
			sxmo_terminal.sh mpv -ao=alsa -v --no-video "$URL" &
		else
			URL="$(echo "$PICKED" | awk -F " " '{print $NF}')"
			sxmo_terminal.sh mpv -ao=alsa -v --ytdl-format='[height<420]' "$URL" &
		fi
	done
}

video() {
	AUDIOONLY=0
	searchmenu
}

audio() {
	AUDIOONLY=1
	searchmenu
}
if [ -n "$1" ]; then
	"$@"
else
	video
fi
