#!/usr/bin/env sh

if [[ ! -z "$1" ]]
then
  # E.g. passed liked: sxmo_urlhandler.sh http://foo.com
  URL=$1
else
  # Surf
  WINDOW="$(xprop -root | sed -n '/^_NET_ACTIVE_WINDOW/ s/.* //p')"
  SURFURL=`xprop -id $WINDOW | grep URI | awk '{print $3}' | sed 's/\"//g'`
  if [[ ! -z "$SURFURL" ]]
  then
    URL="$SURFURL"
  fi

  # Is normal browser? (FF or Netsurf) - use Ctrl-L Ctrl-C to copy URL
  ISNORMBROWS=`xprop -id $(xdotool getactivewindow) | grep -E 'WM_CLASS.*(Netsurf|Firefox)'`
  if [[ ! -z "$ISNORMBROWS" ]]
  then
    xdotool key --clearmodifiers --delay 20 "ctrl+l" "ctrl+c"
    sleep 0.2
    URL="$(xclip -o)"
  fi
fi

COMMAND=$(
  echo "
    w3m URL
    mpv -v URL
    mpv -v --ytdl-format='[height<420]' URL
    firefox -new-window URL
    netsurf URL
    surf URL
    echo URL | xclip -i
    youtube-dl -o- URL | mpv -v -
    youtube-dl URL
    curl URL | vis -
    wget URL
    aria2c URL
    " | sed "s/URL/'URL'/g" | sed -e '/^\s*$/d' | sed -e 's/^\s*//' | dmenu -fn Terminus-15 -p "Pipe URL" -c -l 10
)
[[ -z "$COMMAND" ]] && exit 1

RUN=$(echo $URL | xargs -IURL echo "$COMMAND")
st -e sh -c "$RUN"
