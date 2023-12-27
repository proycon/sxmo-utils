#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script is executed (asynchronously) when you pick up an incoming call

# kill existing ring playback
sxmo_jobs.sh stop ringing

sxmo_playerctl.sh pause_all
