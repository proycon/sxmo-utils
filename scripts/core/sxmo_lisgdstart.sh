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
		-g '1,LR,B,L,sxmo_inputhandler.sh rightbottomcorner' \
		-g '1,RL,B,L,sxmo_inputhandler.sh leftbottomcorner' \
		-g '1,LR,L,*,sxmo_inputhandler.sh rightleftcorner' \
		-g '1,RL,R,*,sxmo_inputhandler.sh leftrightcorner' \
		-g '1,DU,L,*,P,sxmo_inputhandler.sh upleftcorner' \
		-g '1,UD,L,*,P,sxmo_inputhandler.sh downleftcorner' \
		-g '1,LR,T,*,P,sxmo_inputhandler.sh righttopcorner' \
		-g '1,RL,T,*,P,sxmo_inputhandler.sh lefttopcorner' \
		-g "1,DU,B,*,sxmo_inputhandler.sh upbottomcorner" \
		-g "1,UD,B,*,sxmo_inputhandler.sh downbottomcorner" \
		-g "1,UD,T,*,sxmo_inputhandler.sh downtopcorner" \
		-g "1,DU,T,*,sxmo_inputhandler.sh uptopcorner" \
		-g "2,UD,T,*,sxmo_inputhandler.sh twodowntopcorner" \
		-g "2,UD,B,*,sxmo_inputhandler.sh twodownbottomcorner" \
		-g "r,UD,B,*,sxmo_inputhandler.sh threedownbottomcorner" \
		-g '1,DU,R,*,P,sxmo_inputhandler.sh uprightcorner' \
		-g '1,UD,R,*,P,sxmo_inputhandler.sh downrightcorner' \
		-g '1,LR,R,S,sxmo_inputhandler.sh rightrightcorner_short' \
		-g '1,RL,L,S,sxmo_inputhandler.sh leftrightcorner_short' \
		-g '1,RL,*,*,sxmo_inputhandler.sh left' \
		-g '1,LR,*,*,sxmo_inputhandler.sh right' \
		-g '1,DU,*,*,sxmo_inputhandler.sh up' \
		-g '1,UD,*,*,sxmo_inputhandler.sh down' \
		-g '2,RL,*,*,sxmo_inputhandler.sh twoleft' \
		-g '2,LR,*,*,sxmo_inputhandler.sh tworight' \
		-g '2,DU,*,*,sxmo_inputhandler.sh twoup' \
		-g '2,UD,*,*,sxmo_inputhandler.sh twodown' \
		>"$CACHEDIR/lisgd.log" 2>&1 &
fi
