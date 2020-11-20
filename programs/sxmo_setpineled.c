#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void usage() {
	fprintf(stderr, "Usage: setpineled [red|green|blue|white] [0-255]\n");
}

int main(int argc, char *argv[]) {
	int brightness;
	char * color;
	char * command;
	char * type;

	if (argc < 2) {
		usage();
		return 1;
	}
	argc--;
	brightness = atoi(argv[argc--]);

	if (brightness < 0 || brightness > 255) {
		usage();
		return 1;
	}

	color = argv[argc--];
	if (
		strcmp(color, "red") &&
		strcmp(color, "blue") &&
		strcmp(color, "green") &&
		strcmp(color, "white")
	) {
		usage();
		return 1;
	}

	if (!strcmp(color, "white")) {
		type = "flash";
	} else {
		type = "indicator";
	}

	command = malloc(80);
	sprintf(
		command,
		"sh -c 'echo %d > /sys/class/leds/%s:%s/brightness'",
		brightness, color, type
	);
	if (setuid(0)) {
		fprintf(stderr, "setuid(0) failed\n");
	} else {
		return system(command);
	}
}
