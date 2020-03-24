#!/usr/bin/env sh
incvol() {
  amixer set Headphone 1+
  echo 1 > /tmp/sxmo_bar
}
decvol() {
  amixer set Headphone 1-
  echo 1 > /tmp/sxmo_bar
}

echo $1 | grep up && echo 1 > /tmp/sxmo_bar && incvol
echo $1 | grep down && echo 1 > /tmp/sxmo_bar && decvol
sxmo_notify.sh 200 "Volume $(
  amixer sget Headphone |
  grep -oE '([0-9]+)%' |
  tr -d ' %' |
  awk '{ s += $1; c++ } END { print s/c }'  |
  xargs printf %.0f
)"
