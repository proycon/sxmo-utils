#!/usr/bin/env sh
trap gracefulexit INT TERM

# include common definitions
# shellcheck source=scripts/core/sxmo_common.sh
. "$(dirname "$0")/sxmo_common.sh"

WIN=$(xdotool getwindowfocus)

gracefulexit() {
	echo "Gracefully exiting $0">&2
	kill -9 0
}

programchoicesinit() {
	XPROPOUT="$(xprop -id "$(xdotool getactivewindow)")"
	WMCLASS="${1:-$(echo "$XPROPOUT" | grep WM_CLASS | cut -d ' ' -f3- | tr '[:upper:]' '[:lower:]')}"
	if [ -z "$XPROPOUT" ]; then
		echo "sxmo_appmenu: detected no active window, no problem, opening system menu" >&2
	else
		echo "sxmo_appmenu: opening menu for wmclass $WMCLASS" >&2
	fi

	case "$WMCLASS" in
	scripts )
		# Scripts menu
		# shellcheck disable=SC2015
		CHOICES="
			$icon_mic Record          ^ 0 ^ sxmo_record.sh
			$icon_red Reddit          ^ 0 ^ sxmo_reddit.sh
			$icon_rss RSS             ^ 0 ^ sxmo_rss.sh
			$(command -v scrot	>/dev/null && echo $icon_cam Screenshot			^ 0 ^ sxmo_screenshot.sh || notify-send failed to take a screenshot)
			$(command -v scrot	>/dev/null && echo $icon_cam Screenshot \(selection\)	^ 0 ^ sxmo_screenshot.sh selection || notify-send failed to take a screenshot)
			$icon_tmr Timer           ^ 0 ^ sxmo_timer.sh
			$icon_ytb Youtube         ^ 0 ^ sxmo_youtube.sh video
			$icon_ytb Youtube (Audio) ^ 0 ^ sxmo_youtube.sh audio
			$icon_glb Web Search      ^ 0 ^ sxmo_websearch.sh
			$icon_wtr Weather         ^ 0 ^ sxmo_weather.sh
		"
		if [ -x "$XDG_CONFIG_HOME/sxmo/userscripts" ]; then
			CHOICES="
				$(
					find "$XDG_CONFIG_HOME/sxmo/userscripts" \( -type f -o -type l \) -print0 |
					xargs -IF basename F |
					awk "{printf \"$icon_itm %s ^ 0 ^ $XDG_CONFIG_HOME/sxmo/userscripts/%s \\n\", \$0, \$0}" |
					sort -f
				)
				$CHOICES
				$icon_cfg Edit Userscripts ^ 0 ^ sxmo_files.sh $XDG_CONFIG_HOME/sxmo/userscripts
			"
		fi
		WINNAME=Scripts
		;;
	applications )
		# Apps menu
		if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/apps" ]; then
			CHOICES=$("$XDG_CONFIG_HOME/sxmo/hooks/apps")
		else
			CHOICES="
				$(command -v aerc       >/dev/null && echo "$icon_eml Aerc    	^ 0 ^ sxmo_terminal.sh aerc")
				$(command -v amfora     >/dev/null && echo "$icon_glb Amfora      ^ 0 ^ sxmo_terminal.sh amfora")
				$(command -v alpine     >/dev/null && echo "$icon_eml Alpine      ^ 0 ^ sxmo_terminal.sh alpine")
				$(command -v anbox-launch >/dev/null && echo "$icon_and Anbox       ^ 0 ^ anbox")
				$(command -v audacity   >/dev/null && echo "$icon_mic Audacity    ^ 0 ^ audacity")
				$(command -v calcurse   >/dev/null && echo "$icon_clk Calcurse    ^ 0 ^ sxmo_terminal.sh calcurse")
				$(command -v cmus       >/dev/null && echo "$icon_mus Cmus        ^ 0 ^ sxmo_terminal.sh cmus")
				$(command -v dino       >/dev/null && echo "$icon_clk Dino        ^ 0 ^ GDK_SCALE=1 dino")
				$(command -v dolphin    >/dev/null && echo "$icon_dir Dolphin     ^ 0 ^ dolphin")
				$(command -v emacs      >/dev/null && echo "$icon_edt Emacs       ^ 0 ^ sxmo_terminal.sh emacs")
				$(command -v epiphany   >/dev/null && echo "$icon_glb Epiphany    ^ 0 ^ epiphany")
				$(command -v firefox    >/dev/null && echo "$icon_ffx Firefox     ^ 0 ^ firefox")
				$(command -v foliate    >/dev/null && echo "$icon_bok Foliate     ^ 0 ^ foliate")
				$(command -v foxtrotgps >/dev/null && echo "$icon_gps Foxtrotgps  ^ 0 ^ foxtrotgps")
				$(command -v geany      >/dev/null && echo "$icon_eml Geany       ^ 0 ^ geany")
				$(command -v gedit      >/dev/null && echo "$icon_edt Gedit       ^ 0 ^ gedit")
				$(command -v geeqie     >/dev/null && echo "$icon_img Geeqie      ^ 0 ^ geeqie")
				$(command -v giara      >/dev/null && echo "$icon_red Giara       ^ 0 ^ giara")
				$(command -v gomuks     >/dev/null && echo "$icon_msg Gomuks      ^ 0 ^ sxmo_terminal.sh gomuks")
				$(command -v gucharmap  >/dev/null && echo "$icon_inf Gucharmap   ^ 0 ^ gucharmap")
				$(command -v hexchat    >/dev/null && echo "$icon_msg Hexchat     ^ 0 ^ hexchat")
				$(command -v htop       >/dev/null && echo "$icon_cfg Htop        ^ 0 ^ sxmo_terminal.sh htop")
				$(command -v irssi      >/dev/null && echo "$icon_msg Irssi       ^ 0 ^ sxmo_terminal.sh irssi")
				$(command -v ii         >/dev/null && echo "$icon_msg Ii          ^ 0 ^ sxmo_terminal.sh ii")
				$(command -v ipython    >/dev/null && echo "$icon_trm IPython     ^ 0 ^ sxmo_terminal.sh ipython")
				$(command -v kmail      >/dev/null && echo "$icon_eml KMail       ^ 0 ^ kmail")
				$(command -v kontact    >/dev/null && echo "$icon_msg Kontact ^ 0 ^ kontact")
				$(command -v konversation   >/dev/null && echo "$icon_msg Konversation ^ 0 ^ konversation")
				$(command -v kwrite     >/dev/null && echo "$icon_edt Kwrite      ^ 0 ^ kwrite")
				$(command -v lagrange   >/dev/null && echo "$icon_glb Lagrange    ^ 0 ^ lagrange")
				$(command -v lf         >/dev/null && echo "$icon_dir Lf          ^ 0 ^ sxmo_terminal.sh lf")
				$(command -v lollypop   >/dev/null && echo "$icon_mus Lollypop    ^ 0 ^ lollypop")
				$(command -v midori     >/dev/null && echo "$icon_glb Midori      ^ 0 ^ midori")
				$(command -v mutt       >/dev/null && echo "$icon_eml Mutt        ^ 0 ^ sxmo_terminal.sh mutt")
				$(command -v nano       >/dev/null && echo "$icon_edt Nano        ^ 0 ^ sxmo_terminal.sh nano")
				$(command -v navit      >/dev/null && echo "$icon_gps Navit       ^ 0 ^ navit")
				$(command -v ncmpcpp    >/dev/null && echo "$icon_mus Ncmpcpp     ^ 0 ^ sxmo_terminal.sh ncmpcpp")
				$(command -v neomutt    >/dev/null && echo "$icon_eml Neomutt     ^ 0 ^ sxmo_terminal.sh neomutt")
				$(command -v nvim       >/dev/null && echo "$icon_vim Neovim      ^ 0 ^ sxmo_terminal.sh nvim")
				$(command -v netsurf    >/dev/null && echo "$icon_glb Netsurf     ^ 0 ^ netsurf")
				$(command -v newsboat   >/dev/null && echo "$icon_rss Newsboat    ^ 0 ^ sxmo_terminal.sh newsboat")
				$(command -v nnn        >/dev/null && echo "$icon_dir Nnn         ^ 0 ^ sxmo_terminal.sh nnn")
				$(command -v pidgin     >/dev/null && echo "$icon_msg Pidgin      ^ 0 ^ pidgin")
				$(command -v pure-maps  >/dev/null && echo "$icon_map Pure-Maps   ^ 0 ^ pure-maps")
				$(command -v profanity  >/dev/null && echo "$icon_msg Profanity   ^ 0 ^ sxmo_terminal.sh profanity")
				$(command -v qutebrowser>/dev/null && echo "$icon_glb Qutebrowser ^ 0 ^ qutebrowser")
				$(command -v ranger     >/dev/null && echo "$icon_dir Ranger      ^ 0 ^ sxmo_terminal.sh ranger")
				$(command -v sacc       >/dev/null && echo "$icon_itm Sacc        ^ 0 ^ sxmo_terminal.sh sacc i-logout.cz/1/bongusta")
				$(command -v sic        >/dev/null && echo "$icon_itm Sic         ^ 0 ^ sxmo_terminal.sh sic")
				$(command -v st         >/dev/null && echo "$icon_trm St          ^ 0 ^ sxmo_terminal.sh $SHELL")
				$(command -v surf       >/dev/null && echo "$icon_glb Surf        ^ 0 ^ surf")
				$(command -v syncthing  >/dev/null && echo "$icon_rld Syncthing          ^ 0 ^ syncthing")
				$(command -v telegram-desktop >/dev/null && echo "$icon_tgm Telegram     ^ 0 ^ telegram-desktop")
				$(command -v thunar     >/dev/null && echo "$icon_dir Thunar      ^ 0 ^ sxmo_terminal.sh thunar")
				$(command -v thunderbird >/dev/null && echo "$icon_eml Thunderbird     ^ 0 ^ thunderbird")
				$(command -v totem      >/dev/null && echo "$icon_mvi Totem       ^ 0 ^ totem")
				$(command -v tuir       >/dev/null && echo "$icon_red Tuir        ^ 0 ^ sxmo_terminal.sh tuir")
				$(command -v weechat    >/dev/null && echo "$icon_msg Weechat     ^ 0 ^ sxmo_terminal.sh weechat")
				$(command -v w3m        >/dev/null && echo "$icon_glb W3m         ^ 0 ^ sxmo_terminal.sh w3m duck.com")
				$(command -v vim        >/dev/null && echo "$icon_vim Vim         ^ 0 ^ sxmo_terminal.sh vim")
				$(command -v vis        >/dev/null && echo "$icon_vim Vis         ^ 0 ^ sxmo_terminal.sh vis")
				$(command -v vlc        >/dev/null && echo "$icon_mvi Vlc         ^ 0 ^ vlc")
				$(command -v xcalc      >/dev/null && echo "$icon_clc Xcalc       ^ 0 ^ xcalc")
			"
		fi
		WINNAME=Apps
		;;
	config )
		# System Control menu
		CHOICES="
			$icon_aru Brightness               ^ 1 ^ sxmo_brightness.sh up
			$icon_ard Brightness               ^ 1 ^ sxmo_brightness.sh down
			$icon_phn Modem Toggle               ^ 1 ^ sxmo_modemmonitortoggle.sh
			$icon_inf Modem Info                 ^ 0 ^ sxmo_modeminfo.sh
			$icon_phl Modem Log                  ^ 0 ^ sxmo_modemlog.sh
			$icon_fll Flashlight $(
				grep -qE '^0$' /sys/class/leds/white:flash/brightness &&
				printf %b "Off → On" ||  printf %b "On → Off";
				printf %b "^ 1 ^ sxmo_flashtoggle.sh"
			)
			$icon_cfg Bar Toggle                 ^ 1 ^ key Super+b
			$icon_cfg Invert Colors              ^ 1 ^ xcalib -a -invert
			$icon_clk Change Timezone            ^ 1 ^ sxmo_timezonechange.sh
			$icon_ror Autorotate $(
				pgrep -f "$(command -v sxmo_rotateautotoggle.sh)" > /dev/null &&
				printf %b "On → Off ^ 0 ^ sxmo_rotateautotoggle.sh &" ||  printf %b "Off → On ^ 0 ^ sxmo_rotateautotoggle.sh &"
			)
			$icon_lck Proximity Lock $(
				pgrep -f "$(command -v sxmo_proximitylock.sh)" > /dev/null &&
				printf %b "On → Off ^ 0 ^ sxmo_proximitylocktoggle.sh &" ||  printf %b "Off → On ^ 0 ^ sxmo_proximitylocktoggle.sh &"
			)
			$icon_ror Rotate                     ^ 1 ^ sxmo_rotate.sh rotate
			$icon_upc Upgrade Pkgs               ^ 0 ^ sxmo_terminal.sh sxmo_upgrade.sh
			$icon_cfg Edit configuration         ^ 0 ^ sxmo_terminal.sh $EDITOR $XDG_CONFIG_HOME/sxmo/xinit
			$(command -v pmos-tweaks && echo "$icon_cfg PostmarketOS Tweaks	     ^ 0 ^ GDK_SCALE=1 pmos-tweaks")
		"
		WINNAME=Config
		;;
	audioout )
		# Audio Out menu
		CURRENTDEV="$(sxmo_audiocurrentdevice.sh)"
		CHOICES="
			$icon_hdp Headphones $([ "$CURRENTDEV" = "Headphone" ] && echo "$icon_chk") ^ 1 ^ sxmo_audioout.sh Headphones
			$icon_spk Speaker $([ "$CURRENTDEV" = "Line Out" ] && echo "$icon_chk")     ^ 1 ^ sxmo_audioout.sh Speaker
			$icon_phn Earpiece $([ "$CURRENTDEV" = "Earpiece" ] && echo "$icon_chk")    ^ 1 ^ sxmo_audioout.sh Earpiece
			$icon_mut None $([ "$CURRENTDEV" = "None" ] && echo "$icon_chk")            ^ 1 ^ sxmo_audioout.sh None
			$icon_aru Volume up                                       ^ 1 ^ sxmo_vol.sh up
			$icon_ard Volume down                                     ^ 1 ^ sxmo_vol.sh down
		"
		WINNAME="Audio"
		;;
	power )
		# Power menu
		CHOICES="
			$icon_lck Lock               ^ 0 ^ sxmo_screenlock.sh lock && sxmo_unlocklistener.sh
			$icon_lck Lock (Screen off)  ^ 0 ^ sxmo_screenlock.sh off && sxmo_unlocklistener.sh
			$icon_zzz Suspend            ^ 0 ^ sxmo_screenlock.sh lock && sxmo_screenlock.sh crust
			$icon_out Logout             ^ 0 ^ pkill -9 dwm
			$icon_rld Reboot             ^ 0 ^ sxmo_terminal.sh sudo reboot
			$icon_pwr Poweroff           ^ 0 ^ sxmo_terminal.sh sudo poweroff
		"
		WINNAME="Power"
		;;
	*mpv* )
		# MPV
		CHOICES="
			$icon_pau Pause        ^ 0 ^ key space
			$icon_fbw Seek       ^ 1 ^ key Left
			$icon_ffw Seek       ^ 1 ^ key Right
			$icon_aru App Volume ↑ ^ 1 ^ key 0
			$icon_ard App Volume ↓ ^ 1 ^ key 9
			$icon_aru Speed up      ^ 1 ^ key bracketright
			$icon_ard Speed down    ^ 1 ^ key bracketleft
			$icon_cam Screenshot   ^ 1 ^ key s
			$icon_itm Loopmark     ^ 1 ^ key l
			$icon_inf Info         ^ 1 ^ key i
			$icon_inf Seek Info    ^ 1 ^ key o
		"
		WINNAME=Mpv && return
		;;
	*feh* )
		# Feh
		CHOICES="
			$icon_arr Next          ^ 1 ^ key space
			$icon_arl Previous      ^ 1 ^ key BackSpace
			$icon_zmi Zoom in       ^ 1 ^ key up
			$icon_zmo Zoom out      ^ 1 ^ key down
			$icon_exp Zoom to fit   ^ 1 ^ key slash
			$icon_shr Zoom to fill  ^ 1 ^ key exlam
			$icon_rol Rotate        ^ 1 ^ key less
			$icon_ror Rotate        ^ 1 ^ key greater
			$icon_a2y Flip          ^ 1 ^ key underscore
			$icon_a2x Mirror        ^ 1 ^ key bar
			$icon_inf Toggle filename ^ 1 ^ key d
		"
		WINNAME=Feh && return
		;;
	*sxiv* )
		# Sxiv
		CHOICES="
			$icon_arr Next          ^ 1 ^ key space
			$icon_arl Previous      ^ 1 ^ key BackSpace
			$icon_zmi Zoom in       ^ 1 ^ key equal
			$icon_zmo Zoom out      ^ 1 ^ key minus
			$icon_rol Rotate        ^ 1 ^ key less
			$icon_ror Rotate        ^ 1 ^ key greater
			$icon_a2y Flip          ^ 1 ^ key question
			$icon_a2x Mirror        ^ 1 ^ key bar
			$icon_grd Thumbnail     ^ 0 ^ key Return
		"
		WINNAME=Sxiv && return
		;;
	*st-256color* )
		# St
		# First we try to handle the app running inside st:
		WMNAME="${1:-$(echo "$XPROPOUT" | grep -E "^WM_NAME" | cut -d ' ' -f3-)}"
		if echo "$WMNAME" | grep -i -E "(vi|vim|vis|nvim|neovim|kakoune)"; then
			#Vim in st
			CHOICES="
				$icon_aru Scroll up        ^ 1 ^ key Ctrl+Shift+u
				$icon_ard Scroll down      ^ 1 ^ key Ctrl+Shift+d
				$icon_trm Command prompt   ^ 0 ^ key Escape Shift+semicolon
				$icon_cls Save             ^ 0 ^ key Escape Shift+semicolon w Return
				$icon_cls Save and Quit    ^ 0 ^ key Escape Shift+semicolon w q Return
				$icon_cls Quit without saving  ^ 0 ^ key Escape Shift+semicolon q exclam Return
				$icon_pst Paste Selection  ^ 0 ^ key Escape quotedbl asterisk p
				$icon_pst Paste Clipboard  ^ 0 ^ key Escape quotedbl plus p
				$icon_fnd Search           ^ 0 ^ key Escape /
				$icon_zmi Zoom in          ^ 1 ^ key Ctrl+Shift+Prior
				$icon_zmo Zoom out         ^ 1 ^ key Ctrl+Shift+Next
				$icon_mnu St menu          ^ 0 ^ sxmo_appmenu.sh st-256color
			"
			WINNAME=Vim
		elif echo "$WMNAME" | grep -i -w "nano"; then
			#Nano in st
			CHOICES="
				$icon_aru Scroll up       ^ 1 ^ key Prior
				$icon_ard Scroll down     ^ 1 ^ key Next
				$icon_sav Save            ^ 0 ^ key Ctrl+O
				$icon_cls Quit            ^ 0 ^ key Ctrl+X
				$icon_pst Paste           ^ 0 ^ key Ctrl+U
				$icon_itm Type complete   ^ 0 ^ key Ctrl+Shift+u
				$icon_cpy Copy complete   ^ 0 ^ key Ctrl+Shift+i
				$icon_zmi Zoom in         ^ 1 ^ key Ctrl+Shift+Prior
				$icon_zmo Zoom out        ^ 1 ^ key Ctrl+Shift+Next
				$icon_mnu St menu         ^ 0 ^ sxmo_appmenu.sh st-256color
			"
			WINNAME=Nano
		elif echo "$WMNAME" | grep -i -w "tuir"; then
			#tuir (reddit client) in st
			CHOICES="
				$icon_aru Previous      ^ 1 ^ key k
				$icon_ard Next          ^ 1 ^ key j
				$icon_aru Scroll up     ^ 1 ^ key Prior
				$icon_ard Scroll down   ^ 1 ^ key Next
				$icon_ret Open          ^ 0 ^ key o
				$icon_arl Back          ^ 0 ^ key h
				$icon_arr Comments      ^ 0 ^ key l
				$icon_edt Post          ^ 0 ^ key c
				$icon_rld Refresh       ^ 0 ^ key r
				$icon_cls Quit          ^ 0 ^ key q
				$icon_zmi Zoom in       ^ 1 ^ key Ctrl+Shift+Prior
				$icon_zmo Zoom out      ^ 1 ^ key Ctrl+Shift+Next
				$icon_mnu St menu       ^ 0 ^ sxmo_appmenu.sh st-256color
			"
			WINNAME=tuir
		elif echo "$WMNAME" | grep -i -w "w3m"; then
			#w3m
			CHOICES="
				$icon_arl Back          ^ 1 ^ key B
				$icon_glb Goto URL        ^ 1 ^ key U
				$icon_arr Next Link       ^ 1 ^ key Tab
				$icon_arl Previous Link   ^ 1 ^ key Shift+Tab
				$icon_tab Open tab        ^ 0 ^ key T
				$icon_cls Close tab       ^ 0 ^ Ctrl+q
				$icon_itm Next tab        ^ 1 ^ key braceright
				$icon_itm Previous tab    ^ 1 ^ key braceleft
				$icon_zmi Zoom in          ^ 1 ^ key Ctrl+Shift+Prior
				$icon_zmo Zoom out          ^ 1 ^ key Ctrl+Shift+Next
				$icon_mnu St menu         ^ 0 ^ sxmo_appmenu.sh st-256color
			"
			WINNAME=w3m
		elif echo "$WMNAME" | grep -i -w "ncmpcpp"; then
			#ncmpcpp
			CHOICES="
				$icon_lst Playlist        ^ 0 ^ key 1
				$icon_fnd Browser         ^ 0 ^ key 2
				$icon_fnd Search          ^ 0 ^ key 3
				$icon_nxt Next track      ^ 0 ^ key greater
				$icon_prv Previous track  ^ 0 ^ key less
				$icon_pau Pause           ^ 0 ^ key p
				$icon_stp Stop            ^ 0 ^ key s
				$icon_rld Toggle repeat   ^ 0 ^ key r
				$icon_sfl Toggle random   ^ 0 ^ key z
				$icon_itm Toggle consume  ^ 0 ^ key R
				$icon_mnu St menu         ^ 0 ^ sxmo_appmenu.sh st-256color
			"
			WINNAME=ncmpcpp
		elif echo "$WMNAME" | grep -i -w "aerc"; then
			#aerc
			CHOICES="
				$icon_pau Archive	  ^ 1 ^ typeenter ':archive flat'
				$icon_nxt Next Tab	  ^ 0 ^ typeenter ':next-tab'
				$icon_prv Previous Tab	  ^ 0 ^ typeenter ':prev-tab'
				$icon_cls Close Tab	  ^ 0 ^ typeenter ':close'
				$icon_itm Next Part	  ^ 1 ^ typeenter ':next-part'
				$icon_trm xdg-open Part	  ^ 0 ^ typeenter ':open'
			"
			WINNAME=aerc
		elif echo "$WMNAME" | grep -i -E -w "(less|mless)"; then
			#less
			CHOICES="
				$icon_arr Page next       ^ 1 ^ typeenter ':n'
				$icon_arl Page previous   ^ 1 ^ typeenter ':p'
				$icon_cls Quit            ^ 0 ^ key q
				$icon_zmi Zoom in         ^ 1 ^ key Ctrl+Shift+Prior
				$icon_zmo Zoom out        ^ 1 ^ key Ctrl+Shift+Next
				$icon_aru Scroll up       ^ 1 ^ key Ctrl+Shift+b
				$icon_ard Scroll down     ^ 1 ^ key Ctrl+Shift+f
				$icon_mnu St menu       ^ 0 ^ sxmo_appmenu.sh st-256color
			"
			WINNAME=less
		elif echo "$WMNAME" | grep -i -w "weechat"; then
			#weechat
			CHOICES="
				$icon_msg Hotlist Next            ^ 1 ^ key Alt+a
				$icon_arl History Previous        ^ 1 ^ key Alt+Shift+comma
				$icon_arr History Next            ^ 1 ^ key Alt+Shift+period
				$icon_trm Buffer                  ^ 0 ^ type '/buffer '
				$icon_aru Scroll up               ^ 1 ^ key Prior
				$icon_ard Scroll down             ^ 1 ^ key Next
				$icon_mnu St menu       ^ 0 ^ sxmo_appmenu.sh st-256color
			"
			WINNAME=weechat
		elif echo "$WMNAME" | grep -i -w "sms"; then
			number="$(echo "$WMNAME" | sed -e 's|^\"||' -e 's|\"$||' | cut -f1 -d' ')"
			#sms
			CHOICES="
				$icon_msg Reply          ^ 0 ^ sxmo_modemtext.sh sendtextmenu $number
				$icon_phn Call           ^ 0 ^ sxmo_modemdial.sh $number
			"
			WINNAME=sms
		elif echo "$WMNAME" | grep -i -w "cmus"; then
			# cmus
			# requires `:set set_term_title=false` in cmus to match the application
			CHOICES="
				$icon_itm Play            ^ 0 ^ cmus-remote -p
				$icon_pau Pause           ^ 0 ^ cmus-remote -u
				$icon_stp Stop            ^ 0 ^ cmus-remote -s
				$icon_nxt Next track      ^ 0 ^ cmus-remote -n
				$icon_prv Previous track  ^ 0 ^ cmus-remote -r
				$icon_rld Toggle repeat   ^ 0 ^ cmus-remote -R
				$icon_sfl Toggle random   ^ 0 ^ cmus-remote -S
				$icon_mnu St menu         ^ 0 ^ sxmo_appmenu.sh st-256color
			"
			WINNAME=cmus
		else
			STSELMODEON="$(
				echo "$XPROPOUT" | grep -E '^_ST_SELMODE.+=' | cut -d= -f2 | tr -d ' '
			)"
			CHOICES="
				$icon_itm Type complete   ^ 0 ^ key Ctrl+Shift+u
				$icon_cpy Copy complete   ^ 0 ^ key Ctrl+Shift+i
				$icon_itm Selmode $(
				  [ "$STSELMODEON" = 1 ] &&
				  printf %b 'On → Off' ||
				  printf %b 'Off → On'
				  printf %b '^ 0 ^ key Ctrl+Shift+s'
				)
				$([ "$STSELMODEON" = 1 ] && echo 'Copy selection ^ 0 ^ key Ctrl+Shift+c')
				$icon_pst Paste           ^ 0 ^ key Ctrl+Shift+v
				$icon_zmi Zoom in         ^ 1 ^ key Ctrl+Shift+Prior
				$icon_zmo Zoom out        ^ 1 ^ key Ctrl+Shift+Next
				$icon_aru Scroll up       ^ 1 ^ key Ctrl+Shift+b
				$icon_ard Scroll down     ^ 1 ^ key Ctrl+Shift+f
				$icon_a2x Invert          ^ 1 ^ key Ctrl+Shift+x
				$icon_kbd Hotkeys         ^ 0 ^ sxmo_appmenu.sh sthotkeys
			"
			WINNAME=St
		fi
		;;
	*sthotkeys* )
		#  St hotkeys
		CHOICES="
			Send Ctrl-C      ^ 0 ^ key Ctrl+c
			Send Ctrl-Z      ^ 0 ^ key Ctrl+z
			Send Ctrl-L      ^ 0 ^ key Ctrl+l
			Send Ctrl-D      ^ 0 ^ key Ctrl+d
			Send Ctrl-A      ^ 0 ^ key Ctrl+a
			Send Ctrl-B      ^ 0 ^ key Ctrl+b
			Send ESC:w       ^ 0 ^ key Escape Shift+semicolon w Return
			Send ESC:wq      ^ 0 ^ key Escape Shift+semicolon w q Return
			Send ESC:wq!     ^ 0 ^ key Escape Shift+semicolon q exclam Return
		"
		WINNAME=St
		;;
	*netsurf* )
		# Netsurf
		CHOICES="
			$icon_flt Pipe URL          ^ 0 ^ sxmo_urlhandler.sh
			$icon_zmi Zoom            ^ 1 ^ key Ctrl+plus
			$icon_zmo Zoom            ^ 1 ^ key Ctrl+minus
			$icon_arl History        ^ 1 ^ key Alt+Left
			$icon_arr History        ^ 1 ^ key Alt+Right
		"
		WINNAME=Netsurf
		;;
	*surf* )
		# Surf
		CHOICES="
			$icon_glb Navigate    ^ 0 ^ key Ctrl+g
			$icon_lnk Link Menu   ^ 0 ^ key Ctrl+d
			$icon_flt Pipe URL    ^ 0 ^ sxmo_urlhandler.sh
			$icon_fnd Search Page ^ 0 ^ key Ctrl+f
			$icon_fnd Find Next   ^ 0 ^ key Ctrl+n
			$icon_zmi Zoom      ^ 1 ^ key Ctrl+Shift+k
			$icon_zmo Zoom      ^ 1 ^ key Ctrl+Shift+j
			$icon_aru Scroll    ^ 1 ^ key Shift+space
			$icon_ard Scroll    ^ 1 ^ key space
			$icon_itm JS Toggle   ^ 1 ^ key Ctrl+Shift+s
			$icon_arl History   ^ 1 ^ key Ctrl+h
			$icon_arr History   ^ 1 ^ key Ctrl+l
			$icon_rld Refresh     ^ 0 ^ key Ctrl+Shift+r
		"
		WINNAME=Surf
		;;
	*firefox* )
		# Firefox
		CHOICES="
			$icon_flt Pipe URL          ^ 0 ^ sxmo_urlhandler.sh
			$icon_tab New Tab           ^ 0 ^ key Ctrl+t
			$icon_win New Window        ^ 0 ^ key Ctrl+n
			$icon_cls Close Tab         ^ 0 ^ key Ctrl+w
			$icon_zmi Zoom            ^ 1 ^ key Ctrl+plus
			$icon_zmo Zoom            ^ 1 ^ key Ctrl+minus
			$icon_arl History        ^ 1 ^ key Alt+Left
			$icon_arr History        ^ 1 ^ key Alt+Right
			$icon_rld Refresh     ^ 0 ^ key Ctrl+Shift+r
		"
		WINNAME=Firefox
		;;
	*lagrange* )
		# Lagrange
		CHOICES="
			$icon_mnu Toggle sidebar ^ 0 ^ key Ctrl+Shift+p
			$icon_bok Open bookmarks ^ 0 ^ key Ctrl+l && typeenter 'about:bookmarks'
			$icon_pls Add bookmark   ^ 0 ^ key Ctrl+d
			$icon_zmi Zoom           ^ 1 ^ key Ctrl+equal
			$icon_zmo Zoom           ^ 1 ^ key Ctrl+minus
			$icon_aru Parent dir     ^ 1 ^ key Alt+Up
			$icon_arl History        ^ 1 ^ key Alt+Left
			$icon_arr History        ^ 1 ^ key Alt+Right
			$icon_rld Refresh        ^ 0 ^ key Ctrl+r
		"
		WINNAME=Lagrange
		;;
	*foxtrot* )
		# Foxtrot GPS
		CHOICES="
			$icon_itm Locations           ^ 0 ^ sxmo_gpsutil.sh menulocations
			$icon_cpy Copy                ^ 1 ^ sxmo_gpsutil.sh copy
			$icon_pst Paste               ^ 0 ^ sxmo_gpsutil.sh paste
			$icon_itm Drop Pin            ^ 0 ^ sxmo_gpsutil.sh droppin
			$icon_fnd Region Search       ^ 0 ^ sxmo_gpsutil.sh menuregionsearch
			$icon_itm Region Details      ^ 0 ^ sxmo_gpsutil.sh details
			$icon_zmi Zoom              ^ 1 ^ key i
			$icon_zmo Zoom              ^ 1 ^ key o
			$icon_itm Map Type            ^ 0 ^ sxmo_gpsutil.sh menumaptype
			$icon_itm Panel Toggle        ^ 1 ^ key m
			$icon_itm GPSD Toggle         ^ 1 ^ key a
			$icon_usr Locate Me           ^ 0 ^ sxmo_gpsutil.sh gpsgeoclueset
		"
		WINNAME=Maps
		;;
	* )
		# Default system menu (no matches)
		CHOICES="
			$icon_grd Scripts                                            ^ 0 ^ sxmo_appmenu.sh scripts
			$icon_grd Apps                                               ^ 0 ^ sxmo_appmenu.sh applications
			$icon_dir Files                                              ^ 0 ^ sxmo_files.sh
			$(command -v foxtrotgps >/dev/null && echo "$icon_gps Maps   ^ 0 ^ foxtrotgps")
			$icon_phn Dialer                                             ^ 0 ^ sxmo_modemdial.sh
			$icon_msg Texts                                              ^ 0 ^ sxmo_modemtext.sh
			$icon_usr Contacts                                           ^ 0 ^ sxmo_contactmenu.sh
			$(command -v bluetoothctl >/dev/null && echo "$icon_bth Bluetooth ^ 0 ^ sxmo_bluetoothmenu.sh")
			$(command -v megapixels >/dev/null && echo "$icon_cam Camera ^ 0 ^ GDK_SCALE=2 megapixels")
			$icon_net Networks                                           ^ 0 ^ sxmo_networks.sh
			$icon_mus Audio                                              ^ 0 ^ sxmo_appmenu.sh audioout
			$icon_cfg Config                                             ^ 0 ^ sxmo_appmenu.sh config
			$icon_pwr Power                                              ^ 0 ^ sxmo_appmenu.sh power
		"
		WINNAME=Sys
		;;
	esac
}

getprogchoices() {
	# E.g. sets CHOICES var
	programchoicesinit "$@"


	# For the Sys menu decorate at top with notifications if >1 notification
	if [ "$WINNAME" = "Sys" ]; then
		NNOTIFICATIONS="$(find "$NOTIFDIR" -type f | wc -l)"
		if [ "$NNOTIFICATIONS" -gt 0 ]; then
			CHOICES="
				$icon_bel Notifications ($NNOTIFICATIONS) ^ 0 ^ sxmo_notificationsmenu.sh
				$CHOICES
			"
		fi
	fi

	#shellcheck disable=SC2044
	for NOTIFFILE in $(find "$NOTIFDIR" -name 'incomingcall*_notification'); do
		NOTIFACTION="$(head -n1 "$NOTIFFILE")"
		MESSAGE="$(tail -1 "$NOTIFFILE")"
		CHOICES="
			$icon_phn $MESSAGE ^ 0 ^ $NOTIFACTION
			$CHOICES
		"
		break
	done

	# Decorate menu at bottom w/ system menu entry if not system menu
	echo $WINNAME | grep -v Sys && CHOICES="
		$CHOICES
		$icon_mnu System Menu   ^ 0 ^ sxmo_appmenu.sh sys
	"

	# Decorate menu at bottom w/ close menu entry
	CHOICES="
		$CHOICES
		$icon_cls Close Menu    ^ 0 ^ quit
	"

	PROGCHOICES="$(echo "$CHOICES" | xargs -0 echo | sed '/^[[:space:]]*$/d' | awk '{$1=$1};1')"
}

key() {
	xdotool windowactivate "$WIN"
	xdotool key --delay 50 --clearmodifiers "$@"
	#--window $WIN
}

type() {
	xdotool windowactivate "$WIN"
	xdotool type --delay 50 --clearmodifiers "$@"
}

typeenter() {
	type "$@"
	xdotool key Return
}

quit() {
	exit 0
}

mainloop() {
	getprogchoices "$ARGS"
	echo "$PROGCHOICES" |
	cut -d'^' -f1 |
	dmenu -idx "$DMENUIDX" -l 16 -c -p "$WINNAME" | (
		PICKED="$(cat)"
		echo "$PICKED" | grep . || quit
		LOOP="$(echo "$PROGCHOICES" | grep -m1 -F "$PICKED" | cut -d '^' -f2)"
		CMD="$(echo "$PROGCHOICES" | grep -m1 -F "$PICKED" | cut -d '^' -f3)"
		DMENUIDX="$(echo "$PROGCHOICES" | grep -m1 -F -n "$PICKED" | cut -d ':' -f1)"
		echo "sxmo_appmenu: Eval: <$CMD> from picked <$PICKED> with loop <$LOOP>">&2
		if echo "$LOOP" | grep 1; then
			eval "$CMD"
			mainloop
		else
			eval "$CMD" &
			quit
		fi
	) & wait
}

pgrep -f "$(command -v sxmo_appmenu.sh)" | grep -Ev "^${$}$" | xargs -r kill -TERM
DMENUIDX=0
PICKED=""
ARGS="$*"
mainloop
