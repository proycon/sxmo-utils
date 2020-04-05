#!/usr/bin/env sh
MAX=10
MIN=2

setdelta() {
  sxmo_setpinebacklight $(
    cat /sys/class/backlight/backlight/brightness |
    xargs -IB echo B $1 |
    bc |
    xargs -INUM echo -e "$MIN\nNUM" | sort -n | tail -n1 |
    xargs -INUM echo -e "$MAX\nNUM" | sort -n | head -n1
  )
  sxmo_notify.sh 200 "Backlight $(cat /sys/class/backlight/backlight/brightness)/10"
}

up() {
  setdelta "+1"
  
}

down() {
  setdelta "-1"
}

$1 $2