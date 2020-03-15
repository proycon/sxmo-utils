#!/usr/bin/env sh

power_1() {
  pgrep -f sxmo_appmenu.sh || sxmo_keyboard.sh
}
power_2() {
  st
}
power_3() {
  surf
}

voldown_1() {
  pgrep -f sxmo_appmenu.sh && xdotool key Control+n || xdotool key Alt+Ctrl+period
}
voldown_2() {
  xdotool key Alt+Shift+c
}
voldown_3() {
  xdotool key Alt+Return
}

volup_1() {
  pgrep -f sxmo_appmenu.sh && xdotool key Control+p || sxmo_appmenu.sh
}
volup_2() {
  echo nop
}
volup_3() {
  echo nop
}

$@
