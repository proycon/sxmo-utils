#!/bin/sh
superctl stop wireplumber
superctl stop pipewire-pulse
superctl stop pipewire

# give pipewire time
sleep 5s
