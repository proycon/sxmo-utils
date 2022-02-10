#!/bin/sh

# This script is executed (asynchronously) when you mute an incoming call

# just do the same as the missed_call hook:
exec sxmo_hook_missed_call.sh "$@"
