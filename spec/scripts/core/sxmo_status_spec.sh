export SXMO_STATUS_NAME=test
XDG_RUNTIME_DIR="$(mktemp -d)"
export XDG_RUNTIME_DIR
# SPDX-License-Identifier: AGPL-3.0-only
# Copyright 2022 Sxmo Contributors

Describe 'sxmo_status.sh'
	Include scripts/core/sxmo_status.sh

	# Clean up our temporary runtime directory
	# shellcheck disable=SC2016
	AfterAll 'rm -r "$XDG_RUNTIME_DIR"'

	It 'reset the bar'
		When call reset
		The status should be success
	End

	It 'show a blank line'
		When call show
		The output should equal ''
	End

	It 'add a foo component'
		When call add foo 1 'foo'
		The status should be success
	End

	It 'show the foo with the foo component'
		When call show
		The output should equal 'foo'
	End

	It 'add a bar second component'
		When call add bar 2 'bar'
		The status should be success
	End

	It 'show the bar with the foo and bar components'
		When call show
		The output should equal 'foo bar'
	End

	Data
		#|toot
	End

	It 'add a toot third component from stdin'
		When call add toot 3 ""
		The status should be success
	End

	It 'show the bar with the foo, bar and toot components'
		When call show
		The output should equal 'foo bar toot'
	End

	It 'del the bar second component'
		When call del bar
		The status should be success
	End

	It 'show the bar with the foo and toot components'
		When call show
		The output should equal 'foo toot'
	End

	It 'reset the bar'
		When call reset
		The status should be success
	End

	It 'show a blank line'
		When call show
		The output should equal ''
	End
End
