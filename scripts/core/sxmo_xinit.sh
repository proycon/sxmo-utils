#!/usr/bin/env sh
# Env vars
source /etc/profile
which $TERM || export TERM=st
which $BROWSER || export BROWSER=surf
[ -z "$MOZ_USE_XINPUT2" ] && export MOZ_USE_XINPUT2=1
[ -z "$XDG_CONFIG_HOME" ] && export XDG_CONFIG_HOME=~/.config

# Setup audio and a few sensible X defaults
alsactl --file /usr/share/sxmo/default_alsa_sound.conf restore
xmodmap /usr/share/sxmo/xmodmap_caps_esc
xsetroot -mod 3 2 -fg '#000000' -bg '#888888'
xset s off -dpms
xrdb /usr/share/sxmo/xresources_xcalc.xr
synclient TapButton1=1 TapButton2=3 TapButton3=2 MinSpeed=0.25

# Kill old hanging daemons
pkill lisgd && pkill conky

# Start daemons
conky -c /usr/share/sxmo/conky.conf -d
keynav &
autocutsel &
autocutsel -selection PRIMARY &
sxmo_statusbar.sh &

# Start dunst, lisgd (after dunst so it's in dbus path) and dwm
LEGACYSXMOFOLDERWARNING="
Warning: ~/.sxmo is deprecated since sxmo-utils 1.1.5.
Modem call logs/texts location have moved.
Please move the contents of the ~/.sxmo/ folder to $XDG_CONFIG_HOME/sxmo/modem/
"

exec dbus-run-session sh -c "
  dunst -conf /usr/share/sxmo/dunst.conf &
  lisgd & 
  [ -d "/home/$USER/.sxmo" ] && notify-send -t 0 -u critical '$LEGACYSXMOFOLDERWARNING' &
  dwm 2> ~/.dwm.log
"
