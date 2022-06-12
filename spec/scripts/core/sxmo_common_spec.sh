# This file is to investigate whether sxmo_common.sh is loaded in tests

Describe 'sxmo_common.sh'
	It 'runs all tests with sxmo_common.sh loaded'
		When call sh spec/helper/jq.sh
		The output should equal 'gojq'
		The status should be success
	End
End
