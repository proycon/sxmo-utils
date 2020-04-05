#!/usr/bin/env sh
media-ctl -d /dev/media1 --set-v4l2 '"ov5640 3-004c":0[fmt:UYVY8_2X8/1280x720]'
mpv --video-rotate=90 av://v4l2:/dev/video1
