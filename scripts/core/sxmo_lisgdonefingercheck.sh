#!/usr/bin/env sh
ACTIVEWIN="$(xdotool getactivewindow)"
WMCLASS="$(xprop -id "$ACTIVEWIN" | grep WM_CLASS | cut -d ' ' -f3-)"

# E.g. just a check to ignore 1-finger gestures in foxtrotgps
if echo "$WMCLASS" | grep -vi foxtrot; then
  "$@"
fi
