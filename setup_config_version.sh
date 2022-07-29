#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

case "$1" in
	*.json)
		# we ignore json files
		exit
esac

comment="#"
case "$(busybox head -n1 "$1")" in
	!*)
		comment="!"
		;;
	--*)
		comment="--"
		;;
esac

busybox md5sum "$1" | \
	busybox cut -d" " -f1 | \
	busybox xargs -I{} busybox sed -i "2i$comment configversion: {}" \
	"$1"
