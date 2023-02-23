#include <errno.h>       // error handling
#include <stdint.h>      // uint64_t type
#include <stdio.h>       // dprintf
#include <stdlib.h>      // strtol, exit
#include <string.h>      // strerror
#include <sys/timerfd.h> // timers
#include <unistd.h>      // read
#include <sys/epoll.h>   // epoll_*
#include <sys/capability.h> // cap_*

#define MAX_EVENTS 1

#define try(func, args...) { \
if (-1 == func(args)) { \
	perror(#func); \
	return 1; \
} \
}

#define eprintf(...) fprintf (stderr, __VA_ARGS__)

void error(char *message, int err) {
	dprintf(2, "%s: %s\n", message, strerror(err));
	exit(1);
}

void usage(char *name) {
	eprintf(
		"%s: <seconds> <command>\n"
		"\tRun <command> after <seconds> or after a suspension wake up. "
		"Hold the system awake until the command finished\n",
		name
	);
}

void check_cap_avail(cap_value_t cap) {
	if (!CAP_IS_SUPPORTED(CAP_SETFCAP)) {
		fprintf(stderr, "ERROR: %s isn't available on your system\n", cap_to_name(cap));
		exit(1);
	}
}

int check_perimsions() {
	const cap_value_t cap_list[2] = {CAP_BLOCK_SUSPEND, CAP_WAKE_ALARM};

	check_cap_avail(CAP_BLOCK_SUSPEND);
	check_cap_avail(CAP_WAKE_ALARM);

	cap_t caps = cap_get_proc();
	if (caps == NULL) {
		perror("cap_get_proc");
		return 1;
	}

	try(cap_set_flag, caps, CAP_EFFECTIVE, 2, cap_list, CAP_SET);

	if (-1 == cap_set_proc(caps)) {
		perror("cap_set_proc");
		return 1;
	}

        try(cap_free, caps);

	return 0;
}

int main(int argc, char **argv) {
	uint64_t buf;
	long duration = -1;
	int time_fd, epollfd;

	struct epoll_event ev, events[MAX_EVENTS];

	struct timespec now;
	struct itimerspec time = {
		.it_value = { .tv_sec = 0, .tv_nsec = 0 },
		.it_interval = { .tv_sec = 0, .tv_nsec = 0 }
	};

	// Check permissions
	if (check_perimsions()) {
		fprintf(stderr, "Hint: make sure this executeable has the "
		                "cap_block_suspend and cap_wake_alarm privilages\n");
		return 1;
	}

	// Process arguments
	if (argc != 3) {
		usage(argv[0]);
		return 1;
	}

	duration = strtol(argv[1], NULL, 0);

	if (duration <= 0 || errno == ERANGE) {
		usage(argv[0]);
		eprintf("Error: seconds must be a positive integer\n");
		return 1;
	}

	// Create timer
	if ((time_fd = timerfd_create(CLOCK_REALTIME_ALARM, 0)) == -1)
		error("Failed to create timerfd", errno);

	// Setup epoll
	epollfd = epoll_create1(0);
	ev.events = EPOLLIN | EPOLLWAKEUP;
	ev.data.fd = time_fd;
	epoll_ctl(epollfd, EPOLL_CTL_ADD, time_fd, &ev);

	// Calculate absolute time to wakeup
	try(clock_gettime, CLOCK_REALTIME, &now);
	time.it_value.tv_sec = now.tv_sec + duration;
	time.it_value.tv_nsec = now.tv_nsec;

	/* if (timerfd_settime(time_fd, TFD_TIMER_ABSTIME | TFD_TIMER_CANCEL_ON_SET, &time, NULL) == -1) { */
	try(timerfd_settime, time_fd, TFD_TIMER_ABSTIME, &time, NULL);

	// Wait for timer
	int ret;
	do {
		ret = epoll_wait(epollfd, events, MAX_EVENTS, -1);
		if (ret == -1 && errno == EINTR) {
			eprintf("Woke up\n");
			break;
		}
	} while (ret < 1);

	system(argv[2]);
}
