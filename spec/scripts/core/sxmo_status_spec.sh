export SXMO_STATUS_NAME=test

Describe 'sxmo_status.sh'
	Include scripts/core/sxmo_status.sh

	It 'reset the bar'
		When call reset
		The status should be success
	End

	It 'show a blank line'
		When call show
		The output should equal ''
	End

	It 'add a foo component'
		When call add 1-foo 'foo'
		The status should be success
	End

	It 'show the foo with the foo component'
		When call show
		The output should equal 'foo'
	End

	It 'add a bar second component'
		When call add 2-bar 'bar'
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
		When call add 3-toot
		The status should be success
	End

	It 'show the bar with the foo, bar and toot components'
		When call show
		The output should equal 'foo bar toot'
	End

	It 'del the bar second component'
		When call del 2-bar
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
