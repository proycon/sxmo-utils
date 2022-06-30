#!/bin/sh

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

setup_audio() {
	enable_call_audio_mode
	disable_speaker
	unmute_mic

	i=0
	while (! is_unmuted_mic) || (! is_call_audio_mode) || (! is_disabled_speaker); do
		i=$((i+1))
		if [ "$i" -gt 5 ]; then
			return 1
		fi

		sleep 0.2

		enable_call_audio_mode
		disable_speaker
		umute_mic
	done
}

reset_audio() {
	disable_call_audio_mode
	enable_speaker
	mute_mic

	# eventually we should remove this loop once upstream is stable
	i=0
	while (! is_muted_mic) || (! is_default_audio_mode) || (! is_enabled_speaker); do
		i=$((i+1))
		if [ "$i" -gt 5 ]; then
			return 1
		fi

		sleep 0.2

		disable_call_audio_mode
		enable_speaker
		mute_mic
	done
}

is_muted_mic() {
	callaudiocli -S | grep -q "Mic muted: CALL_AUDIO_MIC_OFF"
}

is_unmuted_mic() {
	callaudiocli -S | grep -q "Mic muted: CALL_AUDIO_MIC_ON"
}

mute_mic() {
	callaudiocli -u 1 || sxmo_log "ERR: callaudiocli -u 1 failed"
}

unmute_mic() {
	callaudiocli -u 0 || sxmo_log "ERR: callaudiocli -u 0 failed"
}

is_call_audio_mode() {
	callaudiocli -S | grep -q "Selected mode: CALL_AUDIO_MODE_CALL"
}

is_default_audio_mode() {
	callaudiocli -S | grep -q "Selected mode: CALL_AUDIO_MODE_DEFAULT"
}

enable_call_audio_mode() {
	callaudiocli -m 1 || sxmo_log "ERR: callaudiocl -m 1 failed"
}

disable_call_audio_mode() {
	callaudiocli -m 0 || sxmo_log "ERR: callaudiocli -m 0 failed"
}

is_enabled_speaker() {
	callaudiocli -S | grep -q "Speaker enabled: CALL_AUDIO_SPEAKER_ON"
}

is_disabled_speaker() {
	callaudiocli -S | grep -q "Speaker enabled: CALL_AUDIO_SPEAKER_OFF"
}

enable_speaker() {
	callaudiocli -s 1 || sxmo_log "ERR: callaudiocli -s 1 failed"
}

disable_speaker() {
	callaudiocli -s 0 || sxmo_log "ERR: callaudiocli -s 0 failed"
}

"$@"
