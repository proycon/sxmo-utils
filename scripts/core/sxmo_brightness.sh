#!/usr/bin/env sh
[ -e /sys/class/backlight/edp-backlight ] && DEV=/sys/class/backlight/edp-backlight
[ -e /sys/devices/platform/backlight/backlight/backlight ] && DEV=/sys/devices/platform/backlight/backlight/backlight

MAX=$(cat $DEV/max_brightness)
MIN=2
STEP=$(echo "($MAX - $MIN) / 10" | bc)

setdelta() {
  sxmo_setpinebacklight $(
    cat $DEV/brightness |
    xargs -IB echo B $1 |
    bc |
    xargs -INUM echo -e "$MIN\nNUM" | sort -n | tail -n1 |
    xargs -INUM echo -e "$MAX\nNUM" | sort -n | head -n1
  )
  sxmo_notify.sh 200 "Backlight $(cat $DEV/brightness)/${MAX}"
}

up() {
  setdelta "+${STEP}"
  
}

down() {
  setdelta "-${STEP}"
}

$1 $2