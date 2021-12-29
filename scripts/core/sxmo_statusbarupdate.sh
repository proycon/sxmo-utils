#!/bin/sh

pkill -10 -f sxmo_statusbar.sh
sxmo_hooks.sh statusupdate "$1"
