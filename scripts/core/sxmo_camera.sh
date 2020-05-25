#!/usr/bin/env sh
err() {
  echo -e "$1" | dmenu -fn Terminus-20 -c -l 10
  exit 1
}

media-ctl -d /dev/media1 --set-v4l2 '"ov5640 3-004c":0[fmt:UYVY8_2X8/1280x720]' || err "Couldn't open camera, is camera enabled?"
mpv --video-rotate=90 av://v4l2:/dev/video1
