#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# this is the actual suspend call
# $1 is either empty or seconds to wake up in

if [ -z "$1" ]; then
	# this is an arbitrarily big number, some machines won't accept this much
	# you can also change this to pm-suspend or whatever you like.
	rtcwake -m mem -s 268435455 >&2
else
	rtcwake -m mem -s "$1" >&2
fi
