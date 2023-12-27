#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script is executed (asynchronously) when you missed a call
# You can use it to play a ring tone

# The following parameters are provided:
# $1 = Contact Name or Number (if not in contacts)

# kill existing ring playback
sxmo_jobs.sh stop ringing

sxmo_playerctl.sh resume_all
