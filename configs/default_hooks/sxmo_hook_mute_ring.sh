#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script is executed (asynchronously) when you mute (Ignore) an
# incoming call, i.e., ignore the call ringing in.

# kill existing ring playback
sxmo_jobs.sh stop ringing
