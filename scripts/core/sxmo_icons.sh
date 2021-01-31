#this script is meant to be sourced
#the glyphs are often in the private use area and
#therefore require a font like those in https://github.com/ryanoasis/nerd-fonts/ for proper display
if [ -z "$SXMO_NO_ICONS" ] || [ "$SXMO_NO_ICONS" -eq 0 ]; then
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
    icon_phl="'" #phonelog
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
fi
#allow the user to override icons
if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/icons" ]; then
	"$XDG_CONFIG_HOME/sxmo/hooks/icons"
fi
