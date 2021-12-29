#!/bin/sh
#
# Initial author: Adrien Le Guillou
# License: MIT
#
# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

set -e # error if a command as non 0 exit
set -u # error if undefined variable


# Default parameters
FORMAT="W:%W | %A - %T"
DMENU="sxmo_dmenu.sh"

# FORMAT as a `jq` concatenation string
FORMAT="$FORMAT (%I)"
FORMAT=$(echo "$FORMAT" | \
        sed  's/%O/" + .output + "/
              s/%W/" + .workspace + "/
              s/%A/" + .app_id + "/
              s/%T/" + .name + "/
              s/%I/" + .id + "/
              s/"/\"/
              s/\(.*\)/\"\1\"/')

# Get the container ID from the node tree
selection=$(swaymsg -t get_tree | \
    jq -r ".nodes[]
        | {output: .name, content: .nodes[]}
        | {output: .output, workspace: .content.name,
          apps: .content
            | ..
            | {id: .id?|tostring, name: .name?, app_id: .app_id?, shell: .shell?}
            | select(.app_id != null or .shell != null)}
        | {output: .output, workspace: .workspace,
           id: .apps.id, app_id: .apps.app_id, name: .apps.name }
        | $FORMAT
        | tostring" | \
    awk '(1){print} END{printf "Previous Workspace\nNext Workspace\n"}' | \
    $DMENU -i -p "Window Switcher")


case "$selection" in
"Next Workspace")
	sxmo_wm.sh nextworkspace
	;;
"Previous Workspace")
	sxmo_wm.sh previousworkspace
	;;
*)
	# Requires the actual `id` to be at the end and between parentheses
	CON_ID=${selection##*(}
	CON_ID=${CON_ID%)}
	swaymsg "[con_id=$CON_ID]" focus
	;;
esac
