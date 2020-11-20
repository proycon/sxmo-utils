#!/usr/bin/env sh
trap gracefulexit INT TERM
WIN=$(xdotool getwindowfocus)
NOTIFDIR="$XDG_DATA_HOME"/sxmo/notifications

gracefulexit() {
	echo "Gracefully exiting $0"
	kill -9 0
}

programchoicesinit() {
	XPROPOUT="$(xprop -id "$(xdotool getactivewindow)")"
	WMCLASS="${1:-$(echo "$XPROPOUT" | grep WM_CLASS | cut -d ' ' -f3-)}"

	if echo "$WMCLASS" | grep -i "scripts"; then
		# Scripts menu
		CHOICES="
			Record          ^ 0 ^ sxmo_record.sh
			Reddit          ^ 0 ^ sxmo_reddit.sh
			RSS             ^ 0 ^ sxmo_rss.sh
			Timer           ^ 0 ^ sxmo_timer.sh
			Youtube         ^ 0 ^ sxmo_youtube.sh video
			Youtube (Audio) ^ 0 ^ sxmo_youtube.sh audio
			Web Search      ^ 0 ^ sxmo_websearch.sh
			Weather         ^ 0 ^ sxmo_weather.sh
		"
		if [ -x "$XDG_CONFIG_HOME/sxmo/userscripts" ]; then
			CHOICES="
				$(
					find "$XDG_CONFIG_HOME/sxmo/userscripts" \( -type f -o -type l \) -print0 |
					xargs -IF basename F |
					awk '{printf "%s\t^ 0 ^ $XDG_CONFIG_HOME/sxmo/userscripts/%s \n", $0, $0}' |
					sort -f
				)
				$CHOICES
				Edit Userscripts ^ 0 ^ sxmo_files.sh $XDG_CONFIG_HOME/sxmo/userscripts
			"
		fi
		WINNAME=Scripts
	elif echo "$WMCLASS" | grep -i "applications"; then
	# Apps menu
		if [ -x "$XDG_CONFIG_HOME/sxmo/hooks/apps" ]; then
			CHOICES=$("$XDG_CONFIG_HOME/sxmo/hooks/apps")
		else
			CHOICES="
				$(command -v alpine     >/dev/null && echo 'Alpine      ^ 0 ^ st -e alpine')
				$(command -v cmus       >/dev/null && echo 'Cmus        ^ 0 ^ st -e cmus')
				$(command -v emacs      >/dev/null && echo 'Emacs       ^ 0 ^ st -e emacs')
				$(command -v epiphany   >/dev/null && echo 'Epiphany    ^ 0 ^ epiphany')
				$(command -v firefox    >/dev/null && echo 'Firefox     ^ 0 ^ firefox')
				$(command -v foxtrotgps >/dev/null && echo 'Foxtrotgps  ^ 0 ^ foxtrotgps')
				$(command -v geany      >/dev/null && echo 'Geany       ^ 0 ^ geany')
				$(command -v gedit      >/dev/null && echo 'Gedit       ^ 0 ^ gedit')
				$(command -v geeqie     >/dev/null && echo 'Geeqie      ^ 0 ^ geeqie')
				$(command -v htop       >/dev/null && echo 'Htop        ^ 0 ^ st -e htop')
				$(command -v irssi      >/dev/null && echo 'Irssi       ^ 0 ^ st -e irssi')
				$(command -v ii         >/dev/null && echo 'Ii          ^ 0 ^ st -e ii')
				$(command -v ipython    >/dev/null && echo 'IPython     ^ 0 ^ st -e ipython')
				$(command -v lf         >/dev/null && echo 'Lf          ^ 0 ^ st -e lf')
				$(command -v midori     >/dev/null && echo 'Midori      ^ 0 ^ midori')
				$(command -v mutt       >/dev/null && echo 'Mutt        ^ 0 ^ st -e mutt')
				$(command -v nano       >/dev/null && echo 'Nano        ^ 0 ^ st -e nano')
				$(command -v ncmpcpp    >/dev/null && echo 'Ncmpcpp     ^ 0 ^ st -e ncmpcpp')
				$(command -v neomutt    >/dev/null && echo 'Neomutt     ^ 0 ^ st -e neomutt')
				$(command -v neovim     >/dev/null && echo 'Neovim      ^ 0 ^ st -e neovim')
				$(command -v netsurf    >/dev/null && echo 'Netsurf     ^ 0 ^ netsurf')
				$(command -v newsboat   >/dev/null && echo 'Newsboat    ^ 0 ^ st -e newsboat')
				$(command -v nnn        >/dev/null && echo 'Nnn         ^ 0 ^ st -e nnn')
				$(command -v pidgin     >/dev/null && echo 'Pidgin      ^ 0 ^ pidgin')
				$(command -v ranger     >/dev/null && echo 'Ranger      ^ 0 ^ st -e ranger')
				$(command -v sacc       >/dev/null && echo 'Sacc        ^ 0 ^ st -e sacc i-logout.cz/1/bongusta')
				$(command -v sic        >/dev/null && echo 'Sic         ^ 0 ^ st -e sic')
				$(command -v st         >/dev/null && echo "St          ^ 0 ^ st -e $SHELL -l")
				$(command -v surf       >/dev/null && echo 'Surf        ^ 0 ^ surf')
				$(command -v syncthing  >/dev/null && echo 'Syncthing          ^ 0 ^ syncthing')
				$(command -v telegram-desktop >/dev/null && echo 'Telegram     ^ 0 ^ telegram-desktop')
				$(command -v thunar     >/dev/null && echo 'Thunar      ^ 0 ^ st -e thunar')
				$(command -v thunderbird >/dev/null && echo 'Thunderbird     ^ 0 ^ thunderbird')
				$(command -v totem      >/dev/null && echo 'Totem       ^ 0 ^ st -e totem')
				$(command -v tuir       >/dev/null && echo 'Tuir        ^ 0 ^ st -e tuir')
				$(command -v weechat    >/dev/null && echo 'Weechat     ^ 0 ^ st -e weechat')
				$(command -v w3m        >/dev/null && echo 'W3m         ^ 0 ^ st -e w3m duck.com')
				$(command -v vim        >/dev/null && echo 'Vim         ^ 0 ^ st -e vim')
				$(command -v vis        >/dev/null && echo 'Vis         ^ 0 ^ st -e vis')
				$(command -v vlc        >/dev/null && echo 'Vlc         ^ 0 ^ vlc')
				$(command -v xcalc      >/dev/null && echo 'Xcalc       ^ 0 ^ xcalc')
			"
		fi
		WINNAME=Apps
	elif echo "$WMCLASS" | grep -i "config"; then
		# System Control menu
		CHOICES="
			Brightness ↑               ^ 1 ^ sxmo_brightness.sh up
			Brightness ↓               ^ 1 ^ sxmo_brightness.sh down
			Modem Toggle               ^ 1 ^ sxmo_modemmonitortoggle.sh
			Modem Info                 ^ 0 ^ sxmo_modeminfo.sh
			Modem Log                  ^ 0 ^ sxmo_modemlog.sh
			Flash $(
				grep -qE '^0$' /sys/class/leds/white:flash/brightness &&
				printf %b "Off → On" ||  printf %b "On → Off";
				printf %b "^ 1 ^ sxmo_flashtoggle.sh"
			)
			Bar Toggle                 ^ 1 ^ key Alt+b
			Invert Colors              ^ 1 ^ xcalib -a -invert
			Change Timezone            ^ 1 ^ sxmo_timezonechange.sh
			Autorotate $(
				pgrep -f "$(command -v sxmo_rotateautotoggle.sh)" > /dev/null &&
				printf %b "On → Off ^ 0 ^ sxmo_rotateautotoggle.sh &" ||  printf %b "Off → On ^ 0 ^ sxmo_rotateautotoggle.sh &"
			)
			Rotate                     ^ 1 ^ sxmo_rotate.sh rotate
			Upgrade Pkgs               ^ 0 ^ st -e sxmo_upgrade.sh
		"
		WINNAME=Config
	elif echo "$WMCLASS" | grep -i "audioout"; then
		# Audio Out menu
		CURRENTDEV="$(sxmo_audiocurrentdevice.sh)"
		CHOICES="
			Headphones $([ "$CURRENTDEV" = "Headphone" ] && echo "✓") ^ 1 ^ sxmo_audioout.sh Headphones
			Speaker $([ "$CURRENTDEV" = "Line Out" ] && echo "✓")     ^ 1 ^ sxmo_audioout.sh Speaker
			Earpiece $([ "$CURRENTDEV" = "Earpiece" ] && echo "✓")    ^ 1 ^ sxmo_audioout.sh Earpiece
			None $([ "$CURRENTDEV" = "None" ] && echo "✓")            ^ 1 ^ sxmo_audioout.sh None
			Volume ↑                                                  ^ 1 ^ sxmo_vol.sh up
			Volume ↓                                                  ^ 1 ^ sxmo_vol.sh down
		"
		WINNAME="Audio"
	elif echo "$WMCLASS" | grep -i "power"; then
		# Power menu
		CHOICES="
			Lock               ^ 0 ^ sxmo_lock.sh
			Lock (Screen off)  ^ 0 ^ sxmo_lock.sh --screen-off
			Suspend            ^ 0 ^ sxmo_lock.sh --suspend
			Logout             ^ 0 ^ pkill -9 dwm
			Reboot             ^ 0 ^ st -e sudo reboot
			Poweroff           ^ 0 ^ st -e sudo halt
		"
		WINNAME="Power"
	elif echo "$WMCLASS" | grep -i "mpv"; then
		# MPV
		CHOICES="
			Pause        ^ 0 ^ key space
			Seek ←       ^ 1 ^ key Left
			Seek →       ^ 1 ^ key Right
			App Volume ↑ ^ 1 ^ key 0
			App Volume ↓ ^ 1 ^ key 9
			Speed ↑      ^ 1 ^ key bracketright
			Speed ↓      ^ 1 ^ key bracketleft
			Screenshot   ^ 1 ^ key s
			Loopmark     ^ 1 ^ key l
			Info         ^ 1 ^ key i
			Seek Info    ^ 1 ^ key o
		"
		WINNAME=Mpv && return
	elif echo "$WMCLASS" | grep -i "feh"; then
		# Feh
		CHOICES="
			Next →          ^ 1 ^ key space
			Previous ←      ^ 1 ^ key BackSpace
			Zoom +          ^ 1 ^ key up
			Zoom -          ^ 1 ^ key down
			Zoom to fit     ^ 1 ^ key slash
			Zoom to fill    ^ 1 ^ key exlam
			Rotate ↺        ^ 1 ^ key less
			Rotate ↻        ^ 1 ^ key greater
			Flip ⇅          ^ 1 ^ key underscore
			Mirror ⇄        ^ 1 ^ key bar
			Toggle filename ^ 1 ^ key d
		"
		WINNAME=Feh && return
	elif echo "$WMCLASS" | grep -i "sxiv"; then
		# Sxiv
		CHOICES="
			Next →          ^ 1 ^ key space
			Previous ←      ^ 1 ^ key BackSpace
			Zoom +          ^ 1 ^ key equal
			Zoom -          ^ 1 ^ key minus
			Rotate ↺        ^ 1 ^ key less
			Rotate ↻        ^ 1 ^ key greater
			Flip ⇄          ^ 1 ^ key question
			Flip ⇅          ^ 1 ^ key bar
			Thumbnail ⊡     ^ 0 ^ key Return
		"
		WINNAME=Sxiv && return
	elif echo "$WMCLASS" | grep -i "st-256color"; then
		# St
		# First we try to handle the app running inside st:
		WMNAME="${1:-$(echo "$XPROPOUT" | grep -E "^WM_NAME" | cut -d ' ' -f3-)}"
		if echo "$WMNAME" | grep -i -E "\"(vi|vim|vis|nvim|neovim)\""; then
			#Vim in st
			CHOICES="
				Scroll ↑        ^ 1 ^ key Ctrl+Shift+u
				Scroll ↓        ^ 1 ^ key Ctrl+Shift+d
				Command prompt  ^ 0 ^ key Escape Shift+semicolon
				Save            ^ 0 ^ key Escape Shift+semicolon w Return
				Quit		    ^ 0 ^ key Escape Shift+semicolon q Return
				Paste Selection	^ 0 ^ key Escape quotedbl asterisk p
				Paste Clipboard	^ 0 ^ key Escape quotedbl plus p
				Search          ^ 0 ^ key Escape /
				Zoom +          ^ 1 ^ key Ctrl+Shift+Prior
				Zoom -          ^ 1 ^ key Ctrl+Shift+Next
				St menu         ^ 0 ^ sxmo_appmenu.sh st-256color
			"
			WINNAME=Vim
		elif echo "$WMNAME" | grep -i -w "nano"; then
			#Nano in st
			CHOICES="
				Scroll ↑        ^ 1 ^ key Prior
				Scroll ↓        ^ 1 ^ key Next
				Save            ^ 0 ^ key Ctrl+O
				Quit		    ^ 0 ^ key Ctrl+X
				Paste		    ^ 0 ^ key Ctrl+U
				Type complete   ^ 0 ^ key Ctrl+Shift+u
				Copy complete   ^ 0 ^ key Ctrl+Shift+i
				Zoom +          ^ 1 ^ key Ctrl+Shift+Prior
				Zoom -          ^ 1 ^ key Ctrl+Shift+Next
				St menu         ^ 0 ^ sxmo_appmenu.sh st-256color
			"
			WINNAME=Nano
		elif echo "$WMNAME" | grep -i -w "tuir"; then
			#tuir (reddit client) in st
			CHOICES="
				Previous ↑      ^ 1 ^ key k
				Next ↓          ^ 1 ^ key j
				Scroll ↑        ^ 1 ^ key Prior
				Scroll ↓        ^ 1 ^ key Next
				Open            ^ 0 ^ key o
				Back ←          ^ 0 ^ key h
				Comments →      ^ 0 ^ key l
				Post            ^ 0 ^ key c
				Refresh         ^ 0 ^ key r
				Quit		    ^ 0 ^ key q
				Zoom +          ^ 1 ^ key Ctrl+Shift+Prior
				Zoom -          ^ 1 ^ key Ctrl+Shift+Next
				St menu         ^ 0 ^ sxmo_appmenu.sh st-256color
			"
			WINNAME=tuir
		elif echo "$WMNAME" | grep -i -w "w3m"; then
			#w3m
			CHOICES="
				Back ←          ^ 1 ^ key B
				Goto URL        ^ 1 ^ key U
				Next Link       ^ 1 ^ key Tab
				Previous Link   ^ 1 ^ key Shift+Tab
				Open tab        ^ 0 ^ key T
				Close tab       ^ 0 ^ Ctrl+q
				Next tab        ^ 1 ^ key braceright
				Previous tab    ^ 1 ^ key braceleft
				Zoom +          ^ 1 ^ key Ctrl+Shift+Prior
				Zoom -          ^ 1 ^ key Ctrl+Shift+Next
				St menu         ^ 0 ^ sxmo_appmenu.sh st-256color
			"
			WINNAME=w3m
		elif echo "$WMNAME" | grep -i -w "ncmpcpp"; then
			#ncmpcpp
			CHOICES="
				Playlist        ^ 0 ^ key 1
				Browser         ^ 0 ^ key 2
				Search          ^ 0 ^ key 2
				Next track      ^ 0 ^ key greater
				Previous track  ^ 0 ^ key less
				Pause           ^ 0 ^ key p
				Stop            ^ 0 ^ key s
				Toggle repeat   ^ 0 ^ key r
				Toggle random   ^ 0 ^ key z
				Toggle consume  ^ 0 ^ key R
				St menu         ^ 0 ^ sxmo_appmenu.sh st-256color
			"
			WINNAME=ncmpcpp
		else
			STSELMODEON="$(
				echo "$XPROPOUT" | grep -E '^_ST_SELMODE.+=' | cut -d= -f2 | tr -d ' '
			)"
			CHOICES="
				Type complete   ^ 0 ^ key Ctrl+Shift+u
				Copy complete   ^ 0 ^ key Ctrl+Shift+i
				Selmode $(
				  [ "$STSELMODEON" = 1 ] &&
				  printf %b 'On → Off' ||
				  printf %b 'Off → On'
				  printf %b '^ 0 ^ key Ctrl+Shift+s'
				)
				$([ "$STSELMODEON" = 1 ] && echo 'Copy selection ^ 0 ^ key Ctrl+Shift+c')
				Paste           ^ 0 ^ key Ctrl+Shift+v
				Zoom +          ^ 1 ^ key Ctrl+Shift+Prior
				Zoom -          ^ 1 ^ key Ctrl+Shift+Next
				Scroll ↑        ^ 1 ^ key Ctrl+Shift+b
				Scroll ↓        ^ 1 ^ key Ctrl+Shift+f
				Invert          ^ 1 ^ key Ctrl+Shift+x
				Hotkeys         ^ 0 ^ sxmo_appmenu.sh sthotkeys
			"
			WINNAME=St
		fi
	elif echo "$WMCLASS" | grep -i "sthotkeys"; then
		#  St hotkeys
		CHOICES="
			Send Ctrl-C      ^ 0 ^ key Ctrl+c
			Send Ctrl-Z      ^ 0 ^ key Ctrl+z
			Send Ctrl-L      ^ 0 ^ key Ctrl+l
			Send Ctrl-D      ^ 0 ^ key Ctrl+d
			Send Ctrl-A      ^ 0 ^ key Ctrl+a
			Send Ctrl-B      ^ 0 ^ key Ctrl+b
		"
		WINNAME=St
	elif echo "$WMCLASS" | grep -i netsurf; then
		# Netsurf
		CHOICES="
			Pipe URL          ^ 0 ^ sxmo_urlhandler.sh
			Zoom +            ^ 1 ^ key Ctrl+plus
			Zoom -            ^ 1 ^ key Ctrl+minus
			History  ←        ^ 1 ^ key Alt+Left
			History  →        ^ 1 ^ key Alt+Right
		"
		WINNAME=Netsurf
	elif echo "$WMCLASS" | grep surf; then
		# Surf
		CHOICES="
			Navigate    ^ 0 ^ key Ctrl+g
			Link Menu   ^ 0 ^ key Ctrl+d
			Pipe URL    ^ 0 ^ sxmo_urlhandler.sh
			Search Page ^ 0 ^ key Ctrl+f
			Find Next   ^ 0 ^ key Ctrl+n
			Zoom +      ^ 1 ^ key Ctrl+Shift+k
			Zoom -      ^ 1 ^ key Ctrl+Shift+j
			Scroll ↑    ^ 1 ^ key Shift+space
			Scroll ↓    ^ 1 ^ key space
			JS Toggle   ^ 1 ^ key Ctrl+Shift+s
			History ←   ^ 1 ^ key Ctrl+h
			History →   ^ 1 ^ key Ctrl+l
			Refresh     ^ 0 ^ key Ctrl+Shift+r
		"
		WINNAME=Surf
	elif echo "$WMCLASS" | grep -i firefox; then
		# Firefox
		CHOICES="
			Pipe URL          ^ 0 ^ sxmo_urlhandler.sh
			New Tab           ^ 0 ^ key Ctrl+t
			New Window        ^ 0 ^ key Ctrl+n
			Zoom +            ^ 1 ^ key Ctrl+plus
			Zoom -            ^ 1 ^ key Ctrl+minus
			History  ←        ^ 1 ^ key Alt+Left
			History  →        ^ 1 ^ key Alt+Right
			Refresh     ^ 0 ^ key Ctrl+Shift+r
		"
		WINNAME=Firefox
	elif echo "$WMCLASS" | grep -i foxtrot; then
		# Foxtrot GPS
		CHOICES='
			Locations           ^ 0 ^ sxmo_gpsutil.sh menulocations
			Copy                ^ 1 ^ sxmo_gpsutil.sh copy
			Paste               ^ 0 ^ sxmo_gpsutil.sh paste
			Drop Pin            ^ 0 ^ sxmo_gpsutil.sh droppin
			Region Search       ^ 0 ^ sxmo_gpsutil.sh menuregionsearch
			Region Details      ^ 0 ^ sxmo_gpsutil.sh details
			Zoom +              ^ 1 ^ key i
			Zoom -              ^ 1 ^ key o
			Map Type            ^ 0 ^ sxmo_gpsutil.sh menumaptype
			Panel Toggle        ^ 1 ^ key m
			GPSD Toggle         ^ 1 ^ key a
			Locate Me           ^ 0 ^ sxmo_gpsutil.sh gpsgeoclueset
		'
		WINNAME=Maps
	else
		# Default system menu (no matches)
		CHOICES="
			Scripts                                            ^ 0 ^ sxmo_appmenu.sh scripts
			Apps                                               ^ 0 ^ sxmo_appmenu.sh applications
			Files                                              ^ 0 ^ sxmo_files.sh
			$(command -v foxtrotgps >/dev/null && echo 'Maps   ^ 0 ^ foxtrotgps')
			Dialer                                             ^ 0 ^ sxmo_modemdial.sh
			Texts                                              ^ 0 ^ sxmo_modemtext.sh
			$(command -v megapixels >/dev/null && echo 'Camera ^ 0 ^ megapixels')
			Networks                                           ^ 0 ^ sxmo_networks.sh
			Audio                                              ^ 0 ^ sxmo_appmenu.sh audioout
			Config                                             ^ 0 ^ sxmo_appmenu.sh config
			Power                                              ^ 0 ^ sxmo_appmenu.sh power
		"
		WINNAME=Sys
	fi
}

getprogchoices() {
	# E.g. sets CHOICES var
	programchoicesinit "$@"

	# For the Sys menu decorate at top with notifications if >1 notification
	if [ "$WINNAME" = "Sys" ]; then
		NNOTIFICATIONS="$(find "$NOTIFDIR" -type f | wc -l)"
		if [ "$NNOTIFICATIONS" -gt 0 ]; then
			CHOICES="
				Notifications ($NNOTIFICATIONS) ^ 0 ^ sxmo_notificationsmenu.sh
				$CHOICES
			"
		fi
	fi

	# Decorate menu at bottom w/ system menu entry if not system menu
	echo $WINNAME | grep -v Sys && CHOICES="
		$CHOICES
		System Menu   ^ 0 ^ sxmo_appmenu.sh sys
	"

	# Decorate menu at bottom w/ close menu entry
	CHOICES="
		$CHOICES
		Close Menu    ^ 0 ^ quit
	"

	PROGCHOICES="$(echo "$CHOICES" | xargs -0 echo | sed '/^[[:space:]]*$/d' | awk '{$1=$1};1')"
}

key() {
	xdotool windowactivate "$WIN"
	xdotool key --delay 50 --clearmodifiers "$@"
	#--window $WIN
}

quit() {
	exit 0
}

mainloop() {
	getprogchoices "$ARGS"
	echo "$PROGCHOICES" |
	cut -d'^' -f1 |
	dmenu -idx "$DMENUIDX" -l 16 -c -fn "Terminus-30" -p "$WINNAME" | (
		PICKED="$(cat)"
		echo "$PICKED" | grep . || quit
		LOOP="$(echo "$PROGCHOICES" | grep -m1 -F "$PICKED" | cut -d '^' -f2)"
		CMD="$(echo "$PROGCHOICES" | grep -m1 -F "$PICKED" | cut -d '^' -f3)"
		DMENUIDX="$(echo "$PROGCHOICES" | grep -m1 -F -n "$PICKED" | cut -d ':' -f1)"
		echo "Eval: <$CMD> from picked <$PICKED> with loop <$LOOP>"
		if echo "$LOOP" | grep 1; then
			eval "$CMD"
			mainloop
		else
			eval "$CMD" &
			quit
		fi
	) & wait
}

pgrep -f "$(command -v sxmo_appmenu.sh)" | grep -Ev "^${$}$" | xargs kill -TERM
DMENUIDX=0
PICKED=""
ARGS="$*"
mainloop
