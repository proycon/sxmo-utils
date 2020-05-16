#!/usr/bin/env sh
sxmo_setpineled white "$(
  cat /sys/class/leds/white:flash/brightness | 
  grep -E '^0$' > /dev/null && echo 255 || echo 0
)"

