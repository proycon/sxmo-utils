#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# For use with peanutbutter (peanutbutter --font Sxmo --statuscommand sxmo_hook_lockstatusbar.sh)
# This filters out the last component (which is usually the time and is already displayed more prominently

# obtain status output to pass to peanutbutter, using awk to remove the last
# column (the time), which we don't need duplicated. We also remove the · symbol which we use in $SXMO_NOTCH
# and is not needed for the lockscreen.
sxmo_status_watch.sh -o pango | tr -d "·" | awk 'NF{NF-=1};1'
