#!/bin/sh
# This script is called with both toggle wm and when loging out (i.e., restarting) 
# current window manager.  You'll want to give a 5s pause here to let certain apps
# `cool off' before we restart wm, but otherwise everything *should* die with the 
# wm
superctl stop sxmo_sound_monitor
superctl stop wireplumber
superctl stop pipewire-pulse
superctl stop pipewire

# give pipewire time
sleep 5s
