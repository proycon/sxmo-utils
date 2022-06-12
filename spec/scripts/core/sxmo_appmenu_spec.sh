# shellcheck disable=SC2155
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

# Don't check for unused variables
# shellcheck disable=SC2034

Describe 'sxmo_appmenu.sh'
	Include scripts/core/sxmo_appmenu.sh

	# if the script successfully exits, it confuses shellspec
	quit() {
		true
	}

	getprogchoices() {
		true
	}

	It 'can mock functions'
		CHOICES="foo ^ 0 ^ echo bar"
		Mock sxmo_dmenu.sh
			echo 'foo '
		End

		When call mainloop

		The output should equal 'bar'
		The stderr should match pattern '*' # ignore stderr
		The status should be success
	End

	It 'ignores invalid selections'
		CHOICES="foo ^ 0 ^ echo bar"
		Mock sxmo_dmenu.sh
			echo 'baz '
		End

		When call mainloop

		The output should equal ''
		The stderr should match pattern '*' # ignore stderr
		The status should be success
	End

	It 'handles substring menu items'
		CHOICES="foobar ^ 0 ^ echo foobar
bar ^ 0 ^ echo bar2"

		Mock sxmo_dmenu.sh
			echo 'bar '
		End

		When call mainloop

		The output should equal 'bar2'
		The stderr should match pattern '*' # ignore stderr
		The status should be success
	End
End
