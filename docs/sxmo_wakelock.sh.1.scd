sxmo_wakelock.sh(1)

# NAME

sxmo_wakelock.sh - Sets or remove wakelocks

# SYNOPSIS
	
*sxmo_wakelock.sh* [subcommand]

# DESCRIPTION 

This script sets or removes a wakelock, a wakelock tells the kernel to ensure a device is awake at a particular time.

# SUBCOMMNANDS

*isenabled*
	Indicates whether a wake lock funcionality is available. Exit code 0 means it is, non-zero means it is not.

*lock* <lock-name> <DURATION|nanosec|infinite>
	Sets a wakelock, *DURATION* is be an integer with suffix ms (milliseconds),
	s (seconds) ,h (hours), mn (minutes), or an integer in nanoseconds if no
	unit was provided. It may also be the string "infinite".

*unlock* <lock-name>
	Removes a wakelock

*run* <command>
	Spawn a command and set set a wakelock for its entire duration.

# SEE ALSO

_sxmo_(7)
