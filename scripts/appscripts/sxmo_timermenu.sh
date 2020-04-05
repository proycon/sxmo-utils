#!/usr/bin/env sh
pidof svkbd-sxmo || svkbd-sxmo &
TIMEINPUT=$(
echo "1h
10m
9m
8m
7m
6m
5m
4m
3m
2m
1m
30s
Close Menu" | dmenu -p Timer -c -fn "Terminus-30" -l 20
)
pkill svkbd-sxmo
[ "Close Menu" = $TIMEINPUT ] && exit 0

st -f Monospace-50 -e sxmo_timer.sh $TIMEINPUT

