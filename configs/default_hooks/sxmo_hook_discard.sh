#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script is executed (asynchronously) when you discard an incoming call
# i.e., click Hangup on Pickup menu when call is coming in (without picking
# up the call).

# kill existing ring playback
if [ -e "$XDG_RUNTIME_DIR/sxmo.ring.pid" ]; then
	MPVID="$(cat "$XDG_RUNTIME_DIR/sxmo.ring.pid")"
	kill "$MPVID"
	rm "$XDG_RUNTIME_DIR/sxmo.ring.pid"
fi

sxmo_playerctl.sh resume_all
