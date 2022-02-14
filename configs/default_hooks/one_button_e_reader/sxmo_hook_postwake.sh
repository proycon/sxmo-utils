#!/bin/sh

. sxmo_common.sh

UNSUSPENDREASON="$1"

#The UNSUSPENDREASON can be "usb power", "cover", "rtc" (real-time clock
#periodic wakeup) or "button". You will likely want to check against this and
#decide what to do

light -S "$(cat "$XDG_RUNTIME_DIR"/sxmo.brightness.presuspend.state)"

sxmo_hook_statusbar.sh time
sxmo_hook_unlock.sh

# Add here whatever you want to do
