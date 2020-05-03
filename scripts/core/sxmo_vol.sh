#!/usr/bin/env sh
device() {
  amixer sget Headphone && echo Headphone || echo Speaker
}

incvol() {
  amixer set $(device) 1+
  echo 1 > /tmp/sxmo_bar
}
decvol() {
  amixer set $(device) 1-
  echo 1 > /tmp/sxmo_bar
}

echo $1 | grep up && echo 1 > /tmp/sxmo_bar && incvol
echo $1 | grep down && echo 1 > /tmp/sxmo_bar && decvol
sxmo_notify.sh 200 "Volume $(
  echo "$(amixer sget Headphone || amixer sget Speaker)" | 
  grep -oE '([0-9]+)%' |
  tr -d ' %' |
  awk '{ s += $1; c++ } END { print s/c }'  |
  xargs printf %.0f
)"
