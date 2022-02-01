/* Based on: https://xnux.eu/devices/feature/vibrator.html#toc-example-program-to-control-the-vibration-motor */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <stdbool.h>
#include <time.h>
#include <errno.h>
#include <limits.h>
#include <fcntl.h>
#include <poll.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/input.h>


void syscall_error(int is_err, const char* fmt, ...)
{
	va_list ap;

	if (!is_err)
		return;

	fprintf(stderr, "ERROR: ");
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);
	fprintf(stderr, ": %s\n", strerror(errno));

	exit(1);
}

void usage() {
	fprintf(stderr, "Usage: sxmo_vibratepine duration_ms\n");
	fprintf(stderr, "       sxmo_vibratepine duration_ms strength_number\n");
}

int main(int argc, char* argv[])
{
	int fd, ret, effects;
	struct timespec time;
	long durationMs, strength = 1;
	char *endptr;

	if (argc < 2 || argc > 3) {
		usage();
		return 1;
	}

	errno = 0;
	durationMs = strtol(argv[1], &endptr, 10);
	if (errno || *endptr != '\0' || durationMs <= 0) {
		if (durationMs == LONG_MAX)
			fprintf(stderr, "%s: duration is too big\n", argv[0]);
		else
			fprintf(stderr, "%s: expected positive integer for duration\n", argv[0]);

		return 1;
	}
	time.tv_sec = durationMs / 1000;
	time.tv_nsec = (durationMs % 1000) * 1000 * 1000;

	if (argc == 3) {
		errno = 0;
		strength = strtol(argv[2], &endptr, 10);
		if (errno || *endptr != '\0' || strength <= 0 || strength > 65535) {
			fprintf(stderr, "%s: expected integer between 1 and 65535 (inclusive) for strength\n", argv[0]);
			return 1;
		}
	}

	fd = open("/dev/input/by-path/platform-vibrator-event", O_RDWR | O_CLOEXEC);
	syscall_error(fd < 0, "Can't open vibrator event device");
	ret = ioctl(fd, EVIOCGEFFECTS, &effects);
	syscall_error(ret < 0, "EVIOCGEFFECTS failed");

	struct ff_effect e = {
					.type = FF_RUMBLE,
					.id = -1,
					.u.rumble = { .strong_magnitude = strength },
	};

	ret = ioctl(fd, EVIOCSFF, &e);
	syscall_error(ret < 0, "EVIOCSFF failed");

	struct input_event play = { .type = EV_FF, .code = e.id, .value = 3 };
	ret = write(fd, &play, sizeof play);
	syscall_error(ret < 0, "write failed");

	nanosleep(&time, &time);

	ret = ioctl(fd, EVIOCRMFF, e.id);
	syscall_error(ret < 0, "EVIOCRMFF failed");

	close(fd);
	return 0;
}
