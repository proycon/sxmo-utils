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
icon_ac1="↖"
icon_ac2="↗"
icon_ac3="↘"
icon_ac4="↙"
icon_and=""
icon_ard="↓"
icon_arl="←"
icon_arr="→"
icon_aru="↑"
icon_att=""
icon_audio="♫"
icon_bel=""
icon_bok=""
icon_brightness="󰃝"
icon_bth="" # bluetooth
icon_cal=""
icon_cam=""
icon_cfg="" #configuration cog
icon_chk=""
icon_chs="♜" #chess
icon_clc="󰃬" #calculator
icon_clk="󰥔"
icon_cls="󰅖" #close
icon_com="" # (Laptop) Computer (💻)
icon_cpy=""
icon_del="" #delete
icon_dir="" #directory folder
icon_dof="" # dot off
icon_don="" # dot on
icon_dop="" # dot point
icon_dot="󰇘" # searching, connecting, etc.
icon_drw="󰏬" # Drawing tablet
icon_ear="" # earpiece
icon_edt="󰎞" #editor
icon_eml="󰇮" #email
icon_exp="󰁌" #expand
icon_fbw=""
icon_ffw="" #fast forward
icon_ffx="" #firefox
icon_fil="" #file
icon_flk="" #falkon
icon_fll="󰉄" #flashlight
icon_flt="" #filter/pipe
icon_fnd="󰍉" #search/find
icon_gam="󰊴" # gaming controller (🎮)
icon_glb="" #globe
icon_gps='' #gps
icon_grd="󰀻"
icon_grp="" #group
icon_hdp="" #headphones
icon_hom=""
icon_img="󰏜"
icon_inf="" #info
icon_itm="" #item (default)
icon_kbd="" #keyboard
icon_key=""
icon_lck=""
icon_lnk=""
icon_lst="" #list
icon_map="󰍍"
icon_mdd="󰄢" # modem disabled state
icon_mic="󰍬"
icon_mmc="󰍭"
icon_mnu=""
icon_mod="" # modem
icon_mov="󰁁"
icon_mse="󰍽" # computer mouse (🖱️)
icon_msg="󰍦" #text
icon_mus="󰎈"
icon_mut="" #mute
icon_mvi="󰎁" #movie
icon_net="󰀂"
icon_nto="" #no touch
icon_nxt="" #next
icon_out="󰍃" #logout
icon_pau=""
icon_phl="󰏹" #phonelog
icon_phn="󰏲" #phone
icon_phx="󰏵" #hangup
icon_plk="󰏸" # phone locked
icon_pls=""
icon_prn="" # printer (🖨️)
icon_prv="" #previous
icon_pst=""
icon_pwr="⏻" #power
icon_red="" #reddit
icon_ret="󰌑" #return
icon_rld=""
icon_rol="" #rotate left
icon_ror="" #rotate right
icon_rss=""
icon_sav="󰆓" #save
icon_sfl="" #shuffle, random
icon_shr="󰁄" #shrink
icon_snd="" #send
icon_spk="" #speaker
icon_spl=""
icon_spm=""
icon_stp="" #stop
icon_str="" #star
icon_tab=""
icon_tgm='' #telegram
icon_tmr="󰀠" #timer
icon_tof=""
icon_ton=""
icon_trh="" # trash
icon_trm='' #terminal
icon_upc="󰁠" #up in circle
icon_usb="" # usb
icon_usr="󰀄"
icon_vid="" #video
icon_vim=''
icon_wif=""
icon_wfo="󰖪" # wifi off
icon_wfh="󰀂" # wifi hotspot
icon_win="" #window
icon_wat="" # watch (⌚)
icon_wn2=""
icon_wrh=""
icon_wtr="" #weather
icon_ytb="" #youtube
icon_zmi="󰛭" # Zoom in/magnify
icon_zmo="󰛬" # Zoom out/demagnify
icon_zzz="" #sleep/suspend/crust

# modem states

icon_modem_nomodem="󰥍" # cell with x
icon_modem_locked="󰥏" # cell with lock
icon_modem_initializing="󰥑" # cell with gear
icon_modem_disabled="󰥐" # cell with slash
icon_modem_disabling="$icon_arr$icon_modem_disabled" # -> disabled
icon_modem_enabled="󱟽" # cell with check
icon_modem_enabling="$icon_arr$icon_modem_enabled" # -> enabled
icon_modem_registered="󱋘" # cell with wifi with slash
icon_modem_searching="$icon_arr$icon_modem_registered" # -> registered
icon_modem_connected="󰺐" # cell with wifi
icon_modem_connecting="$icon_aru$icon_modem_connected" # up arrow connected
icon_modem_disconnecting="$icon_ard$icon_modem_connected" # down arrow connected
icon_modem_failed="󰽁" # cell with !

# modem techs
icon_modem_fiveg="󰩯" # 5gnr
icon_modem_fourg="󰜔" # lte
icon_modem_threeg="󰜓" # a lot (see sxmo_hook_statusbar.sh)
icon_modem_hspa="󰜕" # hspa
icon_modem_hspa_plus="󰜖" # hspa plus
icon_modem_twog="󰜒" # edge, pots, gsm, gprs, etc.
icon_modem_notech="󰞃" # disabled cell bars

# modem signal strengths
icon_modem_signal_0="󰢿"
icon_modem_signal_1="󰢼"
icon_modem_signal_2="󰢽"
icon_modem_signal_3="󰢾"

# wifi signal strengths
icon_wifi_signal_exclam="󰤫"
icon_wifi_key_signal_0="󰤬"
icon_wifi_signal_0="󰤯"
icon_wifi_key_signal_1="󰤡"
icon_wifi_signal_1="󰤟"
icon_wifi_key_signal_2="󰤤"
icon_wifi_signal_2="󰤢"
icon_wifi_key_signal_3="󰤧"
icon_wifi_signal_3="󰤥"
icon_wifi_key_signal_4="󰤪"
icon_wifi_signal_4="󰤨"
icon_wifi_disconnected="󰤮"

# battery indicators
icon_bat_c_0="󰢟"
icon_bat_c_1="󱊤"
icon_bat_c_2="󱊥"
icon_bat_c_3="󰂅"
icon_bat_0="󰂎"
icon_bat_1="󱊡"
icon_bat_2="󱊢"
icon_bat_3="󱊣"

# sxmo state indicators
icon_state_proximity=""
icon_state_screenoff=""
icon_state_lock=""
icon_state_unlock=""
