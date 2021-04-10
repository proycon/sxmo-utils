#!/usr/bin/env sh

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

pkill -9 lisgd

if [ -z "$LISGD_THRESHOLD" ]; then
	LISGD_THRESHOLD=125
fi
if [ -z "$LISGD_THRESHOLD_PRESSED" ]; then
	LISGD_THRESHOLD_PRESSED=60
fi

if [ -x "$XDG_CONFIG_HOME"/sxmo/hooks/lisgdstart ]; then
	"$XDG_CONFIG_HOME"/sxmo/hooks/lisgdstart "$@" &
else
	#-g format:
	#   fingers,swipe,edge,distance,command
	#order matters, only the first match gets executed
	lisgd "$@" -t "$LISGD_THRESHOLD" -T "$LISGD_THRESHOLD_PRESSED" \
		-g '1,DRUL,BR,*,sxmo_inputhandler.sh bottomrightcorner' \
		-g '1,DLUR,BL,*,sxmo_inputhandler.sh bottomleftcorner' \
		-g '1,ULDR,TL,*,sxmo_inputhandler.sh topleftcorner' \
		-g '1,URDL,TR,*,sxmo_inputhandler.sh toprightcorner' \
		-g '1,LR,B,L,sxmo_inputhandler.sh enter' \
		-g '1,RL,B,L,sxmo_inputhandler.sh back' \
		-g '1,LR,L,*,sxmo_inputhandler.sh prevdesktop' \
		-g '1,RL,R,*,sxmo_inputhandler.sh nextdesktop' \
		-g '1,DU,L,*,P,sxmo_inputhandler.sh volup' \
		-g '1,UD,L,*,P,sxmo_inputhandler.sh voldown' \
		-g '1,LR,T,*,P,sxmo_inputhandler.sh brightnessup' \
		-g '1,RL,T,*,P,sxmo_inputhandler.sh brightnessdown' \
		-g "1,DU,B,*,sxmo_inputhandler.sh showkeyboard" \
		-g "1,UD,B,*,sxmo_inputhandler.sh hidekeyboard" \
		-g "1,UD,T,*,sxmo_inputhandler.sh showmenu" \
		-g "1,DU,T,*,sxmo_inputhandler.sh hidemenu" \
		-g "2,UD,T,*,sxmo_inputhandler.sh showsysmenu" \
		-g "2,UD,B,*,sxmo_inputhandler.sh closewindow" \
		-g "3,UD,B,*,sxmo_inputhandler.sh killwindow" \
		-g '2,RL,*,*,sxmo_inputhandler.sh moveprevdesktop' \
		-g '2,LR,*,*,sxmo_inputhandler.sh movenextdesktop' \
		-g '1,DU,R,*,P,sxmo_inputhandler.sh scrollup_short' \
		-g '1,UD,R,*,P,sxmo_inputhandler.sh scrolldown_short' \
		-g '1,LR,R,S,sxmo_inputhandler.sh scrollright_short' \
		-g '1,RL,L,S,sxmo_inputhandler.sh scrollleft_short' \
		&
fi
