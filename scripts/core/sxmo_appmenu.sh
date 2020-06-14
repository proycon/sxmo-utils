#!/usr/bin/env sh
WIN=$(xdotool getwindowfocus)

programchoicesinit() {
	XPROPOUT="$(xprop -id "$(xdotool getactivewindow)")"
	WMCLASS="${1:-$(echo "$XPROPOUT" | grep WM_CLASS | cut -d ' ' -f3-)}"

	if echo "$WMCLASS" | grep -i "userscripts"; then
		# Userscripts menu
		CHOICES="$(
			find "$XDG_CONFIG_HOME/sxmo/userscripts" -type f -print0 | 
			xargs -IF basename F | 
			awk '{printf "%s\t^ 0 ^ $XDG_CONFIG_HOME/sxmo/userscripts/%s \n", $0, $0}'
		)"
		WINNAME=Userscripts
	elif echo "$WMCLASS" | grep -i "scripts"; then
		# Scripts menu
		CHOICES="
			Web Search      ^ 0 ^ sxmo_websearch.sh
			Record          ^ 0 ^ sxmo_record.sh
			Timer           ^ 0 ^ sxmo_timer.sh
			Youtube         ^ 0 ^ sxmo_youtube.sh video
			Youtube (Audio) ^ 0 ^ sxmo_youtube.sh audio
			Weather         ^ 0 ^ sxmo_weather.sh
			RSS             ^ 0 ^ sxmo_rss.sh
		"
		WINNAME=Scripts
	elif echo "$WMCLASS" | grep -i "applications"; then
	# Apps menu
		CHOICES="
			Surf            ^ 0 ^ surf
			Netsurf         ^ 0 ^ netsurf
			Firefox         ^ 0 ^ firefox
			Sacc            ^ 0 ^ st -e sacc i-logout.cz/1/bongusta
			W3m             ^ 0 ^ st -e w3m duck.com
			Xcalc           ^ 0 ^ xcalc
			St              ^ 0 ^ st
			Foxtrotgps      ^ 0 ^ foxtrotgps
		"
		WINNAME=Apps
	elif echo "$WMCLASS" | grep -i "config"; then
		# System Control menu
		CHOICES="
			Brightesss ↑               ^ 1 ^ sxmo_brightness.sh up
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
			Change Timezone            ^ 1 ^ sxmo_timezonechange.sh
			Rotate                     ^ 1 ^ sxmo_rotate.sh
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
	elif echo "$WMCLASS" | grep -i "st-256color"; then
		#  St
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
	elif echo "$WMCLASS" | grep -i "sthotkeys"; then
		#  St hotkeys
		CHOICES="
			Send Ctrl-C      ^ 0 ^ key Ctrl+c
			Send Ctrl-L      ^ 0 ^ key Ctrl+l
			Send Ctrl-D      ^ 0 ^ key Ctrl+d
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
			Zoom +      ^ 1 ^ key Ctrl+Shift+k
			Zoom -      ^ 1 ^ key Ctrl+Shift+j
			Scroll ↑    ^ 1 ^ key Shift+space
			Scroll ↓    ^ 1 ^ key space
			JS Toggle   ^ 1 ^ key Ctrl+Shift+s
			History ←   ^ 1 ^ key Ctrl+h
			History →   ^ 1 ^ key Ctrl+l
		"
		WINNAME=Surf
	elif echo "$WMCLASS" | grep -i firefox; then
		# Firefox
		CHOICES="
			Pipe URL          ^ 0 ^ sxmo_urlhandler.sh
			Zoom +            ^ 1 ^ key Ctrl+plus
			Zoom -            ^ 1 ^ key Ctrl+minus
			History  ←        ^ 1 ^ key Alt+Left
			History  →        ^ 1 ^ key Alt+Right
		"
		WINNAME=Firefox
	elif echo "$WMCLASS" | grep -i foxtrot; then
		# Foxtrot GPS
		CHOICES="
			Zoom +            ^ 1 ^ key i
			Zoom -            ^ 1 ^ key o
			Panel toggle      ^ 1 ^ key m
			Autocenter toggle ^ 0 ^ key a
			Route             ^ 0 ^ key r
		"
		WINNAME=Gps
	else
		# Default system menu (no matches)
		CHOICES="
			$(
				[ -n "$(ls -A "$XDG_CONFIG_HOME"/sxmo/userscripts)" ] && 
				echo 'Userscripts  ^ 0 ^ sxmo_appmenu.sh userscripts'
			)
			Scripts              ^ 0 ^ sxmo_appmenu.sh scripts
			Apps                 ^ 0 ^ sxmo_appmenu.sh applications
			Files                ^ 0 ^ sxmo_files.sh
			Dialer               ^ 0 ^ sxmo_modemcall.sh dial
			Texts                ^ 0 ^ sxmo_modemtext.sh
			Camera               ^ 0 ^ sxmo_camera.sh
			Wifi                 ^ 0 ^ st -e nmtui
			Audio                ^ 0 ^ sxmo_appmenu.sh audioout
			Config               ^ 0 ^ sxmo_appmenu.sh config
			Logout               ^ 0 ^ pkill -9 dwm
		"
		WINNAME=Sys
	fi
}

getprogchoices() {
	# E.g. sets CHOICES var
	programchoicesinit "$@"

	# Decorate menu at top w/ incoming call entry if present
	INCOMINGCALL="$(cat /tmp/sxmo_incomingcall || echo NOCALL)"
	echo "$INCOMINGCALL" | grep -v NOCALL && CHOICES="
		Pickup $(echo "$INCOMINGCALL" | cut -d: -f2) ^ 0 ^ sxmo_modemcall.sh pickup $(echo "$INCOMINGCALL" | cut -d: -f1)
		$CHOICES
	"

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
	xdotool key --clearmodifiers "$1"
	#--window $WIN
}

quit() {
	exit 0
}

mainloop() {
	DMENUIDX=0
	PICKED=""
	ARGS="$*"

	while :
	do
		# E.g. sets PROGCHOICES
		getprogchoices "$ARGS"

		PICKED="$(
			echo "$PROGCHOICES" |
			cut -d'^' -f1 | 
			dmenu -idx $DMENUIDX -l 14 -c -fn "Terminus-30" -p "$WINNAME"
		)"
		LOOP="$(echo "$PROGCHOICES" | grep -F "$PICKED" | cut -d '^' -f2)"
		CMD="$(echo "$PROGCHOICES" | grep -F "$PICKED" | cut -d '^' -f3)"
		DMENUIDX="$(echo "$PROGCHOICES" | grep -F -n "$PICKED" | cut -d ':' -f1)"
		echo "Eval: <$CMD> from picked <$PICKED> with loop <$LOOP>"
		eval "$CMD"
		echo "$LOOP" | grep 1 || quit
	done
}

pgrep -f sxmo_appmenu.sh | grep -Ev "^${$}$" | xargs kill -9
pkill -9 dmenu
mainloop "$@"