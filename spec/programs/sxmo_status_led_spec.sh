# shellcheck disable=SC2317
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2024 Sxmo Contributors

led() {
	./programs/sxmo_status_led --debug-led-dir "$led_dir" "$@"
}

Describe 'no led'
	setup() {
		led_dir="$(mktemp -d)"
	}

	cleanup() {
		rm -rf "$led_dir"
	}

	BeforeEach setup
	AfterEach cleanup

	It 'prints an error when there is no led'
		When call led
		The stderr should equal "Unable to find suitable status led"
		The status should be failure
	End

End

Describe 'Monocolor Leds'
	# TODO: it would be nice to make this a parameterized test, but
	# shellspec doesn't support features that we'd need
	# https://github.com/shellspec/shellspec/issues/110
	# Parameters
	# 	"Common status"    {red,green,blue}:status
	# 	"Common indicator" {red,green,blue}:indicator
	# 	"Motorola Droid 4" status-led:{red,green,blue}
	# 	"Nokia N900"       lp5523:{r,g,b}
	# End

	make_led() {
		name="$1"
		_led="$led_dir/$name/"

		mkdir "$_led"
		echo 0 > "$_led/brightness"
		echo 240 > "$_led/max_brightness"
	}

	setup() {
		led_dir="$(mktemp -d)"

		make_led "red:indicator"
		make_led "blue:indicator"
		make_led "green:indicator"

		red="$led_dir/red:indicator/brightness"
		green="$led_dir/green:indicator/brightness"
		blue="$led_dir/blue:indicator/brightness"
	}

	cleanup() {
		rm -rf "$led_dir"
	}

	BeforeEach setup
	AfterEach cleanup

	It 'Recognizes indicator type leds'
		# setup creates indicator leds, no need to setup here
		When call led
		The stderr should equal ""
		The stdout should equal ""
		The status should be success
	End

	It 'Recognizes status type leds'
		mv "$led_dir/red:indicator" "$led_dir/red:status"
		mv "$led_dir/green:indicator" "$led_dir/green:status"
		mv "$led_dir/blue:indicator" "$led_dir/blue:status"

		When call led
		The stderr should equal ""
		The stdout should equal ""
		The status should be success
	End

	It 'Recognizes status status-led prefixed leds (like Motorola Droid)'
		mv "$led_dir/red:indicator" "$led_dir/status-led:red"
		mv "$led_dir/green:indicator" "$led_dir/status-led:green"
		mv "$led_dir/blue:indicator" "$led_dir/status-led:blue"

		When call led
		The stderr should equal ""
		The stdout should equal ""
		The status should be success
	End

	It 'Recognizes lp5523 leds (like Nokia N900)'
		mv "$led_dir/red:indicator" "$led_dir/lp5523:r"
		mv "$led_dir/green:indicator" "$led_dir/lp5523:g"
		mv "$led_dir/blue:indicator" "$led_dir/lp5523:b"

		When call led
		The stderr should equal ""
		The stdout should equal ""
		The status should be success
	End

	It "Ignores non-status leds"
		mv "$led_dir/red:indicator" "$led_dir/red:foo"
		mv "$led_dir/green:indicator" "$led_dir/green:foo"
		mv "$led_dir/blue:indicator" "$led_dir/blue:foo"

		When call led
		The stderr should equal "Unable to find suitable status led"
		The status should be failure
	End

	It "Ignores leds without all necessary colors"
		mv "$led_dir/red:indicator" "$led_dir/red:status"
		mv "$led_dir/green:indicator" "$led_dir/green:status"
		rm -r "$led_dir/blue:indicator"

		When call led
		The stderr should equal "Unable to find suitable status led"
		The status should be failure
	End

	It "Ignores leds with mismatched types (probably multiple devices)"
		mv "$led_dir/red:indicator" "$led_dir/red:status"
		mv "$led_dir/green:indicator" "$led_dir/green:status"

		When call led
		The stderr should equal "Unable to find suitable status led"
		The status should be failure
	End

	It 'Handles brightness as percent'
		When call led set red 25
		The file "$red" contents should eq 60
	End

	It 'Can set multiple colors at once'
		echo "72" > "$led_dir/blue:indicator/brightness"

		When call led set red 50 green 75
		The file "$red" contents should eq 120
		The file "$green" contents should eq 180
		The file "$blue" contents should eq 72
	End

	It 'Rounds up when the value is less than 1'
		echo "10" > "$led_dir/red:indicator/max_brightness"
		echo "0" > "$led_dir/red:indicator/brightness"

		When call led set red 1
		The file "$led_dir/red:indicator/brightness" contents should eq 1
		The file "$led_dir/red:indicator/max_brightness" contents should eq 10
	End

	It 'Writes the proper blink sequence'
		echo "4" > "$led_dir/red:indicator/brightness"
		echo "10" > "$led_dir/red:indicator/max_brightness"
		echo "72" > "$led_dir/green:indicator/brightness"

		red_states="$(printf "4\n0\n10\n0\n4")"
		blue_states="$(printf "0\n0\n240\n0\n0")"
		green_states="$(printf "72\n0\n0\n0\n72")"

		When call led blink red blue
		The file "$led_dir/red:indicator/brightness" contents should eq "$red_states"
		The file "$led_dir/blue:indicator/brightness" contents should eq "$blue_states"
		The file "$led_dir/green:indicator/brightness" contents should eq "$green_states"
	End
End

Describe 'Multicolor Leds'
	setup() {
		led_dir="$(mktemp -d)"
		led="$led_dir/rgb:status"

		mkdir "$led"
		echo "green red blue" > "$led/multi_index"
		echo 240 > "$led/max_brightness"
		echo 0 > "$led/brightness"
		echo "0 0 0" > "$led/multi_intensity"
	}

	cleanup() {
		rm -rf "$led_dir"
	}

	BeforeEach setup
	AfterEach cleanup

	It 'Detects status leds'
		# the setup function creates a status led, no need to setup here
		When call led
		The stderr should equal ""
		The stdout should equal ""
		The status should be success
	End

	It 'Detects indicator leds'
		mv "$led_dir/rgb:status" "$led_dir/rgb:indicator"
		When call led
		The stderr should equal ""
		The stdout should equal ""
		The status should be success
	End

	It "Ignores non-status leds"
		mv "$led_dir/rgb:status" "$led_dir/rgb:indicato"

		When call led
		The stderr should equal "Unable to find suitable status led"
		The status should be failure
	End

	It "Ignores leds without all necessary colors"
		echo "red green" > "$led/multi_index"
		echo "0 0" > "$led/multi_intensity"

		When call led
		The stderr should equal "Unable to find suitable status led"
		The status should be failure
	End

	It 'Sets brightness to max when setting a color'
		When call led set red 50
		The file "$led/multi_intensity" contents should eq "0 120 0"
		The file "$led/brightness" contents should eq 240
		The file "$led/max_brightness" contents should eq 240
	End

	It 'Handles brightness as percent'
		When call led set red 25
		The file "$led/multi_intensity" contents should eq "0 60 0"
	End

	It 'Can set multiple colors at once'
		When call led set red 50 green 75
		The file "$led/multi_intensity" contents should eq "180 120 0"
	End

	It 'Preserves colors that arent passed to set'
		echo "150 140 130" > "$led/multi_intensity"
		When call led set red 50
		The file "$led/multi_intensity" contents should eq "150 120 130"
	End

	It 'Rounds up when the value is less than 1'
		echo "10" > "$led/max_brightness"
		echo "0" > "$led/brightness"

		When call led set red 1 blue 100
		The file "$led/multi_intensity" contents should eq "0 1 10"
		The file "$led/brightness" contents should eq 10
		The file "$led/max_brightness" contents should eq 10
	End

	It 'Writes the proper blink sequence'
		echo "10" > "$led/max_brightness"
		echo "7 4 0" > "$led/multi_intensity"

		expected_intesnity="$(
			%text
			#|0 0 0
			#|0 10 10
			#|0 0 0
			#|7 4 0
		)"

		When call led blink red blue
		The file "$led/multi_intensity" contents should eq "$expected_intesnity"
	End
End
