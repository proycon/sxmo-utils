#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

modem_n() {
	MODEMS="$(mmcli -L)"
	echo "$MODEMS" | grep -oE 'Modem\/([0-9]+)' | cut -d'/' -f2
	return
}

sim_n() {
	SIMS="$(mmcli -m "$(modem_n)" | grep SIM)"
	echo "$SIMS" | grep -oE 'SIM\/([0-9]+)' | cut -d'/' -f2
	return
}

if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/unlocksim" ]; then
	"$XDG_CONFIG_HOME/sxmo/hooks/unlocksim" "$(sim_n)"
else
	retry=1
	pkill dmenu #kill existing dmenu
	while [ $retry -eq 1 ]; do
		PICKED="$(
			# shellcheck disable=SC2039,SC3037
			echo -e "Cancel\n0000\n1234" | sxmo_dmenu_with_kb.sh -l 3 -c -p "PIN:" | tr -d "\n\r "
		)"
		if [ -n "$PICKED" ] && [ "$PICKED" != "Cancel" ]; then
			retry=0
			mmcli -i "$(sim_n)" --pin "$PICKED" > /tmp/unlockmsg 2>&1 || retry=1
			MSG=$(cat /tmp/unlockmsg)
			[ -n "$MSG" ] && notify-send "$MSG"
			if echo "$MSG" | grep -q "not SIM-PIN locked"; then
				retry=0
			fi
		else
			retry=0
		fi
	done
fi
