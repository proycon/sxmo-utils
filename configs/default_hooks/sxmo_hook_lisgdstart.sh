#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(which sxmo_common.sh)"

LISGD_THRESHOLD="${SXMO_LISGD_THRESHOLD:-125}"
LISGD_THRESHOLD_PRESSED="${SXMO_LISGD_THRESHOLD_PRESSED:-60}"
LISGD_INPUT_DEVICE="${SXMO_LISGD_INPUT_DEVICE:-"/dev/input/touchscreen"}"

if [ dwm = "$SXMO_WM" ]; then
	case "$(xrandr | grep DSI-1 | cut -d' ' -f 5)" in
		right) orientation=1;;
		left) orientation=3;;
		inverted) orientation=2;;
		*) orientation=0;;
	esac
fi

#-g format:
#   fingers,swipe,edge,distance,command
#order matters, only the first match gets executed
exec lisgd "$@" -d "$LISGD_INPUT_DEVICE" ${orientation:+-o $orientation} \
	-t "$LISGD_THRESHOLD" -T "$LISGD_THRESHOLD_PRESSED" \
	-g '1,DRUL,BR,*,sxmo_hook_inputhandler.sh bottomrightcorner' \
	-g '1,DLUR,BL,*,sxmo_hook_inputhandler.sh bottomleftcorner' \
	-g '1,ULDR,TL,*,sxmo_hook_inputhandler.sh topleftcorner' \
	-g '1,URDL,TR,*,sxmo_hook_inputhandler.sh toprightcorner' \
	-g '1,LR,B,L,sxmo_hook_inputhandler.sh rightbottomedge' \
	-g '1,RL,B,L,sxmo_hook_inputhandler.sh leftbottomedge' \
	-g '1,LR,L,*,sxmo_hook_inputhandler.sh rightleftedge' \
	-g '1,RL,R,*,sxmo_hook_inputhandler.sh leftrightedge' \
	-g '1,DU,L,*,P,sxmo_hook_inputhandler.sh upleftedge' \
	-g '1,UD,L,*,P,sxmo_hook_inputhandler.sh downleftedge' \
	-g '1,LR,T,*,P,sxmo_hook_inputhandler.sh righttopedge' \
	-g '1,RL,T,*,P,sxmo_hook_inputhandler.sh lefttopedge' \
	-g "1,DU,B,*,sxmo_hook_inputhandler.sh upbottomedge" \
	-g "1,UD,B,*,sxmo_hook_inputhandler.sh downbottomedge" \
	-g "1,UD,T,*,sxmo_hook_inputhandler.sh downtopedge" \
	-g "1,DU,T,*,sxmo_hook_inputhandler.sh uptopedge" \
	-g "2,UD,T,*,sxmo_hook_inputhandler.sh twodowntopedge" \
	-g "2,UD,B,*,sxmo_hook_inputhandler.sh twodownbottomedge" \
	-g '1,DU,R,*,P,sxmo_hook_inputhandler.sh uprightedge' \
	-g '1,UD,R,*,P,sxmo_hook_inputhandler.sh downrightedge' \
	-g '1,LR,R,S,sxmo_hook_inputhandler.sh rightrightedge_short' \
	-g '1,RL,L,S,sxmo_hook_inputhandler.sh leftrightedge_short' \
	-g '1,RL,*,L,sxmo_hook_inputhandler.sh longoneleft' \
	-g '1,LR,*,L,sxmo_hook_inputhandler.sh longoneright' \
	-g '1,DU,*,L,sxmo_hook_inputhandler.sh longoneup' \
	-g '1,UD,*,L,sxmo_hook_inputhandler.sh longonedown' \
	-g '1,RL,*,M,sxmo_hook_inputhandler.sh mediumoneleft' \
	-g '1,LR,*,M,sxmo_hook_inputhandler.sh mediumoneright' \
	-g '1,DU,*,M,sxmo_hook_inputhandler.sh mediumoneup' \
	-g '1,UD,*,M,sxmo_hook_inputhandler.sh mediumonedown' \
	-g '1,RL,*,*,sxmo_hook_inputhandler.sh oneleft' \
	-g '1,LR,*,*,sxmo_hook_inputhandler.sh oneright' \
	-g '1,DU,*,*,sxmo_hook_inputhandler.sh oneup' \
	-g '1,UD,*,*,sxmo_hook_inputhandler.sh onedown' \
	-g '1,DRUL,*,*,sxmo_hook_inputhandler.sh upleft' \
	-g '1,URDL,*,*,sxmo_hook_inputhandler.sh downleft' \
	-g '1,DLUR,*,*,sxmo_hook_inputhandler.sh upright' \
	-g '1,ULDR,*,*,sxmo_hook_inputhandler.sh downright' \
	-g '2,RL,*,*,sxmo_hook_inputhandler.sh twoleft' \
	-g '2,LR,*,*,sxmo_hook_inputhandler.sh tworight' \
	-g '2,DU,*,*,sxmo_hook_inputhandler.sh twoup' \
	-g '2,UD,*,*,sxmo_hook_inputhandler.sh twodown'
