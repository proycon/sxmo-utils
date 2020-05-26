#!/usr/bin/env sh
audiodevice() {
  amixer sget "Earpiece" | grep -E '\[on\]' > /dev/null && echo Earpiece && return
  amixer sget "Headphone" | grep -E '\[on\]' > /dev/null && echo Headphone && return
  amixer sget "Line Out" | grep -E '\[on\]' > /dev/null && echo Line Out && return
  echo "None"
}

audiodevice
