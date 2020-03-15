move() {
  xdotool keydown Alt
  echo "Move done?" | dmenu
  xdotool keyup Alt
}

resize() {
  xdotool keydown Alt
  xdotool mousedown 3
  echo "Resize done?" | dmenu
  xdotool keyup Alt
  xdotool mouseup 3
}

$@