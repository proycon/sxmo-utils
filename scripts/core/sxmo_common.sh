#!/usr/bin/env sh

# This script is meant to be sourced by various sxmo scripts
# and defines some common settings

# Small optimization to guard against including the script unnecessarily
[ "$SXMO_COMMON_INCLUDED" = "1" ] && return 0;

# we disable shellcheck SC2034 (variable not used)
# for all the variables we define here

# shellcheck disable=SC2034
export NOTIFDIR="$XDG_DATA_HOME"/sxmo/notifications
# shellcheck disable=SC2034
export CACHEDIR="$XDG_CACHE_HOME"/sxmo
# shellcheck disable=SC2034
export LOGDIR="$XDG_DATA_HOME"/sxmo/modem

command -v "$KEYBOARD" > /dev/null || export KEYBOARD=svkbd-mobile-intl

# This script ensures all sxmo scripts are using the busybox version of
# certain coreutils rather than any other version that may be installed on the
# user's computer

#aliases aren't expanded in bash
# shellcheck disable=SC2039
command -v shopt > /dev/null && shopt -s expand_aliases

alias find="busybox find"
alias pkill="busybox pkill"
alias pgrep="busybox pgrep"
alias xargs="busybox xargs"

SXMO_COMMON_INCLUDED=1

# shellcheck disable=SC2034
icon_chk="[x]" #we override this later if the user wants icons

[ "$SXMO_NO_ICONS" = "1" ] && return 0;

#this script is meant to be sourced
#the glyphs are often in the private use area and
#therefore require a font like those in https://github.com/ryanoasis/nerd-fonts/ for proper display

# shellcheck disable=SC2034
icon_itm="" #item (default)
# shellcheck disable=SC2034
icon_trm='' #terminal
# shellcheck disable=SC2034
icon_vim=''
# shellcheck disable=SC2034
icon_tgm='' #telegram
# shellcheck disable=SC2034
icon_gps='' #gps
# shellcheck disable=SC2034
icon_msg="" #text
# shellcheck disable=SC2034
icon_pwr="⏻" #power
# shellcheck disable=SC2034
icon_cfg="" #configuration cog
# shellcheck disable=SC2034
icon_cls="" #close
# shellcheck disable=SC2034
icon_phn="" #phone
# shellcheck disable=SC2034
icon_dir="" #directory folder
# shellcheck disable=SC2034
icon_fil="" #file
# shellcheck disable=SC2034
icon_grd=""
# shellcheck disable=SC2034
icon_mnu=""
# shellcheck disable=SC2034
icon_cam=""
# shellcheck disable=SC2034
icon_net=""
# shellcheck disable=SC2034
icon_bel=""
# shellcheck disable=SC2034
icon_mic=""
# shellcheck disable=SC2034
icon_mmc=""
# shellcheck disable=SC2034
icon_mus=""
# shellcheck disable=SC2034
icon_mut="" #mute
# shellcheck disable=SC2034
icon_spk="" #speaker
# shellcheck disable=SC2034
icon_img=""
# shellcheck disable=SC2034
icon_usr=""
# shellcheck disable=SC2034
icon_tmr="" #timer
# shellcheck disable=SC2034
icon_arl=""
# shellcheck disable=SC2034
icon_arr=""
# shellcheck disable=SC2034
icon_aru=""
# shellcheck disable=SC2034
icon_ard=""
# shellcheck disable=SC2034
icon_ac1=""
# shellcheck disable=SC2034
icon_ac2=""
# shellcheck disable=SC2034
icon_ac3=""
# shellcheck disable=SC2034
icon_ac4=""
# shellcheck disable=SC2034
icon_mov=""
# shellcheck disable=SC2034
icon_shr="" #shrink
# shellcheck disable=SC2034
icon_exp="" #expand
# shellcheck disable=SC2034
icon_zmi=""
# shellcheck disable=SC2034
icon_zmo=""
# shellcheck disable=SC2034
icon_hom=""
# shellcheck disable=SC2034
icon_rld=""
# shellcheck disable=SC2034
icon_hdp="" #headphones
# shellcheck disable=SC2034
icon_lck=""
# shellcheck disable=SC2034
icon_rss=""
# shellcheck disable=SC2034
icon_lnk=""
# shellcheck disable=SC2034
icon_cpy=""
# shellcheck disable=SC2034
icon_pst=""
# shellcheck disable=SC2034
icon_fnd="" #search/find
# shellcheck disable=SC2034
icon_win="" #window
# shellcheck disable=SC2034
icon_tab=""
# shellcheck disable=SC2034
icon_flt="" #filter/pipe
# shellcheck disable=SC2034
icon_glb="" #globe
# shellcheck disable=SC2034
icon_phl="" #phonelog
# shellcheck disable=SC2034
icon_inf="" #info
# shellcheck disable=SC2034
icon_fll="" #flashlight
# shellcheck disable=SC2034
icon_clk=""
# shellcheck disable=SC2034
icon_rol="" #rotate left
# shellcheck disable=SC2034
icon_ror="" #rotate right
# shellcheck disable=SC2034
icon_upc="" #up in circle
# shellcheck disable=SC2034
icon_zzz="" #sleep/suspend/crust
# shellcheck disable=SC2034
icon_out="" #logout
# shellcheck disable=SC2034
icon_ytb="" #youtube
# shellcheck disable=SC2034
icon_wtr="" #weather
# shellcheck disable=SC2034
icon_red="" #reddit
# shellcheck disable=SC2034
icon_vid="" #video
# shellcheck disable=SC2034
icon_mvi="" #movie
# shellcheck disable=SC2034
icon_clc="" #calculator
# shellcheck disable=SC2034
icon_eml="" #email
# shellcheck disable=SC2034
icon_edt="" #editor
# shellcheck disable=SC2034
icon_ffx="" #firefox
# shellcheck disable=SC2034
icon_ffw="'" #fast forward
# shellcheck disable=SC2034
icon_fbw=""
# shellcheck disable=SC2034
icon_pau=""
# shellcheck disable=SC2034
icon_a2y="⇅"
# shellcheck disable=SC2034
icon_a2x="⇄"
# shellcheck disable=SC2034
icon_sav="" #save
# shellcheck disable=SC2034
icon_ret="" #return
# shellcheck disable=SC2034
icon_nxt="" #next
# shellcheck disable=SC2034
icon_prv="" #previous
# shellcheck disable=SC2034
icon_stp="" #stop
# shellcheck disable=SC2034
icon_sfl="" #shuffle, random
# shellcheck disable=SC2034
icon_lst="" #list
# shellcheck disable=SC2034
icon_kbd="" #keyboard
# shellcheck disable=SC2034
icon_del="﫧" #delete
# shellcheck disable=SC2034
icon_grp="" #group
# shellcheck disable=SC2034
icon_snd="" #send
# shellcheck disable=SC2034
icon_phx="" #hangup
# shellcheck disable=SC2034
icon_wn2=""
# shellcheck disable=SC2034
icon_chk=""

#allow the user to override icons
if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/icons" ]; then
	"$XDG_CONFIG_HOME/sxmo/hooks/icons"
fi
