#!/usr/bin/env sh
notify() {
  sxmo_notify.sh 200 "Volume $(
    amixer get "$(sxmo_audiocurrentdevice.sh)" | 
    grep -oE '([0-9]+)%' |
    tr -d ' %' |
    awk '{ s += $1; c++ } END { print s/c }'  |
    xargs printf %.0f
  )"
  echo 1 > /tmp/sxmo_bar
}

up() {
  amixer set "$(sxmo_audiocurrentdevice.sh)" 1+
  notify
}
down() {
  amixer set "$(sxmo_audiocurrentdevice.sh)" 1-
  notify
}
setvol() {
  amixer set "$(sxmo_audiocurrentdevice.sh)" $1
}

$@
