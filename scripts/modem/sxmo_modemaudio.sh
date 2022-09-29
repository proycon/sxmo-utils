#!/bin/sh

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

setup_audio() {
	# implies speaker off, mic not muted
	enable_call_audio_mode
}

reset_audio() {
	# implies speaker on, mic muted
	disable_call_audio_mode
}

toggle_speaker() {
	if is_enabled_speaker; then
		disable_speaker
	else
		enable_speaker
	fi
}

is_muted_mic() {
	dbus-send --session --print-reply --dest=org.mobian_project.CallAudio \
		/org/mobian_project/CallAudio org.freedesktop.DBus.Properties.Get \
		string:org.mobian_project.CallAudio string:MicState | \
		tail -n1 | grep -q "uint32 0"
}

is_unmuted_mic() {
	dbus-send --session --print-reply --dest=org.mobian_project.CallAudio \
		/org/mobian_project/CallAudio org.freedesktop.DBus.Properties.Get \
		string:org.mobian_project.CallAudio string:MicState | \
		tail -n1 | grep -q "uint32 1"
}

mute_mic() {
	dbus-send --session --print-reply --type=method_call --dest=org.mobian_project.CallAudio \
		/org/mobian_project/CallAudio org.mobian_project.CallAudio.MuteMic boolean:true

	sxmo_hook_statusbar.sh volume
}

unmute_mic() {
	dbus-send --session --print-reply --type=method_call --dest=org.mobian_project.CallAudio \
		/org/mobian_project/CallAudio org.mobian_project.CallAudio.MuteMic boolean:false

	sxmo_hook_statusbar.sh volume
}

is_call_audio_mode() {
	dbus-send --session --print-reply --dest=org.mobian_project.CallAudio \
		/org/mobian_project/CallAudio org.freedesktop.DBus.Properties.Get \
		string:org.mobian_project.CallAudio string:AudioMode | \
		tail -n1 | grep -q "uint32 1"
}

is_default_audio_mode() {
	dbus-send --session --print-reply --dest=org.mobian_project.CallAudio \
		/org/mobian_project/CallAudio org.freedesktop.DBus.Properties.Get \
		string:org.mobian_project.CallAudio string:AudioMode | \
		tail -n1 | grep -q "uint32 0"
}

enable_call_audio_mode() {
	pgrep -f callaudiod || callaudiod
	dbus-send --session --print-reply --type=method_call --dest=org.mobian_project.CallAudio \
		/org/mobian_project/CallAudio org.mobian_project.CallAudio.SelectMode uint32:1

	# fixes bug where sometimes we start with speaker on and mic off
	enable_speaker
	disable_speaker
	mute_mic
	unmute_mic

	sxmo_hook_statusbar.sh volume
}

disable_call_audio_mode() {
	pgrep -f callaudiod || callaudiod
	dbus-send --session --print-reply --type=method_call --dest=org.mobian_project.CallAudio \
		/org/mobian_project/CallAudio org.mobian_project.CallAudio.SelectMode uint32:0

	# fixes bug where sometimes we leave call with speaker off and mic on
	disable_speaker
	enable_speaker
	unmute_mic
	mute_mic

	sxmo_hook_statusbar.sh volume
}

is_enabled_speaker() {
	dbus-send --session --print-reply --dest=org.mobian_project.CallAudio \
		/org/mobian_project/CallAudio org.freedesktop.DBus.Properties.Get \
		string:org.mobian_project.CallAudio string:SpeakerState | \
		tail -n1 | grep -q "uint32 1"
}

is_disabled_speaker() {
	dbus-send --session --print-reply --dest=org.mobian_project.CallAudio \
		/org/mobian_project/CallAudio org.freedesktop.DBus.Properties.Get \
		string:org.mobian_project.CallAudio string:SpeakerState | \
		tail -n1 | grep -q "uint32 0"
}

enable_speaker() {
	dbus-send --session --print-reply --type=method_call --dest=org.mobian_project.CallAudio \
		/org/mobian_project/CallAudio org.mobian_project.CallAudio.EnableSpeaker boolean:true

	sxmo_hook_statusbar.sh volume
}

disable_speaker() {
	dbus-send --session --print-reply --type=method_call --dest=org.mobian_project.CallAudio \
		/org/mobian_project/CallAudio org.mobian_project.CallAudio.EnableSpeaker boolean:false

	sxmo_hook_statusbar.sh volume
}

"$@"
