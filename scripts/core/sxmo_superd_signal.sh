#!/bin/sh

# superd should allow a "signal" command
# before that this will close the gap

superctl status "$1" | \
	grep "PID:" | \
	cut -f"2" -d":" |  \
	tr -d "[:blank:]" | \
	xargs -r kill "$2"
