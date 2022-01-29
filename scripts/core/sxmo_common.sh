#!/bin/sh

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

# Use native commands if busybox was compile without those apples (for example Debians busybox)
if busybox pkill -l > /dev/null 2>&1; then
	alias pkill="busybox pkill"
	alias pgrep="busybox pgrep"
fi
alias bc="busybox bc"
alias find="busybox find"
alias grep="busybox grep"
alias less="busybox less"
alias more="busybox more"
alias netstat="busybox netstat"
alias tail="busybox tail"
alias xargs="busybox xargs"
alias rfkill="busybox rfkill"

confirm_menu() {
	printf "No\nYes\n" | \
		dmenu "$@" | \
		grep -q "Yes"
}

sxmo_log() {
	printf "%s %s: %s\n" "$(date +%H:%M:%S)" "${0##*/}" "$*" >&2
}

sxmo_debug() {
	printf "%s %s DEBUG: %s\n" "$(date +%H:%M:%S)" "${0##*/}" "$*" >&2
}
