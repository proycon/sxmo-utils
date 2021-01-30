#!/usr/bin/env sh
pgrep -f "$(command -v sxmo_statusbar.sh)" | xargs -r kill -USR1 &
