#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

LISGD_THRESHOLD="${SXMO_LISGD_THRESHOLD:-125}"
LISGD_THRESHOLD_PRESSED="${SXMO_LISGD_THRESHOLD_PRESSED:-60}"
LISGD_INPUT_DEVICE="${SXMO_LISGD_INPUT_DEVICE:-"/dev/input/touchscreen"}"

if [ dwm = "$SXMO_WM" ]; then
	case "$(xrandr | grep primary | cut -d' ' -f 5)" in
		right) orientation=1;;
		left) orientation=3;;
		inverted) orientation=2;;
		*) orientation=0;;
	esac
fi

#-g format:
#   fingers,swipe,edge,distance,command
#order matters, only the first match gets executed
lisgd "$@" -d "$LISGD_INPUT_DEVICE" ${orientation:+-o $orientation} \
	-t "$LISGD_THRESHOLD" -T "$LISGD_THRESHOLD_PRESSED" \
	-g "1,DRUL,BR,*,setsid -f sxmo_hook_inputhandler.sh bottomrightcorner >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,DLUR,BL,*,setsid -f sxmo_hook_inputhandler.sh bottomleftcorner >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,ULDR,TL,*,setsid -f sxmo_hook_inputhandler.sh topleftcorner >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,URDL,TR,*,setsid -f sxmo_hook_inputhandler.sh toprightcorner >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,LR,B,L,setsid -f sxmo_hook_inputhandler.sh rightbottomedge >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,RL,B,L,setsid -f sxmo_hook_inputhandler.sh leftbottomedge >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,LR,L,*,setsid -f sxmo_hook_inputhandler.sh rightleftedge >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,RL,R,*,setsid -f sxmo_hook_inputhandler.sh leftrightedge >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,DU,L,*,P,setsid -f sxmo_hook_inputhandler.sh upleftedge >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,UD,L,*,P,setsid -f sxmo_hook_inputhandler.sh downleftedge >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,LR,T,*,P,setsid -f sxmo_hook_inputhandler.sh righttopedge >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,RL,T,*,P,setsid -f sxmo_hook_inputhandler.sh lefttopedge >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,DU,B,*,setsid -f sxmo_hook_inputhandler.sh upbottomedge >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,UD,B,*,setsid -f sxmo_hook_inputhandler.sh downbottomedge >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,UD,T,*,setsid -f sxmo_hook_inputhandler.sh downtopedge >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,DU,T,*,setsid -f sxmo_hook_inputhandler.sh uptopedge >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "2,UD,T,*,setsid -f sxmo_hook_inputhandler.sh twodowntopedge >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "2,UD,B,*,setsid -f sxmo_hook_inputhandler.sh twodownbottomedge >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,DU,R,*,P,setsid -f sxmo_hook_inputhandler.sh uprightedge >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,UD,R,*,P,setsid -f sxmo_hook_inputhandler.sh downrightedge >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,LR,R,S,setsid -f sxmo_hook_inputhandler.sh rightrightedge_short >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,RL,L,S,setsid -f sxmo_hook_inputhandler.sh leftrightedge_short >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,RL,*,L,setsid -f sxmo_hook_inputhandler.sh longoneleft >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,LR,*,L,setsid -f sxmo_hook_inputhandler.sh longoneright >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,DU,*,L,setsid -f sxmo_hook_inputhandler.sh longoneup >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,UD,*,L,setsid -f sxmo_hook_inputhandler.sh longonedown >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,RL,*,M,setsid -f sxmo_hook_inputhandler.sh mediumoneleft >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,LR,*,M,setsid -f sxmo_hook_inputhandler.sh mediumoneright >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,DU,*,M,setsid -f sxmo_hook_inputhandler.sh mediumoneup >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,UD,*,M,setsid -f sxmo_hook_inputhandler.sh mediumonedown >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,RL,*,*,setsid -f sxmo_hook_inputhandler.sh oneleft >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,LR,*,*,setsid -f sxmo_hook_inputhandler.sh oneright >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,DU,*,*,setsid -f sxmo_hook_inputhandler.sh oneup >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,UD,*,*,setsid -f sxmo_hook_inputhandler.sh onedown >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,DRUL,*,*,setsid -f sxmo_hook_inputhandler.sh upleft >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,URDL,*,*,setsid -f sxmo_hook_inputhandler.sh downleft >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,DLUR,*,*,setsid -f sxmo_hook_inputhandler.sh upright >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "1,ULDR,*,*,setsid -f sxmo_hook_inputhandler.sh downright >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "2,RL,*,*,setsid -f sxmo_hook_inputhandler.sh twoleft >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "2,LR,*,*,setsid -f sxmo_hook_inputhandler.sh tworight >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "2,DU,*,*,setsid -f sxmo_hook_inputhandler.sh twoup >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1" \
	-g "2,UD,*,*,setsid -f sxmo_hook_inputhandler.sh twodown >> \"$XDG_STATE_HOME\"/lisgd_execs.log 2>&1"
