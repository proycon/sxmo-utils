#include <errno.h>       // error handling
#include <stdint.h>      // uint64_t type
#include <stdio.h>       // dprintf
#include <stdlib.h>      // strtol, exit
#include <string.h>      // strerror, strcmp
#include <sys/timerfd.h> // timers
#include <unistd.h>      // read

static void error(char *message, int err) {
	dprintf(2, "%s: %s\n", message, strerror(err));
	exit(1);
}

int main(int argc, char **argv) {
	uint64_t buf;
	long duration = -1;
	int time_fd;

	struct timespec now;
	struct itimerspec time = {
		.it_value = { .tv_sec = 0, .tv_nsec = 0 },
		.it_interval = { .tv_sec = 0, .tv_nsec = 0 }
	};

	// Process arguments
	if (argc >= 2) duration = strtol(argv[1], NULL, 0);
	if (duration <= 0) {
		dprintf(2, "Usage: %s <seconds>\n", argv[0]);
		dprintf(2, "ERROR: duration must be a positive integer\n");
		return 1;
	}

	// Setup timer
	if ((time_fd = timerfd_create(CLOCK_REALTIME, 0)) == -1)
		error("Failed to create timerfd", errno);
	if (clock_gettime(CLOCK_REALTIME, &now) == -1)
		error("Failed to get current time", errno);

	// find the next time that's divisable by the provided number of seconds
	time.it_value.tv_sec = now.tv_sec + duration - (now.tv_sec % duration);

	if (timerfd_settime(time_fd, TFD_TIMER_ABSTIME | TFD_TIMER_CANCEL_ON_SET, &time, NULL) == -1)
		error("Failed to set timer",errno);

	// Wait for timer
	read(time_fd, &buf, sizeof(uint64_t));
}

