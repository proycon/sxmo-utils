#!/usr/bin/env sh
pidof svkbd-sxmo || svkbd-sxmo &
SEARCHTERMS="$(
  echo "Search term" |
  dmenu -p "Yt Search" -c -l 10 -fn Terminus-20
)"
pkill svkbd-sxmo

IDIOTRESULTS="$(idiotbox-cli $SEARCHTERMS)"
RESULT="$(
        echo "$IDIOTRESULTS" |
        grep -Ev '^(Channelid|Atom feed|Channel title|Published|Viewcount|Userid):' |
        sed -E 's/^(URL|Duration):\s+/\t/g' |
        tr -d '\n' |
        sed 's/===/\n/g' |
        gawk -F'\t' '{ print $3 " " $1 " " $2}' |
        dmenu -c -l 10 -fn Terminus-20
)"

[[ "CLOSE_MENU" == "$RESULT" ]] && exit 0

URL=$(echo "$RESULT" | awk -F " " '{print $NF}')
st -e mpv --ytdl-format='[height<420]' $@ "$URL"
