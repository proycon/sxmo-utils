#!/usr/bin/env sh
audiodevice() {
	amixer sget "Earpiece" | grep -qE '\[on\]' && echo Earpiece && return
	amixer sget "Headphone" | grep -qE '\[on\]' && echo Headphone && return
	amixer sget "Line Out" | grep -qE '\[on\]' && echo Line Out && return
	echo "None"
}

audiodevice
