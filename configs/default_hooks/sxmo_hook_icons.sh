#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# we disable shellcheck SC2034 (variable not used)
# for all the variables we define here
# shellcheck disable=SC2034

#this script is meant to be sourced
#the glyphs are often in the private use area and
#therefore require a font like those in https://github.com/ryanoasis/nerd-fonts/ for proper display
# note that you should *not* use glyphs in range U+F500 - U+FD46 as these wont render.
# this is a known bug in nerdfonts: https://github.com/ryanoasis/nerd-fonts/issues/365

icon_a2x="⇄"
icon_a2y="⇅"
icon_ac1=""
icon_ac2=""
icon_ac3=""
icon_ac4=""
icon_and=""
icon_ard=""
icon_arl=""
icon_arr=""
icon_aru=""
icon_att=""
icon_bel=""
icon_bok=""
icon_btd="" # bluethooth device
icon_bth="" # bluetooth
icon_cam=""
icon_cfg="" #configuration cog
icon_chk=""
icon_chs="♜" #chess
icon_clc="" #calculator
icon_clk=""
icon_cls="" #close
icon_cpy=""
icon_del="﫧" #delete
icon_dir="" #directory folder
icon_dof="" # dot off
icon_don="" # dot on
icon_dot="" # searching, connecting, etc.
icon_ear="" # earpiece
icon_edt="" #editor
icon_eml="" #email
icon_ena="" # enabled
icon_exp="" #expand
icon_fbw=""
icon_ffw="" #fast forward
icon_ffx="" #firefox
icon_fil="" #file
icon_fll="" #flashlight
icon_flt="" #filter/pipe
icon_fnd="" #search/find
icon_glb="" #globe
icon_gps='' #gps
icon_grd=""
icon_grp="" #group
icon_hdp="" #headphones
icon_hom=""
icon_img=""
icon_inf="" #info
icon_itm="" #item (default)
icon_kbd="" #keyboard
icon_key=""
icon_lck=""
icon_lnk=""
icon_lst="" #list
icon_map=""
icon_mdd="" # modem disabled state
icon_mic=""
icon_mmc=""
icon_mnu=""
icon_mod="" # modem
icon_mov=""
icon_msg="" #text
icon_mus=""
icon_mut="" #mute
icon_mvi="" #movie
icon_net=""
icon_nto="" #no touch
icon_nxt="" #next
icon_out="" #logout
icon_pau=""
icon_phl="" #phonelog
icon_phn="" #phone
icon_phx="" #hangup
icon_plk="" # phone locked
icon_pls=""
icon_prv="" #previous
icon_pst=""
icon_pwr="⏻" #power
icon_red="" #reddit
icon_ret="" #return
icon_rld=""
icon_rol="" #rotate left
icon_ror="" #rotate right
icon_rss=""
icon_sav="" #save
icon_sfl="" #shuffle, random
icon_shr="" #shrink
icon_snd="" #send
icon_spk="" #speaker
icon_spl=""
icon_spm=""
icon_stp="" #stop
icon_str="" #star
icon_tab=""
icon_tgm='' #telegram
icon_tmr="" #timer
icon_tof=""
icon_ton=""
icon_trh="" # trash
icon_trm='' #terminal
icon_upc="" #up in circle
icon_usb="" # usb
icon_usr=""
icon_vid="" #video
icon_vim=''
icon_wif=""
icon_win="" #window
icon_wn2=""
icon_wrh=""
icon_wtr="" #weather
icon_ytb="" #youtube
icon_zmi=""
icon_zmo=""
icon_zzz="" #sleep/suspend/crust

