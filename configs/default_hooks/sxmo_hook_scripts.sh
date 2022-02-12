#!/bin/sh

# This script will output the content of the scripts menu

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(which sxmo_common.sh)"
# shellcheck source=configs/default_hooks/sxmo_hook_icons.sh
. sxmo_hook_icons.sh

write_line() {
	printf "%s ^ 0 ^ %s\n" "$1" "$2"
}

if [ -f "$XDG_CONFIG_HOME/sxmo/userscripts" ]; then
	cat "$XDG_CONFIG_HOME/sxmo/userscripts"
elif [ -d "$XDG_CONFIG_HOME/sxmo/userscripts" ]; then
	find "$XDG_CONFIG_HOME/sxmo/userscripts" -type f -o -type l | \
		tr '\n' '\0' | \
		xargs -0 -n1 basename | \
		awk "{printf \"$icon_itm %s ^ 0 ^ $XDG_CONFIG_HOME/sxmo/userscripts/%s \\n\", \$0, \$0}" | \
		sort -f
fi

write_line "$icon_mic Record" "sxmo_record.sh"
write_line "$icon_red Reddit" "sxmo_reddit.sh"
write_line "$icon_rss RSS" "sxmo_rss.sh"
write_line "$icon_cam Screenshot" "sxmo_screenshot.sh"
write_line "$icon_cam Screenshot (selection)" "sxmo_screenshot.sh selection"
write_line "$icon_tmr Timer" "sxmo_timer.sh"
write_line "$icon_ytb Youtube" "sxmo_youtube.sh video"
write_line "$icon_ytb Youtube (Audio)" "sxmo_youtube.sh audio"
write_line "$icon_glb Web Search" "sxmo_websearch.sh"
write_line "$icon_wtr Weather" "sxmo_weather.sh"
write_line "$icon_cfg Edit Userscripts" "sxmo_terminal.sh $EDITOR $XDG_CONFIG_HOME/sxmo/userscripts"
