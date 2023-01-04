#!/bin/sh

if command -v sxmobar > /dev/null; then
	exec sxmobar -w "$@"
else
	exec sxmo_status.sh -w "$@"
fi
