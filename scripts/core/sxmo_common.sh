#!/bin/sh

# This script is meant to be sourced by various sxmo scripts
# and defines some common settings

# we disable shellcheck SC2034 (variable not used)
# for all the variables we define here
# shellcheck disable=SC2034

# Small optimization to guard against including the script unnecessarily
[ "$SXMO_COMMON_INCLUDED" = "1" ] && return 0;

# Determine current operating system see os-release(5)
# https://www.linux.org/docs/man5/os-release.html
if [ -e /etc/os-release ]; then
	# shellcheck source=/dev/null
	. /etc/os-release
elif [ -e /usr/lib/os-release ]; then
	# shellcheck source=/dev/null
	. /usr/lib/os-release
fi
export OS="${ID:-unknown}"

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/dev/shm/user/$(id -u)}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export NOTIFDIR="${XDG_DATA_HOME:-$HOME/.local/share}"/sxmo/notifications
export CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}"/sxmo
export DEBUGLOG="$CACHEDIR/sxmo.log"
export LOGDIR="${XDG_DATA_HOME:-$HOME/.local/share}"/sxmo/modem
export BLOCKDIR="${XDG_DATA_HOME:-$HOME/.local/share}"/sxmo/block
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export CONTACTFILE="$XDG_CONFIG_HOME/sxmo/contacts.tsv"
export BLOCKFILE="$XDG_CONFIG_HOME/sxmo/block.tsv"
export UNSUSPENDREASONFILE="$XDG_RUNTIME_DIR/sxmo.suspend.reason"
export LASTSTATE="$XDG_RUNTIME_DIR/sxmo.suspend.laststate"
export MMS_BASE_DIR="$HOME/.mms/modemmanager"
export MMS_AUTO_DELETE="${SXMO_MMS_AUTO_DELETE:-1}"
export MMS_KEEP_MMSFILE="${SXMO_MMS_KEEP_MMSFILE:-1}"
export VVM_AUTO_DELETE="${SXMO_VVM_AUTO_DELETE:-1}"
export VVM_AUTO_MARKREAD="${SXMO_VVM_AUTO_MARKREAD:-0}"
export VVM_BASE_DIR="$HOME/.vvm/modemmanager"

command -v "$KEYBOARD" > /dev/null || export KEYBOARD=svkbd-mobile-intl
command -v "$EDITOR" > /dev/null || export EDITOR=vis

# This script ensures all sxmo scripts are using the busybox version of
# certain coreutils rather than any other version that may be installed on the
# user's computer

#aliases aren't expanded in bash
# shellcheck disable=SC2039,SC3044
command -v shopt > /dev/null && shopt -s expand_aliases

alias dmenu="sxmo_dmenu.sh"
alias jq="gojq" # better performances

# Use native commands if busybox was compile without those apples (for example Debians busybox)
if busybox pkill -l > /dev/null; then
	alias pkill="busybox pkill"
	alias pgrep="busybox pgrep"
fi
alias find="busybox find"
alias grep="busybox grep"
alias less="busybox less"
alias more="busybox more"
alias netstat="busybox netstat"
alias tail="busybox tail"
alias xargs="busybox xargs"

SXMO_COMMON_INCLUDED=1

icon_chk="[x]" #we override this later if the user wants icons
icon_wif="W" #we override this later if the user wants icons

[ "$SXMO_NO_ICONS" = "1" ] && return 0;

#this script is meant to be sourced
#the glyphs are often in the private use area and
#therefore require a font like those in https://github.com/ryanoasis/nerd-fonts/ for proper display
# note that you should *not* use glyphs in range U+F500 - U+FD46 as these wont render.
# this is a known bug in nerdfonts: https://github.com/ryanoasis/nerd-fonts/issues/365

icon_itm="" #item (default)
icon_trm='' #terminal
icon_vim=''
icon_tgm='' #telegram
icon_gps='' #gps
icon_msg="" #text
icon_pwr="⏻" #power
icon_cfg="" #configuration cog
icon_cls="" #close
icon_phn="" #phone
icon_dir="" #directory folder
icon_fil="" #file
icon_grd=""
icon_mnu=""
icon_cam=""
icon_net=""
icon_bel=""
icon_mic=""
icon_mmc=""
icon_mus=""
icon_mut="" #mute
icon_spk="" #speaker
icon_spm=""
icon_spl=""
icon_img=""
icon_usr=""
icon_tmr="" #timer
icon_arl=""
icon_arr=""
icon_aru=""
icon_ard=""
icon_ac1=""
icon_ac2=""
icon_ac3=""
icon_ac4=""
icon_mov=""
icon_shr="" #shrink
icon_exp="" #expand
icon_zmi=""
icon_zmo=""
icon_hom=""
icon_rld=""
icon_hdp="" #headphones
icon_lck=""
icon_rss=""
icon_lnk=""
icon_cpy=""
icon_pst=""
icon_fnd="" #search/find
icon_win="" #window
icon_tab=""
icon_flt="" #filter/pipe
icon_glb="" #globe
icon_phl="" #phonelog
icon_inf="" #info
icon_fll="" #flashlight
icon_clk=""
icon_rol="" #rotate left
icon_ror="" #rotate right
icon_upc="" #up in circle
icon_zzz="" #sleep/suspend/crust
icon_out="" #logout
icon_ytb="" #youtube
icon_wtr="" #weather
icon_red="" #reddit
icon_vid="" #video
icon_mvi="" #movie
icon_clc="" #calculator
icon_eml="" #email
icon_edt="" #editor
icon_ffx="" #firefox
icon_ffw="'" #fast forward
icon_fbw=""
icon_pau=""
icon_a2y="⇅"
icon_a2x="⇄"
icon_sav="" #save
icon_ret="" #return
icon_nxt="" #next
icon_prv="" #previous
icon_stp="" #stop
icon_sfl="" #shuffle, random
icon_lst="" #list
icon_kbd="" #keyboard
icon_del="﫧" #delete
icon_grp="" #group
icon_snd="" #send
icon_phx="" #hangup
icon_wn2=""
icon_chk=""
icon_and=""
icon_wif=""
icon_bth=""
icon_pls=""
icon_key=""
icon_bok=""
icon_map=""
icon_att="📎"
icon_chs="♜" #chess
icon_str="" #star
icon_ton=""
icon_tof=""
icon_mod="" # modem
icon_usb="禍" # usb
icon_ear="" # earpiece
icon_dot="" # searching, connecting, etc.
icon_ena="" # enabled
icon_mod="" # modem
icon_usb="" # usb
icon_dof="" # dot off
icon_don="" # dot on

#allow the user to override icons
# shellcheck disable=SC1091
[ -x "$XDG_CONFIG_HOME/sxmo/hooks/icons" ] && . "$XDG_CONFIG_HOME/sxmo/hooks/icons"
