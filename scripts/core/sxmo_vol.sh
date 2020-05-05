#!/usr/bin/env sh
device() {
  amixer sget Headphone > /dev/null && echo Headphone || echo Speaker
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
  amixer set $(device) 1+
  notify
}
down() {
  amixer set $(device) 1-
  notify
}

$@
