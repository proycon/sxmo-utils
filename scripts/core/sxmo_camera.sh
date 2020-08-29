#!/usr/bin/env sh
REAR_NODE="ov5640 3-004c"
REAR_LINK='"gc2145 3-003c":0->"sun6i-csi":0'
REAR_MODE="1920x1080@20"
FRONT_NODE="gc2145 3-003c"
FRONT_LINK='"ov5640 3-004c":0->"sun6i-csi":0'
FRONT_MODE="1600x1200@15"
FMTPIX='UYVY'
FMTBUS='UYVY8_2X8'

err() {
	printf %b "$1" | dmenu -fn Terminus-20 -c -l 10
	exit 1
}
setupmediactllinks() {
	media-ctl -d /dev/media1 --links "$1"
	media-ctl -d /dev/media1 --links "$2"
}
setupv4l2() {
	MODE="$1"
	NODE="$2"
	RES="${MODE%%@*}"
	SPEED="${MODE##*@}"
	HEIGHT="${RES%%x*}"
	WIDTH="${RES##*x}"
	eval "media-ctl -d /dev/media1 --set-v4l2 '\"$NODE\":0[fmt:$FMTBUS/$RES@1/$SPEED]'"
	v4l2-ctl --device /dev/video1 --set-fmt-video="width=$WIDTH,height=$HEIGHT,pixelformat=$FMTPIX" ||
		err "Couldnt set up camera\n Is killswitch in right position?"
}
startmpv() {
	MODE="$1"
	RES="${MODE%%@*}"
	SPEED="${MODE##*@}"
	HEIGHT="${RES##*x}"
	WIDTH="${RES%%x*}"
	# -vf=transpose=1 - TODO: figure out why rotation is so slow..
	mpv -v --demuxer-lavf-format=video4linux2 \
		-demuxer-lavf-o=input_format=rawvideo,video_size=${WIDTH}x${HEIGHT}:framerate=$SPEED \
		--profile=low-latency --untimed --fps=$SPEED --vo=xv \
		av://v4l2:/dev/video1 
}

camerarear() {
	setupmediactllinks "$REAR_LINK[0]" "$FRONT_LINK[1]"
	setupv4l2 "$REAR_MODE" "$REAR_NODE"
	startmpv "$REAR_MODE"
}
camerafront() {
	setupmediactllinks "$FRONT_LINK[0]" "$REAR_LINK[1]"
	setupv4l2 "$FRONT_MODE" "$FRONT_NODE"
	startmpv "$FRONT_MODE"
}

cameramenu() {
	CHOICE="$(
		printf %b "Rear Camera\nFront Camera\nClose Menu" |
		dmenu -fn Terminus-30 -c -p "Camera" -l 20
	)"
	if [ "$CHOICE" = "Close Menu" ]; then
		exit 0
	elif [ "$CHOICE" = "Rear Camera" ]; then
		sxmo_rotate.sh rotright #TODO - figure out how to rotate w mpv
		camerarear
	elif [ "$CHOICE" = "Front Camera" ]; then
		sxmo_rotate.sh rotleft #TODO - figure out how to rotate w mpv
		camerafront
	fi
}

if [ $# -gt 0 ]; then
	"$@"
else
	cameramenu
fi
