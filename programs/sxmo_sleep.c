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

static void usage(char *cmd, char *msg) {
	dprintf(2, "Usage: %s [-c <clock-name>] <seconds>\n", cmd);
	dprintf(2, "%s\n", msg);
	exit(1);
}

int main(int argc, char **argv) {
	uint64_t buf;
	long duration = -1;
	int time_fd;
	int clockid = CLOCK_REALTIME;

	struct itimerspec time = {
		.it_value = { .tv_sec = 0, .tv_nsec = 0 },
		.it_interval = { .tv_sec = 0, .tv_nsec = 0 }
	};

	for (int i = 1; i < argc; i += 1) {
		if (0 == strcmp(argv[i], "-c")) {
			if (argc <= i + 1) {
				usage(argv[0], "You must pass a clock name.");
			}
			if (0 == strcmp(argv[i+1], "realtime")) {
				clockid = CLOCK_REALTIME;
			} else if (0 == strcmp(argv[i+1], "monotonic")) {
				clockid = CLOCK_MONOTONIC;
			} else if (0 == strcmp(argv[i+1], "boottime")) {
				clockid = CLOCK_BOOTTIME;
			} else if (0 == strcmp(argv[i+1], "realtime_alarm")) {
				clockid = CLOCK_REALTIME_ALARM;
			} else if (0 == strcmp(argv[i+1], "boottime_alarm")) {
				clockid = CLOCK_BOOTTIME_ALARM;
			} else {
				usage(argv[0], "Unknown clock name.");
			}
			i += 1;
			continue;
		}
		duration = strtol(argv[i], NULL, 0);;
	}

	if (duration <= 0) {
		usage(argv[0], "You must pass a duration in second.");
	}

	// Setup timer
	if ((time_fd = timerfd_create(clockid, TFD_CLOEXEC)) == -1)
		error("Failed to create timerfd", errno);

	time.it_value.tv_sec = duration;

	if (timerfd_settime(time_fd, 0, &time, NULL) == -1)
		error("Failed to set timer",errno);

	// Wait for timer
	read(time_fd, &buf, sizeof(uint64_t));
}
