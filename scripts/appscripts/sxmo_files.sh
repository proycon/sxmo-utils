#!/usr/bin/env sh
EDITOR=vis
cd /home/$USER/

handlefiles() {
  echo "$1" | grep -iE ".(wav|webm|mp4|ogg|opus|m4a|flac|mov|avi)$" && st -e mpv "$@" && exit
  echo "$1" | grep -iE ".(jpg|png|gif)$" && st -e sxiv "$@" && exit
  st -e sh -ic "$EDITOR "$@"" && exit
}

while true; do
  CHOICES="$(echo -e 'Close Menu\n../\n*\n'"$(ls -1p)")"
  DIR="$(basename "$(pwd)")"
  PICKED="$(
    echo "$CHOICES" |
    dmenu -fn Terminus-18 -c -p "$DIR" -l 20
  )"

  echo "$PICKED" | grep "Close Menu" && exit 0
  [ -d "$PICKED" ] && cd "$PICKED" && continue
  echo "$PICKED" | grep -E '^[*]$' && handlefiles *
  [ -f "$PICKED" ] && handlefiles "$PICKED"
done
