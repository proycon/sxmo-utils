#!/usr/bin/env sh
device() {
  amixer sget Earpiece | grep -E '\[on\]' > /dev/null && echo Earpiece && return
  amixer sget Headphone | grep -E '\[on\]' > /dev/null && echo Headphone && return
  echo "Line Out"
}

notify() {
  sxmo_notify.sh 200 "Volume $(
    amixer get "$(device)" | 
    grep -oE '([0-9]+)%' |
    tr -d ' %' |
    awk '{ s += $1; c++ } END { print s/c }'  |
    xargs printf %.0f
  )"
  echo 1 > /tmp/sxmo_bar
}

up() {
  amixer set "$(device)" 1+
  notify
}
down() {
  amixer set "$(device)" 1-
  notify
}
setvol() {
  amixer set "$(device)" $1
}

$@
