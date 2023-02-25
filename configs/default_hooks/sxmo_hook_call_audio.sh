#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script is executed when phone successfully enables/disables callaudio
# mode.

# $1 = "enable" or "disable"

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

# Phonecall started
if [ "$1" = "enable" ]; then
	sxmo_log "Attempting hack to get things just right."
	# fixes bug where sometimes we start with speaker on and mic off
	sxmo_modemaudio.sh enable_speaker
	sxmo_modemaudio.sh disable_speaker
	sxmo_modemaudio.sh mute_mic
	sxmo_modemaudio.sh unmute_mic

	# Add other things here, e.g., volume boosters

# Phonecall ended
elif [ "$1" = "disable" ]; then
	sxmo_log "Attempting hack to get things just right."
	# fixes bug where sometimes we leave call with speaker off
	sxmo_modemaudio.sh disable_speaker
	sxmo_modemaudio.sh enable_speaker

	# Add other things here, e.g., volume boosters

fi
