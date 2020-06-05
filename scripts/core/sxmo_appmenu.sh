#!/usr/bin/env sh
WIN=$(xdotool getwindowfocus)

programchoicesinit() {
  XPROPOUT="$(xprop -id $(xdotool getactivewindow))"
  WMCLASS="${1:-$(echo "$XPROPOUT" | grep WM_CLASS | cut -d ' ' -f3-)}"

  # Default system menu (no matches)
  CHOICES="$(echo "
    Scripts            ^ 0 ^ sxmo_appmenu.sh scripts
    Apps               ^ 0 ^ sxmo_appmenu.sh applications
    $([ -d $XDG_CONFIG_HOME/sxmo/userscripts ] && [ -n "$(ls -A $XDG_CONFIG_HOME/sxmo/userscripts)" ] && echo 'Userscripts        ^ 0 ^ sxmo_appmenu.sh userscripts')
    Volume ↑           ^ 1 ^ sxmo_vol.sh up
    Volume ↓           ^ 1 ^ sxmo_vol.sh down
    Dialer             ^ 0 ^ sxmo_modemcall.sh dial
    Texts              ^ 0 ^ sxmo_modemtext.sh
    Camera             ^ 0 ^ sxmo_camera.sh
    Wifi               ^ 0 ^ st -e "nmtui"
    Audio              ^ 0 ^ sxmo_appmenu.sh audioout
    Config             ^ 0 ^ sxmo_appmenu.sh config
    Logout             ^ 0 ^ pkill -9 dwm
  ")" && WINNAME=Sys

  # Userscripts menu
  echo $WMCLASS | grep -i "userscripts" &&
  CHOICES="$(ls -1 $XDG_CONFIG_HOME/sxmo/userscripts | sed 's/ /\\ /' |
  awk '{printf "%s\t^ 0 ^ sh $XDG_CONFIG_HOME/sxmo/userscripts/%s \n", $0, $0}')" &&
  WINNAME=Userscripts && return

  # Apps menu
  echo $WMCLASS | grep -i "applications" && CHOICES="$(echo "
    Surf            ^ 0 ^ surf
    Netsurf         ^ 0 ^ netsurf
    Firefox         ^ 0 ^ firefox
    Sacc            ^ 0 ^ st -e sacc i-logout.cz/1/bongusta
    W3m             ^ 0 ^ st -e w3m duck.com
    Xcalc           ^ 0 ^ xcalc
    St              ^ 0 ^ st
    Foxtrotgps      ^ 0 ^ foxtrotgps
  ")" && WINNAME=Apps && return

  # Scripts menu
  echo $WMCLASS | grep -i "scripts" && CHOICES="$(echo "
    Web Search      ^ 0 ^ sxmo_websearch.sh
    Files           ^ 0 ^ sxmo_files.sh
    Timer           ^ 0 ^ sxmo_timer.sh
    Youtube         ^ 0 ^ sxmo_youtube.sh video
    Youtube (Audio) ^ 0 ^ sxmo_youtube.sh audio
    Weather         ^ 0 ^ sxmo_weather.sh
    RSS             ^ 0 ^ sxmo_rss.sh
  ")" && WINNAME=Scripts && return

  # System Control menu
  echo $WMCLASS | grep -i "config" && CHOICES="$(echo "
    Brightesss ↑               ^ 1 ^ sxmo_brightness.sh up
    Brightness ↓               ^ 1 ^ sxmo_brightness.sh down
    Modem Toggle               ^ 1 ^ sxmo_modemmonitortoggle.sh
    Modem Info                 ^ 0 ^ sxmo_modeminfo.sh
    Modem Log                  ^ 0 ^ sxmo_modemlog.sh
    Flash $(cat /sys/class/leds/white:flash/brightness | grep -E '^0$' > /dev/null && echo -n "Off → On" || echo -n "On → Off") ^ 1 ^ sxmo_flashtoggle.sh
    Bar Toggle                 ^ 1 ^ key Alt+b
    Change Timezone            ^ 1 ^ sxmo_timezonechange.sh
    Rotate                     ^ 1 ^ sxmo_rotate.sh
    Upgrade Pkgs               ^ 0 ^ st -e sxmo_upgrade.sh
  ")" && WINNAME=Config && return

  # Audio Out menu
  echo $WMCLASS | grep -i "audioout" && CURRENTDEV="$(sxmo_audiocurrentdevice.sh)" && CHOICES="$(echo "
    Headphones $([[ "$CURRENTDEV" == "Headphone" ]] && echo "✓") ^ 1 ^ sxmo_audioout.sh Headphones
    Speaker $([[ "$CURRENTDEV" == "Line Out" ]] && echo "✓")      ^ 1 ^ sxmo_audioout.sh Speaker
    Earpiece $([[ "$CURRENTDEV" == "Earpiece" ]] && echo "✓")      ^ 1 ^ sxmo_audioout.sh Earpiece
    None $([[ "$CURRENTDEV" == "None" ]] && echo "✓")          ^ 1 ^ sxmo_audioout.sh None
  ")" && WINNAME="Audio" && return

  # MPV
  echo $WMCLASS | grep -i "mpv" && CHOICES="$(echo "
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
  ")" && WINNAME=Mpv && return

  #  St
  echo $WMCLASS | grep -i "st-256color" && STSELMODEON="$(echo "$XPROPOUT" | grep -E '^_ST_SELMODE.+=' | cut -d= -f2 | tr -d ' ')" && CHOICES="$(echo "
      Type complete   ^ 0 ^ key Ctrl+Shift+u
      Copy complete   ^ 0 ^ key Ctrl+Shift+i
      Selmode $([ $STSELMODEON == 1 ] && echo 'On → Off' || echo 'Off → On') ^ 0 ^ key Ctrl+Shift+s
      $([ $STSELMODEON == 1 ] && echo 'Copy selection ^ 0 ^ key Ctrl+Shift+c')
      Paste           ^ 0 ^ key Ctrl+Shift+v
      Zoom +          ^ 1 ^ key Ctrl+Shift+Prior
      Zoom -          ^ 1 ^ key Ctrl+Shift+Next
      Scroll ↑        ^ 1 ^ key Ctrl+Shift+b
      Scroll ↓        ^ 1 ^ key Ctrl+Shift+f
      Invert          ^ 1 ^ key Ctrl+Shift+x
      Hotkeys         ^ 0 ^ sxmo_appmenu.sh sthotkeys
  ")" && WINNAME=St && return

  #  St hotkeys
  echo $WMCLASS | grep -i "sthotkeys" && CHOICES="$(echo "
      Send Ctrl-C      ^ 0 ^ key Ctrl+c
      Send Ctrl-L      ^ 0 ^ key Ctrl+l
      Send Ctrl-D      ^ 0 ^ key Ctrl+d
  ")" && WINNAME=St && return

  # Netsurf
  echo $WMCLASS | grep -i netsurf && CHOICES="$(echo "
      Pipe URL          ^ 0 ^ sxmo_urlhandler.sh
      Zoom +            ^ 1 ^ key Ctrl+plus
      Zoom -            ^ 1 ^ key Ctrl+minus
      History  ←      ^ 1 ^ key Alt+Left
      History  →   ^ 1 ^ key Alt+Right
  ")" && WINNAME=Netsurf && return

  # Surf
  echo $WMCLASS | grep surf && CHOICES="$(echo "
      Navigate    ^ 0 ^ key Ctrl+g
      Link Menu   ^ 0 ^ key Ctrl+d
      Pipe URL    ^ 0 ^ sxmo_urlhandler.sh
      Zoom +      ^ 1 ^ key Ctrl+Shift+k
      Zoom -      ^ 1 ^ key Ctrl+Shift+j
      Scroll ↑    ^ 1 ^ key Shift+space
      Scroll ↓    ^ 1 ^ key space
      JS Toggle   ^ 1 ^ key Ctrl+Shift+s
      History ←    ^ 1 ^ key Ctrl+h
      History →   ^ 1 ^ key Ctrl+l
  ")" && WINNAME=Surf && return

  # Firefox
  echo $WMCLASS | grep -i firefox && CHOICES="$(echo "
      Pipe URL          ^ 0 ^ sxmo_urlhandler.sh
      Zoom +            ^ 1 ^ key Ctrl+plus
      Zoom -            ^ 1 ^ key Ctrl+minus
      History  ←        ^ 1 ^ key Alt+Left
      History  →        ^ 1 ^ key Alt+Right
  ")" && WINNAME=Firefox && return

  # Foxtrot GPS
  echo $WMCLASS | grep -i foxtrot && CHOICES="$(echo "
      Zoom +            ^ 1 ^ key i
      Zoom -            ^ 1 ^ key o
      Panel toggle      ^ 1 ^ key m
      Autocenter toggle ^ 0 ^ key a
      Route             ^ 0 ^ key r
  ")" && WINNAME=Gps && return
}

getprogchoices() {
  # E.g. sets CHOICES var
  programchoicesinit $@

  # Decorate menu at top w/ incoming call entry if present
  INCOMINGCALL=$(cat /tmp/sxmo_incomingcall || echo NOCALL)
  echo "$INCOMINGCALL" | grep -v NOCALL && CHOICES="$(echo "
    Pickup $(echo $INCOMINGCALL | cut -d: -f2) ^ 0 ^ sxmo_modemcall.sh pickup $(echo $INCOMINGCALL | cut -d: -f1)
    $CHOICES
  ")"

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
  ARGS="$@"

  while :
  do
    # E.g. sets PROGCHOICES
    getprogchoices $ARGS

    PICKED="$(
      echo "$PROGCHOICES" |
      cut -d'^' -f1 | 
      dmenu -idx $DMENUIDX -l 14 -c -fn "Terminus-30" -p "$WINNAME"
    )"
    LOOP="$(echo "$PROGCHOICES" | grep -F "$PICKED" | cut -d '^' -f2)"
    CMD="$(echo "$PROGCHOICES" | grep -F "$PICKED" | cut -d '^' -f3)"
    DMENUIDX="$(echo "$PROGCHOICES" | grep -F -n "$PICKED" | cut -d ':' -f1)"
    echo "Eval: <$CMD> from picked <$PICKED> with loop <$LOOP>"
    eval $CMD
    echo $LOOP | grep 1 || quit
  done
}

pgrep -f sxmo_appmenu.sh | grep -Ev "^${$}$" | xargs kill -9
pkill -9 dmenu
mainloop $@
