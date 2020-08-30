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
	TRANSPOSE="$2"
	RES="${MODE%%@*}"
	SPEED="${MODE##*@}"
	HEIGHT="${RES##*x}"
	WIDTH="${RES%%x*}"

	# FFMpeg here is just converting V4L2 into rawvideo data to pipe to mpv which
	# has better compatabilty with mpv's rawvideo demuxer (then v4l2 data). There
	# (may) be a way to directly invoke the rawvideo demuxer with a v4l2 device
	# in mpv; but this is simpler and more reliable for now.
	ffmpeg -re -fflags nobuffer -f v4l2 -video_size $RES -i /dev/video1 -f rawvideo - |
	mpv \
		--demuxer-rawvideo-w=$WIDTH --demuxer-rawvideo-h=$HEIGHT \
		--untimed --vo=xv --cache-pause=no --no-demuxer-thread \
		--profile=low-latency --demuxer=rawvideo -vf transpose=$TRANSPOSE \
		-
}

camerarear() {
	setupmediactllinks "$REAR_LINK[0]" "$FRONT_LINK[1]"
	setupv4l2 "$REAR_MODE" "$REAR_NODE"
	startmpv "$REAR_MODE" 1
}
camerafront() {
	setupmediactllinks "$FRONT_LINK[0]" "$REAR_LINK[1]"
	setupv4l2 "$FRONT_MODE" "$FRONT_NODE"
	startmpv "$FRONT_MODE" 3
}

cameramenu() {
	CHOICE="$(
		printf %b "Rear Camera\nFront Camera\nClose Menu" |
		dmenu -fn Terminus-30 -c -p "Camera" -l 20
	)"
	if [ "$CHOICE" = "Close Menu" ]; then
		exit 0
	elif [ "$CHOICE" = "Rear Camera" ]; then
		st -e $0 camerarear
	elif [ "$CHOICE" = "Front Camera" ]; then
		st -e $0 camerafront
	fi
}

if [ $# -gt 0 ]; then
	"$@"
else
	cameramenu
fi
