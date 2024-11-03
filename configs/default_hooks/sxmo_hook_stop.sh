#!/bin/sh

# Runs after wm has been stopped., useful for cleanup

# clean up misc. stale files (if any)
rm -rf "$XDG_RUNTIME_DIR"/sxmo*
