 #!/usr/bin/env sh

SXMO_IMAGESDIR="$XDG_PICTURES_DIR/sxmo"

node_rear="ov5640 3-004c"
route_rear="ov5640"
mode_rear="1920x1080@20"

node_front="gc2145 3-003c"
route_front="gc2145"
mode_front="1600x1200@15"

pixfmt='UYVY'

set_route () {
	camera="$1"
	if [ "$camera" = "$route_rear" ]
	then
		link1='"gc2145 3-003c":0->"sun6i-csi":0[0]'
		link2='"ov5640 3-004c":0->"sun6i-csi":0[1]'
	elif [ "$camera" = "$route_front"  ]
	then
		link1='"ov5640 3-004c":0->"sun6i-csi":0[0]'
		link2='"gc2145 3-003c":0->"sun6i-csi":0[1]'
	fi

	media-ctl -d /dev/media1 --links "$link1" && media-ctl -d /dev/media1 --links "$link2" || exit 1
}

setup () {
	node="$1" 
	mode="$2" 

	res="${mode%%@*}"
	speed="${mode##*@}"

	busfmt='UYVY8_2X8'

	setup="media-ctl -d /dev/media1 --set-v4l2 '\"$node\":0[fmt:$busfmt/$res@1/$speed]'"
	eval "$setup"

	height="${res%%x*}"
	width="${res##*x}"

	v4l2-ctl --device /dev/video1 --set-fmt-video="width=$width,height=$height,pixelformat=$pixfmt"
}

still () {
	node="$1" 
	mode="$2" 
	angle="$3"
	skip="$4"

	setup "$node" "$mode"

	speed="30"
	res="${mode%%@*}"
	speed="${mode##*@}"

	height="${res##*x}"
	width="${res%%x*}"

	mkdir "$SXMO_IMAGESDIR"

	SCREENSHOT_PRE="$(date)"

	mplayer tv:// -tv driver=v4l2:width=$width:height=$height:device=/dev/video1 -fps $speed -vf rotate="$angle",screenshot="$SXMO_IMAGESDIR/$SCREENSHOT_PRE"

	find "$SXMO_IMAGESDIR" -iname "$SCREENSHOT_PRE*" | sxiv -t -i -

	# mpv command doesnt work =( https://wiki.archlinux.org/index.php/Webcam_setup#MPlayer
	# mpv --demuxer-lavf-format=video4linux2 --demuxer-lavf-o-set=input_format=rawvideo:video_size=1920x1080:framerate=20 av://v4l2:/dev/video1 --profile=low-latency

}

movie () {
	# Not working but shows off the performance of this script
	node="$1" 
	mode="$2" 
	angle="$3"
	skip="$4"

	setup "$node" "$mode"

	speed="30"
	res="${mode%%@*}"
	speed="${mode##*@}"

	height="${res##*x}"
	width="${res%%x*}"

	VIDEO_NAME="$SXMO_IMAGESDIR"/"$(date)".mkv
	# this command gives the best performance but I cannot get a video preview with this command =(
	# please note, to stop recording, you need to type `killall ffmpeg` in a terminal
	ffmpeg -f v4l2 -framerate $speed -video_size $res -i /dev/video1 -preset ultrafast -filter:v fps=fps=$speed -f matroska "$VIDEO_NAME"


	save="Save: $VIDEO_NAME"
	playback="Playback: $(ffprobe -v quiet -of csv=p=0 -show_entries format=duration "$VIDEO_NAME")"
	delete="Delete Recording"

	DONE=0

	while [ $DONE != 1 ]; do
		result="$(printf %b "$save\n$playback\n$delete" | dmenu -fn Terminus-30 -c -p "Record" -l 20)"
		if [ "$result" = "$save" ]; then
			return 0
		elif [ "$result" = "$playback" ]; then
			mpv "$VIDEO_NAME"
		else
			rm "$VIDEO_NAME"
			return 0
		fi
	done


	# outputs 10 fps =(
	# ffmpeg -f v4l2 -framerate $speed -video_size $res -i /dev/video1 -preset ultrafast -filter:v fps=fps=$speed -f matroska pipe: | tee file.mkv | mplayer - -fps $speed -vf screenshot

	# I tried forking ffmpeg to background and using mplayer. When mplayer closes, killall ffmpeg. It didnt work =(
	#mplayer tv:// -tv driver=v4l2:width=$width:height=$height:device=/dev/video1 -fps $speed -vf screenshot 

}


type="$(printf %b "picture\nmovie" | dmenu -fn Terminus-30 -c -p "Record" -l 20)"
camera="$(printf %b "front\nrear" | dmenu -fn Terminus-30 -c -p "Record" -l 20)"

# Note: "angle" is set according to mplayer's conventions. See man mplayer and look for "rotate"

[ "$camera" = "rear" ] && set_route "$route_rear" && skip=5 && node="$node_rear" && mode="$mode_rear" && angle="1"
[ "$camera" = "front" ] && set_route "$route_front" && skip=0 && node="$node_front" && mode="$mode_front" && angle="2"

# our angle variables are set for rotnormal orientation
# rotating will ruin the preview
RUNNING_AUTO="$(ps aux | grep "sh /usr/bin/sxmo_autorotate.sh" | grep -v grep | cut -f2 -d' ')"
[ -n "$RUNNING_AUTO" ] && echo "$RUNNING_AUTO" | tr '\n' ' ' | xargs kill -9; notify-send "Turning autorotate off"
sxmo_rotate.sh isrotated && sxmo_rotate.sh rotnormal

[ "$type" = "picture" ] && still "$node" "$mode" "$angle" "$skip"
[ "$type" = "movie" ] && movie "$node" "$mode" "$angle" "$skip"

[ -n "$RUNNING_AUTO" ] && sxmo_autorotate.sh
