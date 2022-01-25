#!/bin/sh

err() {
	printf %b "$1" | dmenu
	exit
}

sxmo_terminal.sh sh -c "mmcli -m any && read"
