#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

err() {
	printf %b "$1" | dmenu
	exit
}

sxmo_terminal.sh sh -c "mmcli -m any && read"
