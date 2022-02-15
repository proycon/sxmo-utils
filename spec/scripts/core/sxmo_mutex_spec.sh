# shellcheck disable=SC2155
export PATH="$PATH:$(pwd)/scripts/core"

Describe 'sxmo_mutex.sh'
	# Make sure we're running in a somewhat clean environment
	setup() {
		sh scripts/core/sxmo_mutex.sh shellspec_mutex freeall
	}

	BeforeAll 'setup'

	# TODO: refactor script so it can be included instead of calling it
	# Include scripts/core/sxmo_mutex.sh

	It 'can list an empty lock'
		When call sh scripts/core/sxmo_mutex.sh shellspec_mutex list
		The output should equal ''
		The status should be success
	End

	It 'can acquire a lock'
		When call sh scripts/core/sxmo_mutex.sh shellspec_mutex lock shellspec
		The status should be success
	End

	It 'can list an acquired lock'
		When call sh scripts/core/sxmo_mutex.sh shellspec_mutex list
		The output should equal 'shellspec'
	End

	It 'can free a lock'
		When call sh scripts/core/sxmo_mutex.sh shellspec_mutex free shellspec
		The status should be success
	End

	It 'does not list a freed lock'
		When call sh scripts/core/sxmo_mutex.sh shellspec_mutex list
		The output should equal ''
	End

	IDS="$(seq 1 100)"
	many_lock() {
		set -e

		for id in $IDS; do
			sh scripts/core/sxmo_mutex.sh shellspec_mutex lock "$id" &
		done

		for id in $IDS; do
			wait
		done
	}

	It 'can handle concurrent locks'
		When call many_lock
		The status should be success
	End

	It 'lists all concurrently added locks'
		list() {
			sh scripts/core/sxmo_mutex.sh shellspec_mutex list | sort
		}

		When call list

		# shellcheck disable=SC2086
		The output should equal "$(printf "%s\n" $IDS | sort)"
	End

	many_unlock() {
		set -e

		for id in $IDS; do
			[ "$id" = 50 ] && continue
			sh scripts/core/sxmo_mutex.sh shellspec_mutex free "$id" &
		done

		for id in $IDS; do
			[ "$id" = 50 ] && continue
			wait
		done
	}

	It 'can handle concurrent unlocks'
		When call many_unlock
		The status should be success
	End

	It 'clears all locks after they are unlocked'
		When call sh scripts/core/sxmo_mutex.sh shellspec_mutex list
		The output should equal "50"
	End
End
