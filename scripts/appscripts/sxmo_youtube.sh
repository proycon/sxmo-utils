#!/usr/bin/env sh
HISTORY_FILE="$XDG_CONFIG_HOME"/sxmo/youtubehistory.tsv
NRESULTS=5
AUDIOONLY=0

jsonfieldextract() {
  FIELDNAME="$1"
  TYPE="$2"
  # TODO: be less lazy and use a JSON parser, need to add json2tsv as dep..
  if [ "$TYPE" = "number" ]; then
    GREPED="$(grep -oE '"'"$FIELDNAME"'"[ ]*:[ ]*[0-9+]+[ ]*,')"
  else
    GREPED="$(grep -oE '"'"$FIELDNAME"'"[ ]*:[ ]*"[^"]+"[ ]*,')"
  fi
  echo "$GREPED" | cut -d: -f2- | tr -d '",' | sed -E 's#^[ ]+##' | head -n1
}

youtubesearch() {
  QUERY="$1"
  NRESULTS="$2"
  RESULTS="$(youtube-dl -j ytsearch"$NRESULTS":"${QUERY}")"
  i=1
  while [ $i -lt "$(echo "$NRESULTS" + 1 | bc)" ]; do
    TITLE="$(echo "$RESULTS" | awk NR==$i | jsonfieldextract fulltitle string)"
    URL="$(echo "$RESULTS" | awk NR==$i | jsonfieldextract webpage_url string)"
    DURATION="$(echo "$RESULTS" | awk NR==$i | jsonfieldextract duration number)s"
    echo "$DURATION: $TITLE - $URL"
    i="$(echo $i + 1 | bc)"
  done
}

searchmenu() {
	HISTORY="$(
		tac "$HISTORY_FILE" | nl | sort -uk 2 | sort -k 1 | cut -f 2 |
		sed "s#^#History: #g"
	)"

	while true; do
		ENTRY="$(
			printf %b "
				Close Menu
				Show 1 Result              $([ "$NRESULTS" = "1" ] && echo "✓")
				Show 5 Results             $([ "$NRESULTS" = "5" ] && echo "✓")
				Show 10 Results            $([ "$NRESULTS" = "10" ] && echo "✓")
				Show 20 Results            $([ "$NRESULTS" = "20" ] && echo "✓")
				$HISTORY
			" |
				xargs -0 echo |
				sed '/^[[:space:]]*$/d' |
				awk '{$1=$1};1' |
				sxmo_dmenu_with_kb.sh -p "Yt Search" -c -l 10 -fn Terminus-20
		)"

		if [ "Close Menu" = "$ENTRY" ]; then
			exit 0
		elif echo "$ENTRY" | grep -E "Show [0-9]+ Results*"; then
			NRESULTS="$(echo "$ENTRY" | grep -oE "[0-9]+")"
		else
			ENTRY="$(echo "$ENTRY" | sed 's#^History: ##')"
			printf %b "$ENTRY\n" >> "$HISTORY_FILE"
			youtubesearch "$ENTRY" "$NRESULTS" | resultsmenu
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
				dmenu -c -l 10 -p "Yt Results" -fn Terminus-20
		)"

		if [ "Change Search" = "$PICKED" ]; then
			return
		elif [ "Close Menu" = "$PICKED" ]; then
			exit 0
		elif echo $PICKED | grep "Audio & Video or"; then
			if [ "$AUDIOONLY" = 0 ]; then
				AUDIOONLY=1
			else
				AUDIOONLY=0
			fi
		elif [ "$AUDIOONLY" = 1 ]; then
			URL="$(echo "$PICKED" | awk -F " " '{print $NF}')"
			st -e mpv -ao=alsa -v --no-video "$URL" &
		else
			URL="$(echo "$PICKED" | awk -F " " '{print $NF}')"
			st -e mpv -ao=alsa -v --ytdl-format='[height<420]' "$URL" &
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

$1