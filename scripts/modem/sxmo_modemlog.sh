#!/usr/bin/env sh
LOGDIR="$XDG_DATA_HOME"/sxmo/modem
st -f "Terminus-14" -e tail -n9999 -f "$LOGDIR"/modemlog.tsv
