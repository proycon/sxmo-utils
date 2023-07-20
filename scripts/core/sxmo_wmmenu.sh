#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# this script is a menu which lets the user perform some WM actions.

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh
# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh

set -e

# A menu which allows to move windows or toggle floating.
swaymovemenu() {
	CHOICES="$(cat <<EOF
$icon_cls Close Menu
$icon_aru Move Up
$icon_ard Move Down
$icon_arl Move Left
$icon_arr Move Right
$icon_wn2 Toggle Floating
$icon_ac1 Move Scratchpad
1 Move to WS 1
2 Move to WS 2
3 Move to WS 3
4 Move to WS 4
EOF
	)"

	MOVEINDEX=0
	while : ; do
		# Remove current workspace from the list
		CHOICES="$(
			printf "%s" "$CHOICES" |
			grep -v "$(
				swaymsg -t get_workspaces |
				jq -r '
					.[] | select(.focused).name
				')"
		)"

		PICKED="$(printf "%s" "$CHOICES" | dmenu -I "$MOVEINDEX" -p "Move menu")"
		MOVEINDEX="$(($(printf "%s" "$CHOICES" | grep -nm1 "^$PICKED$" | cut -d: -f1) -1))"
		case "$PICKED" in
			""|"$icon_cls Close Menu")
				return
				;;
			?" Move to WS "?)
				sxmo_wm.sh moveworkspace "${PICKED%" Move to WS "?}"
				return
				;;
			"$icon_wn2 Toggle Floating")
				swaymsg floating toggle
				;;
			*)
				printf "%s" "$PICKED" | tr -cd '\000-\177' | xargs swaymsg
				;;
		esac
	done
}

# The generic sway menu
swaywmmenu() {
	WMINDEX=0

	while : ; do
		# generate layout line with format "current → next → 2nd next"
		CURRENT_LAYOUT="$(
			swaymsg -t get_tree |
				jq -r 'recurse(.nodes[]) |
				if select(.nodes[].focused).layout=="output" then
					select(.nodes[].focused).nodes[].layout
				else select(.nodes[].focused).layout end'
		)"
		if [ -n "$CURRENT_LAYOUT" ]; then
			if [ "$CURRENT_LAYOUT" = "splith" ]; then
				LAYOUT_LINE="splith $icon_arr splitv $icon_arr tabbed"
			elif [ "$CURRENT_LAYOUT" = "tabbed" ] ; then
				LAYOUT_LINE="tabbed $icon_arr splith $icon_arr splitv"
			else
				LAYOUT_LINE="splitv $icon_arr tabbed $icon_arr splith"
			fi
		fi
		CHOICES="$(grep . <<EOF
$icon_cls Close Menu
$icon_mov Move menu
$icon_rld Switch menu
$([ -n "$CURRENT_LAYOUT" ] && printf "%s" "$icon_rld $LAYOUT_LINE")
$icon_grd Split horizontal
$icon_mnu Split vertical
$icon_exp Focus parent
EOF
		)"
		PICKED="$(printf "%s" "$CHOICES" | grep . | dmenu -I "$WMINDEX" -p "WM Menu")"
		WMINDEX="$(($(printf "%s" "$CHOICES" | grep -nm1 "^$PICKED$" | cut -d: -f1) -1))"

		case "$PICKED" in
			""|"$icon_cls Close Menu")
				return
				;;
			"$icon_mov Move menu")
				swaymovemenu
				;;
			"$icon_rld Switch menu")
				swaywindowswitcher
				;;
			"$icon_rld $LAYOUT_LINE")
				sxmo_wm.sh togglelayout
				;;
			"$icon_exp Focus parent")
				swaymsg focus parent
				;;
			*)
				printf "%s" "$PICKED" | tr -cd '\000-\177' | xargs swaymsg
		esac
	done
}

dwmwmmenu() {
	WMINDEX=0

	while : ; do
		CHOICES="$(
			cat <<EOF
$icon_cls Close Menu
1 Move to WS 1
2 Move to WS 2
3 Move to WS 3
4 Move to WS 4
$icon_rld Shift stack
$icon_grd Toggle Layout
EOF
		)"
		PICKED="$(printf "%s" "$CHOICES" | dmenu -I "$WMINDEX" -p "WM Menu")"
		WMINDEX="$(($(printf "%s" "$CHOICES" | grep -nm1 "^$PICKED$" | cut -d: -f1) -1))"
		case "$PICKED" in
			""|"$icon_cls Close Menu")
				return
				;;
			?" Move to WS "?)
				sxmo_wm.sh moveworkspace "${PICKED%" Move to WS "?}"
				;;
			"$icon_rld Shift stack")
				sxmo_wm.sh switchfocus
				;;
			"$icon_grd Toggle Layout")
				sxmo_wm.sh togglelayout
		esac
	done
}

swaywindowswitcher() {
	SWITCHINDEX=0

	while : ; do
		FORMAT='"W:" + .workspace + " | " + .app_id + " - " + .name + " (" + .id + ")"'

		WINDOWSLIST="$(
			swaymsg -t get_tree |
				jq -r ".nodes[]
					| {output: .name, content: .nodes[]}
					| {output: .output, workspace: .content.name, apps: .content
					| ..
					| {id: .id?|tostring, name: .name?, app_id: .app_id?, shell: .shell?}
					| select(.app_id != null or .shell != null)}
					| {output: .output, workspace: .workspace,
						id: .apps.id, app_id: .apps.app_id, name: .apps.name }
					| $FORMAT
					| tostring
				"
		)"

		# Get the container ID from the node tree
		CHOICES="$(
			cat <<EOF
$icon_cls Close Menu
$icon_arl Previous Workspace
$icon_arr Next Workspace
$WINDOWSLIST
EOF
		)"

		PICKED="$(printf "%s" "$CHOICES" | dmenu -p "Switch menu" -I "$SWITCHINDEX")"
		SWITCHINDEX="$(($(printf "%s" "$CHOICES" | grep -nm1 "^$PICKED$" | cut -d: -f1) -1))"

		case "$PICKED" in
			""|"$icon_cls Close Menu")
				return
				;;
			"$icon_arr Next Workspace")
				sxmo_wm.sh nextworkspace
				;;
			"$icon_arl Previous Workspace")
				sxmo_wm.sh previousworkspace
				;;
			*)
				# Requires the actual `id` to be at the end and between parentheses
				CON_ID=${PICKED##*(}
				CON_ID=${CON_ID%)}
				swaymsg "[con_id=$CON_ID]" focus
				;;
		esac
	done
}

if [ -n "$1" ]; then
	"$SXMO_WM$1"
	exit
fi

"$SXMO_WM"wmmenu
