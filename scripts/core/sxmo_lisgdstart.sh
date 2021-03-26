#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

pkill -9 lisgd

if [ -x "$XDG_CONFIG_HOME"/sxmo/hooks/lisgdstart ]; then
	"$XDG_CONFIG_HOME"/sxmo/hooks/lisgdstart &
else
	#-g format:
	#   fingers,swipe,edge,distance,command
	#order matters, only the first match gets executed
	lisgd "$@" -t 125 \
		-g '1,DRUL,BR,*,sxmo_hotcorner.sh bottomright' \
		-g '1,DLUR,BL,*,sxmo_hotcorner.sh bottomleft' \
		-g '1,ULDR,TL,*,sxmo_hotcorner.sh topleft' \
		-g '1,DRUL,TR,*,sxmo_hotcorner.sh topright' \
		-g '1,LR,B,L,sxmo_gesturehandler.sh enter' \
		-g '1,RL,B,L,sxmo_gesturehandler.sh back' \
		-g '1,LR,L,*,sxmo_gesturehandler.sh prevdesktop' \
		-g '1,RL,R,*,sxmo_gesturehandler.sh nextdesktop' \
		-g '1,DU,L,*,P,sxmo_gesturehandler.sh volup' \
		-g '1,UD,L,*,P,sxmo_gesturehandler.sh voldown' \
		-g '1,LR,T,*,P,sxmo_gesturehandler.sh brightnessup' \
		-g '1,RL,T,*,P,sxmo_gesturehandler.sh brightnessdown' \
		-g "1,DU,B,*,sxmo_gesturehandler.sh showkeyboard" \
		-g "1,UD,B,*,sxmo_gesturehandler.sh hidekeyboard" \
		-g "1,UD,T,*,sxmo_gesturehandler.sh showmenu" \
		-g "1,DU,T,*,sxmo_gesturehandler.sh hidemenu" \
		-g "2,UD,T,*,sxmo_gesturehandler.sh showsysmenu" \
		-g "2,UD,B,*,sxmo_gesturehandler.sh closewindow" \
		-g "3,UD,B,*,sxmo_gesturehandler.sh killwindow" \
		-g '2,RL,*,*,sxmo_gesturehandler.sh moveprevdesktop' \
		-g '2,LR,*,*,sxmo_gesturehandler.sh movenextdesktop' \
		-g '1,DU,R,*,P,sxmo_gesturehandler.sh scrollup_short' \
		-g '1,UD,R,*,P,sxmo_gesturehandler.sh scrolldown_short' \
		-g '1,LR,R,S,sxmo_gesturehandler.sh scrollright_short' \
		-g '1,RL,L,S,sxmo_gesturehandler.sh scrollleft_short' \
		&
fi
