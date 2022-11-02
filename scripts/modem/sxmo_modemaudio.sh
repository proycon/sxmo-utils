#!/bin/sh

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

ca_dbus_get_prop() {
	dbus-send --session --print-reply --dest=org.mobian_project.CallAudio \
		/org/mobian_project/CallAudio org.freedesktop.DBus.Properties.Get \
		string:org.mobian_project.CallAudio string:"$1"
}

ca_dbus_set_prop() {
	dbus-send --session --print-reply --type=method_call \
		--dest=org.mobian_project.CallAudio \
		/org/mobian_project/CallAudio org.mobian_project.CallAudio."$1" "$2" |\
		grep -q "boolean true" && return 0 || return 1
}

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
	ca_dbus_get_prop MicState | tail -n1 | grep -q "uint32 0"
}

is_unmuted_mic() {
	ca_dbus_get_prop MicState | tail -n1 | grep -q "uint32 1"
}

mute_mic() {
	if ca_dbus_set_prop MuteMic boolean:true; then
		sxmo_hook_statusbar.sh volume
		sxmo_log "Successfully muted mic."
		return 0
	else
		sxmo_notify_user.sh "Failed to mute mic."
		return 1
	fi
}

unmute_mic() {
	if ca_dbus_set_prop MuteMic boolean:false; then
		sxmo_hook_statusbar.sh volume
		sxmo_log "Successfully unmuted mic."
		return 0
	else
		sxmo_notify_user.sh "Failed to unmute mic."
		return 1
	fi
}

is_call_audio_mode() {
	ca_dbus_get_prop AudioMode | tail -n1 | grep -q "uint32 1"
}

is_default_audio_mode() {
	ca_dbus_get_prop AudioMode | tail -n1 | grep -q "uint32 0"
}

enable_call_audio_mode() {
	if ca_dbus_set_prop SelectMode uint32:1; then
		sxmo_log "Successfully enabled call audio mode."
		sxmo_log "Attempting hack to get things just right."
		# fixes bug where sometimes we start with speaker on and mic off
		enable_speaker
		disable_speaker
		mute_mic
		unmute_mic
		sxmo_hook_statusbar.sh volume
		return 0
	else
		sxmo_notify_user.sh "Failed to enable call audio mode."
		return 1
	fi
}

disable_call_audio_mode() {
	if ca_dbus_set_prop SelectMode uint32:0; then
		sxmo_log "Successfully disabled call audio mode."
		sxmo_log "Attempting hack to get things just right."
		# fixes bug where sometimes we leave call with speaker off and mic on
		disable_speaker
		enable_speaker
		unmute_mic
		mute_mic
		sxmo_hook_statusbar.sh volume
		return 0
	else
		sxmo_notify_user.sh "Failed to disable call audio mode."
		return 1
	fi
}

is_enabled_speaker() {
	ca_dbus_get_prop SpeakerState | tail -n1 | grep -q "uint32 1"
}

is_disabled_speaker() {
	ca_dbus_get_prop SpeakerState | tail -n1 | grep -q "uint32 0"
}

enable_speaker() {
	if ca_dbus_set_prop EnableSpeaker boolean:true; then
		sxmo_hook_statusbar.sh volume
		sxmo_log "Successfully enabled speaker."
		return 0
	else
		sxmo_notify_user.sh "Failed to enable speaker."
		return 1
	fi
}

disable_speaker() {
	if ca_dbus_set_prop EnableSpeaker boolean:false; then
		sxmo_hook_statusbar.sh volume
		sxmo_log "Successfully disabled speaker."
		return 0
	else
		sxmo_notify_user.sh "Failed to disable speaker."
		return 1
	fi
}

"$@"
