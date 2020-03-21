#!/usr/bin/env sh
sxmo_keyboard.sh on &
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
sxmo_keyboard.sh off &
[ "Close Menu" = $TIMEINPUT ] && exit 0

st -f Monospace-50 -e sxmo_timer.sh $TIMEINPUT

