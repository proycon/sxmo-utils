#!/usr/bin/env sh
DIR=/home/$USER/.sxmo

# Warn for no texts
ls -1 $DIR | wc -l | grep -E '^0$' && echo "No texts!" | dmenu -fn Terminus-20 -l 10 -c && exit 1

# Display
ls -1 $DIR | dmenu -p Messages -c -fn Terminus-20 -l 10 | xargs -INUMBER st -e tail -f $DIR/NUMBER/sms.txt