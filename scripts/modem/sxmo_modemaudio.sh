#!/bin/sh

# shellcheck source=scripts/core/sxmo_common.sh
. sxmo_common.sh

setup_audio() {
	unmute_mic
	enable_call_audio_mode
	disable_speaker

	i=0
	while (! is_unmuted_mic) || (! is_call_audio_mode) || (! is_disabled_speaker); do
		i=$((i+1))
		if [ "$i" -gt 5 ]; then
			return 1
		fi

		sleep 0.2

		unmute_mic
		enable_call_audio_mode
		disable_speaker
	done
}

reset_audio() {
	mute_mic
	disable_call_audio_mode
	enable_speaker

	i=0
	while (! is_muted_mic) || (! is_default_audio_mode) || (! is_enabled_speaker); do
		i=$((i+1))
		if [ "$i" -gt 5 ]; then
			return 1
		fi

		sleep 0.2

		mute_mic
		disable_call_audio_mode
		enable_speaker
	done
}

is_muted_mic() {
	callaudiocli -S | grep -q "Mic muted: CALL_AUDIO_MIC_OFF"
}

is_unmuted_mic() {
	callaudiocli -S | grep -q "Mic muted: CALL_AUDIO_MIC_ON"
}

mute_mic() {
	callaudiocli -u 1
}

unmute_mic() {
	callaudiocli -u 0
}

is_call_audio_mode() {
	callaudiocli -S | grep -q "Selected mode: CALL_AUDIO_MODE_CALL"
}

is_default_audio_mode() {
	callaudiocli -S | grep -q "Selected mode: CALL_AUDIO_MODE_DEFAULT"
}

enable_call_audio_mode() {
	callaudiocli -m 1
}

disable_call_audio_mode() {
	callaudiocli -m 0
}

is_enabled_speaker() {
	callaudiocli -S | grep -q "Speaker enabled: CALL_AUDIO_SPEAKER_ON"
}

is_disabled_speaker() {
	callaudiocli -S | grep -q "Speaker enabled: CALL_AUDIO_SPEAKER_OFF"
}

enable_speaker() {
	callaudiocli -s 1
}

disable_speaker() {
	callaudiocli -s 0
}

"$@"
