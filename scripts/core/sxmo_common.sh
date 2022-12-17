#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# This script is meant to be sourced by various sxmo scripts
# and defines some common settings

# This script ensures all sxmo scripts are using the busybox version of
# certain coreutils rather than any other version that may be installed on the
# user's computer

#aliases aren't expanded in bash
# shellcheck disable=SC2039,SC3044
command -v shopt > /dev/null && shopt -s expand_aliases

alias dmenu="sxmo_dmenu.sh"
alias bemenu="sxmo_dmenu.sh"
alias jq="gojq" # better performances

confirm_menu() {
	printf "No\nYes\n" | \
		dmenu "$@" | \
		grep -q "Yes"
}

sxmo_log() {
	printf "%s %s: %s\n" "$(date +%H:%M:%S)" "${0##*/}" "$*" >&2
}

sxmo_debug() {
	if [ -n "$SXMO_DEBUG" ]; then
		printf "%s %s DEBUG: %s\n" "$(date +%H:%M:%S)" "${0##*/}" "$*" >&2
	fi
}

# Outputs the paths of the specified file/dir path in XDG_DATA_DIRS.
# Will output $2 instances (default 1, 0 for no limit)
# Will separate instances with $3 (default " ")
#
# xdg_data_path icons/open.ico
# -> "/usr/local/share/icons/open.ico"
#
# xdg_data_path sxmo/appcfg
# -> "/usr/share/sxmo/appcfg"
#
# xdg_data_path icons 0 "|"
# -> "/usr/local/share/icons|/usr/share/icons"
xdg_data_path() {
	filepath=$1
	instance_count=${2:-1}
	sep=${3:-" "}

	IFS=':'
	instance=0
	for dir in $XDG_DATA_DIRS /usr/share
	do
		if [ -e "$dir/$filepath" ]; then
			if [ "$instance" -ge "$instance_count" ] && [ "$instance_count" != "0" ]; then
				break
			fi
			if [ $instance -gt 0 ]; then
				printf '%s' "${sep}"
			fi
			printf '%s' "${dir}/${filepath}"
			instance=$((instance+1))
		fi
	done
}
