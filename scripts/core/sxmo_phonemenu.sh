#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

set -e

number="$(printf "%s" "$1" | sed -e "s/^tel://")"

number="$(sxmo_validnumber.sh "$number")"

result="$(printf "%s Call %s\n%s Text %s\n%s Save %s\n%s Close Menu\n" \
	"$icon_phn" "$number" "$icon_msg" "$number" "$icon_sav" "$number" \
	"$icon_cls" \
	| sxmo_dmenu.sh -p "Action")"

case "$result" in
	*Call*)
		sxmo_modemdial.sh "$number"
		;;
	*Text*)
		sxmo_modemtext.sh sendtextmenu "$number"
		;;
	*Save*)
		sxmo_contactmenu.sh newcontact "$number"
		;;
esac
