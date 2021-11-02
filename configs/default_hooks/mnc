#!/bin/sh

if ! command -v mnc > /dev/null; then
	exit 1
fi

crontab -l | grep sxmo_rtcwake | mnc
