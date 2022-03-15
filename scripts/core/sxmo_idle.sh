#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

_swayidletoidles() {
	while [ $# -gt 0 ]; do
		case "$1" in
			timeout)
				printf "%s|%s" "$2" "$3"
				shift 3
				case "$1" in
					resume)
						printf "|%s" "$2"
						shift 2
				;;
				esac
				printf "\n"
				;;
			*)
				shift
				;;
		esac
	done
}

xorgidle() {
	idles="$(_swayidletoidles "$@")"
	resumes=""

	tick=0
	new_idle="$(xprintidle)"
	last_idle="$new_idle"

	finish() {
		sh -c "$resumes"
		resumes=""
		exit
	}
	trap 'finish' TERM INT EXIT

	while : ; do
		last_idle="$new_idle"
		new_idle="$(xprintidle)"
		if [ "$last_idle" -gt "$new_idle" ]; then
			sh -c "$resumes"
			tick=0
			resumes=""
		fi

		if printf "%b\n" "$idles" | grep -q "^$tick|"; then
			printf "%b\n" "$idles" | \
				grep "^$tick|" | \
				cut -d'|' -f2 | \
				xargs -I{} -0 sh -c "{}"
			resumes="$(printf "%b\n" "$idles" | grep "^$tick|" | cut -d'|' -f3);$resumes"
		fi

		sleep 1
		tick=$((tick + 1))
	done
}

case "$SXMO_WM" in
	dwm)
		xorgidle "$@"
		;;
	*)
		exec "${SXMO_WM}idle" "$@"
		;;
esac
