#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

MIMEAPPS="${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list"
DESKTOPS_CACHED_MIMEAPPS="${XDG_CONFIG_HOME:-$HOME/.config}/desktops.mimeapps.list"
DESKTOP_DIRS="$(xdg_data_path sxmo/applications/ 0 "|")|$(xdg_data_path applications 0 "|")|${XDG_DATA_HOME:-$HOME/.local/share}/applications/"
CACHE_DIR="${XDG_RUNTIME_DIR:-$HOME/.run}/xdg-open-cache"
[ ! -d "$CACHE_DIR" ] && mkdir -p "$CACHE_DIR"
attached=
debug=
TERMCMD="${TERMCMD:-st -e}"

# This will convert a mimeapps.list to a parsable mapping
# Lines with multiple mimetype will be splitted
# The mapping format is something as
# added;image/jpeg;bar.desktop
# added;image/jpeg;baz.desktop
# added;video/H264;bar.desktop
# default;image/jpeg;foo.desktop
# removed;video/H264;baz.desktop
mimeapps_to_desktop_mapping() {
	[ ! -f "$1" ] && return
	awk '
		/^\[Default Applications\]$/ { kind = "default" }
		/^\[Added Associations\]$/ { kind = "added" }
		/^\[Removed Associations\]$/ { kind = "removed" }
		/=/ {
			split($0, mime_desktops, "=")
			split(mime_desktops[2], desktops, ";")

			for ( key in desktops ) {
				print kind ";" mime_desktops[1] ";" desktops[key]
			}
		}
	' "$1"
}

# This will generate the added mapping from all destkop entries in a dir
get_mimeapps_entries_from_desktop_dir() {
	for desktop_path in "$1"/*.desktop; do
		grep '^MimeType=' "$desktop_path" \
		| tr ';' '\n' \
		| cut -d= -f2 \
		| xargs -I{} printf "%s=%s\n" "{}" "$(basename "$desktop_path")"
	done
}

# Build and save the desktop mimeapps mapping if necessary
prepare_desktop_mimeapps_mapping_cache() {
	last_desktop_modif_date="$(printf "%s\n" "$DESKTOP_DIRS" | tr '|' '\n' | while read -r desktop_dir; do
		for desktop_file in "$desktop_dir"/*.desktop; do
			stat -c %Y "$desktop_file"
		done
	done | sort -r | head -n1)"

	if [ -r "$DESKTOPS_CACHED_MIMEAPPS" ]; then
		desktop_cache_modif_date="$(stat -c %Y "$DESKTOPS_CACHED_MIMEAPPS")"
		if [ "$last_desktop_modif_date" -gt "$desktop_cache_modif_date" ]; then
			rm "$DESKTOPS_CACHED_MIMEAPPS"
		fi
	fi

	if [ ! -r "$DESKTOPS_CACHED_MIMEAPPS" ]; then
		IFS='|'
		echo "[Added Associations]" > "$DESKTOPS_CACHED_MIMEAPPS"
		for desktop_dir in $DESKTOP_DIRS; do
			get_mimeapps_entries_from_desktop_dir "$desktop_dir"
		done >> "$DESKTOPS_CACHED_MIMEAPPS"
	fi
}

find_desktop_path() {
	desktop_name="$1"

	IFS='|'
	for desktop_dir in $DESKTOP_DIRS; do
		if [ -r "$desktop_dir/$desktop_name" ]; then
			realpath "$desktop_dir/$desktop_name"
			return
		fi
	done
}

# This will take the full maping and simplify it which means
# * strip added entries with removed ones
# * put default entries first
# * remove duplicates lines
# following this format
# image/jpeg;foo.desktop
# image/jpeg;bar.desktop
# image/jpeg;baz.desktop
simplify_mapping() {
	awk '
		function contains(array, value) {
			for (key in array) {
				if (array[key] == value)
					return 1
			}
			return 0
		}

		/^$/ {next}

		/^default;/ { kind = "default" }
		/^added;/ { kind = "added" }
		/^removed;/ { kind = "removed" }

		{ gsub(kind ";", "", $0) }

		kind == "default" { default_entries[NR]=$0 }
		kind == "added" { added_entries[NR]=$0 }
		kind == "removed" { removed_entries[NR]=$0 }

		END {
			for (key in default_entries) {
				print default_entries[key]
			}
			for (key in added_entries) {
				entry = added_entries[key]
				if (contains(removed_entries, entry)) { continue }
				if (contains(default_entries, entry)) { continue }
				print entry
			}
		}
	' /dev/stdin
}

get_mimeapps_mapping() {
	prepare_desktop_mimeapps_mapping_cache

	printf '%s\n%s' \
		"$(mimeapps_to_desktop_mapping "$MIMEAPPS")" \
		"$(mimeapps_to_desktop_mapping "$DESKTOPS_CACHED_MIMEAPPS")" \
		| simplify_mapping
}

filter_matching_desktops() {
	mime_type="$1"

	grep "^$mime_type;" /dev/stdin \
		| cut -d";" -f2
}

curl_mime_type() {
	if result="$(curl -sL --head -f "$1")"; then
		printf %s "$result" \
			| grep -i "^content-type: " \
			| cut -d" " -f2 \
			| head -c-2 \
			| sed "s|;.*||"
	fi
}

extension_mime_type() {
	[ ! -r "/etc/mime.types" ] && return # require mailcap

	ext="${1##*.}"
	grep "\t.*$ext" /etc/mime.types | awk '{print $1}'
}

get_mime_type() {
	if [ -r "$1" ]; then # is readable
		mime_type="$(file -b --mime-type "$1")"
	elif echo "$1" | grep -q '^.\+:'; then # Seems like an x-scheme
		if echo "$1" | grep -q '^https\?:'; then
			mime_type="$(curl_mime_type "$1")"
		fi

		if [ -z "$mime_type" ] || \
			[ "$mime_type" = "application/binary" ]; then
			mime_type="x-scheme-handler/$(echo "$1" | grep -o '^\w\+')"
		fi
	else
		echo "This file does not exists?" >&2
		exit 1
	fi

	# we try to be more precise then
	if [ "application/octet-stream" = "$mime_type" ]; then
		new_mime_type="$(extension_mime_type "$1")"
		[ -n "$new_mime_type" ] && mime_type="$new_mime_type"
	elif [ "inode/symlink" = "$mime_type" ]; then
		real_path="$(realpath "$1")"
		mime_type="$(get_mime_type "$real_path")"
	fi

	echo "$mime_type"
}

execute() {
	if [ -n "$debug" ]; then
		echo "The final command to execute is:" >&2
		echo "$@" >&2
		exit 0
	fi

	eval "$*"
}

fetch_file() {
	if [ -n "$debug" ]; then
		echo "The file would be downloaded with '$*'" >&2
		return
	fi

	eval "$*"
}

build_command() {
	exec="$1"
	shift

	IFS="
"
	file_paths="$*"
	unset IFS

	if echo "$exec" | grep -q '%f\|%F'; then # We must retrieve distant files
		file_paths="$(
			echo "$file_paths" | while read -r file_path; do
				file_id="$(printf %s "$file_path" | sha256sum | cut -d" " -f1)"
				local_file_path="$CACHE_DIR/$file_id"
				if echo "$file_path" | grep -q '^https\?://'; then
					if [ ! -f "$local_file_path" ]; then
						fetch_file curl -L -so "$local_file_path" "$file_path"
					fi
				else
					echo "$file_path"
					continue
				fi
				echo "$local_file_path"
			done
		)"
		exec="$(echo "$exec" | sed -e 's|%f|%u|' -e 's|%F|%U|')"
	fi

	file_paths="$(echo "$file_paths" | awk '{print "\"" $0 "\""}')"

	command=
	if echo "$exec" | grep -q '%u'; then # handle url file one by one
		exec="$(echo "$exec" | sed 's|%u|"%s"|')"
		if [ "true" = "$terminal" ]; then
			command="$(echo "$file_paths" | xargs printf "$TERMCMD $exec & " | sed 's| $||')"
		else
			command="$(echo "$file_paths" | xargs printf "$exec & " | sed -e 's|^ ||' -e 's| $||')"
		fi
	elif echo "$exec" | grep -q '%U'; then # handle url file grouped
		exec_before="$(echo "$exec" | awk -F' %U' '{print $1}')"
		exec_after="$(echo "$exec" | awk -F'%U ' '{$1=""; print $0}')"
		command="$exec_before $(echo "$file_paths" | xargs printf '"%s" ')${exec_after:+ $exec_after }&"
		if [ "true" = "$terminal" ]; then
			command="$TERMCMD $command"
		fi
	else
		command="$exec $(echo "$file_paths" | xargs printf '"%s" ')&"
		if [ "true" = "$terminal" ]; then
			command="$TERMCMD $command"
		fi
	fi

	echo "$command"
}

run_desktop() {
	desktop="$1"
	shift

	desktop_path="$(find_desktop_path "$desktop")"
	if [ -z "$desktop_path" ]; then
		echo "We can't find the desktop file \"$desktop\"" >&2
		return
	fi

	desktop_content="$(cat "$desktop_path")"
	exec="$(echo "$desktop_content" | grep '^Exec=' | sed 's|^Exec=||' | head -n1)"
	terminal="$(echo "$desktop_content" | grep '^Terminal=' | cut -d= -f2)"
	[ -z "$terminal" ] && terminal="false"

	command="$(build_command "$exec" "$@")"

	if [ -n "$attached" ]; then
		command="$(echo "$command" | sed 's| &|;|g')"
	fi

	if [ -n "$debug" ]; then
		echo "Exec is \"$exec\"" >&2
		echo "Terminal is \"$terminal\"" >&2
		echo "Command is \"$command\"" >&2
		exit 0
	fi

	eval "$command"

	exit 0
}

run() {
	mime_type="$(get_mime_type "$1")"

	if [ -z "$mime_type" ]; then
		echo "We failed to find the mime_type for \"$1\"" >&2
		exit 1
	fi

	desktops="$(get_mimeapps_mapping | filter_matching_desktops "$mime_type")"

	if [ -n "$debug" ]; then
		echo "The mime type is \"$mime_type\"" >&2
		echo "The matching desktops are:" >&2
		echo "$desktops" >&2
	fi

	if [ -z "$desktops" ]; then
		echo "There is no matching desktop to open \"$mime_type\"" >&2
		exit 1
	fi

	echo "$desktops" | while read -r desktop; do
		run_desktop "$desktop" "$@"
	done
}

if [ "-d" = "$1" ]; then
	debug="1"
	shift
fi

if [ "-a" = "$1" ]; then
	attached="1"
	shift
fi

if [ $# -gt 0 ]; then
	set -- "${1#file://}"
	run "$@"
fi
