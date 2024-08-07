// SPDX-License-Identifier: AGPL-3.0-only
// Copyright 2024 Aren Moynihan
// Copyright 2024 Sxmo Contributors

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

// for tests
#include <assert.h>

#define BIT(n) 1<<n

// Logging functions
#define info(...) ({ if (verbose) fprintf(stderr, __VA_ARGS__); })
#define error(format, ...) ({ if (!quiet) fprintf(stderr, format "\n", ## __VA_ARGS__); })

static bool quiet = false;
static bool verbose = false;
static char *led_dir = "/sys/class/leds";

enum color {
	COLOR_RED,
	COLOR_GREEN,
	COLOR_BLUE,
	COLOR_MAX,
};

typedef union {
	double colors[COLOR_MAX];
	struct {
		double red;
		double green;
		double blue;
	};
} led_state;

struct led_handle {
	int brightness;
	int max_brightness;
};

void close_single_led(struct led_handle *led) {
	if (led->brightness > 0)
		close(led->brightness);
}

struct multicolor_handle {
	enum color color_ids[3];

	// file descriptors, names match sysfs
	FILE *brightness;
	FILE *multi_intensity;

	int max_brightness;
};

enum led_type {
	LED_GROUP,
	LED_MULTICOLOR,
};

struct status_handle {
	enum led_type type;
	union {
		struct multicolor_handle multicolor;
		struct led_handle group[COLOR_MAX];
	};
};

struct timespec delay_length = {
	.tv_sec = 0,
	// 150ms
	.tv_nsec = 150000000,
};

// see include/dt-bindings/leds/common.h in linux kernel source
char *types[] = {
	"status",
	"indicator",
	NULL,
};

int dreadint(int fd, int *value) {
	int ret;
	char buf[128];
	char *end;
	*value = 0;

	ret = lseek(fd, 0, SEEK_SET);
	if (ret == -1) {
		perror("dreadint: lseek");
		return -1;
	}

	ret = read(fd, buf, sizeof(buf) - 1);
	if (ret == -1) {
		perror("dreadint: read");
		return -1;
	}

	buf[ret] = 0;
	ret = strtol(buf, &end, 10);
	if (end == buf) {
		return -1;
	}

	*value = ret;
	return 0;
}

int parse_color_ids(char *input, int length, enum color colors[]) {
	int color_index = 0;
	int start = 0;
	int i = 0;
	memset(colors, COLOR_MAX, sizeof(enum color)*3);

	while (i < length) {
		// skip whitespace
		while (i < length && isspace(input[i])) { i++; }
		start = i;

		// find the end of the word (next whitespace)
		while (i < length && !isspace(input[i])) { i++; }

		if (i == start) break;

		// now start points to the first char in the word and i is the last
		if (strncmp(&input[start], "red", i-start) == 0) {
			colors[color_index] = COLOR_RED;
		} else if (strncmp(&input[start], "green", i-start) == 0) {
			colors[color_index] = COLOR_GREEN;
		} else if (strncmp(&input[start], "blue", i-start) == 0) {
			colors[color_index] = COLOR_BLUE;
		} else {
			info("Unknown color: \"%.*s\"\n", i-start, &input[start]);
			return false;
		}

		color_index++;
	}

	// We expect to find a controls for green, red, and blue channels. To
	// check this, we convert the colors we found to a bitflag and compare
	// them to what we expected to have. The color enum starts at zero and
	// increments by 1, so we can bitshift by that number to decide what bit
	// to use.
	return (BIT(colors[0]) | BIT(colors[1]) | BIT(colors[2]))
		== (BIT(COLOR_RED) | BIT(COLOR_BLUE) | BIT(COLOR_GREEN));
}

bool open_multicolor_led(char *type, struct multicolor_handle *dst) {
	int ret, fd = 0;
	char buf[128];

	memset(dst, 0, sizeof(*dst));

	snprintf(buf, sizeof(buf), "%s/rgb:%s/multi_index", led_dir, type);
	fd = open(buf, O_RDONLY);
	if (fd == -1) {
		info("failed to open %s\n", buf);
		goto error;
	}

	int size = read(fd, buf, sizeof(buf));
	buf[size] = 0;
	if (size <= 0) {
		perror("while reading multi_index");
		exit(1);
	}
	close(fd);

	if (!parse_color_ids(buf, size, dst->color_ids)) {
		info("failed to parse multi_index\n");
		goto error;
	}

	snprintf(buf, sizeof(buf), "%s/rgb:%s/max_brightness", led_dir, type);
	fd = open(buf, O_RDONLY);
	if (fd <= 0)
		goto error;

	ret = dreadint(fd, &dst->max_brightness);
	if (ret == -1) {
		info("dreadint: read: %d\n", errno);
		goto error;
	}
	close(fd);

	snprintf(buf, sizeof(buf), "%s/rgb:%s/brightness", led_dir, type);
	dst->brightness = fopen(buf, "r+");
	if (dst->brightness == NULL)
		goto error;

	snprintf(buf, sizeof(buf), "%s/rgb:%s/multi_intensity", led_dir, type);
	dst->multi_intensity = fopen(buf, "r+");
	if (dst->multi_intensity == NULL)
		goto error;

	return true;

error:
	if (fd > 0) close(fd);
	if (dst->brightness) fclose(dst->brightness);
	if (dst->multi_intensity) fclose(dst->multi_intensity);

	return false;
}

int open_monocolor_led(char *color, char *type, bool flip, struct led_handle *led) {
	char buf[128];
	int fd, ret;

	if (flip) {
		char *tmp = type;
		type = color;
		color = tmp;
	}

	snprintf(buf, sizeof(buf), "%s/%s:%s/brightness", led_dir, color, type);
	info("attempting to open %s\n", buf);
	led->brightness = open(buf, O_RDWR);
	if (led->brightness < 0)
		return led->brightness;

	snprintf(buf, sizeof(buf), "%s/%s:%s/max_brightness", led_dir, color, type);
	fd = open(buf, O_RDONLY);
	if (fd <= 0)
		return fd;

	ret = dreadint(fd, &led->max_brightness);
	if (ret == -1) {
		info("dreadint: read: %d\n", errno);
	}

	close(fd);
	return ret;
}

bool open_led_group(
	struct status_handle *led,
	char *type, char *red, char *green, char *blue, bool flip
) {
	struct led_handle *ret = led->group;
	memset(ret, 0, sizeof(struct led_handle) * 3);

	if (-1 == open_monocolor_led(red, type, flip, &ret[COLOR_RED]))
		goto error;

	if (-1 == open_monocolor_led(green, type, flip, &ret[COLOR_GREEN]))
		goto error;

	if (-1 == open_monocolor_led(blue, type, flip, &ret[COLOR_BLUE]))
		goto error;

	return true;

error:
	close_single_led(&ret[COLOR_RED]);
	close_single_led(&ret[COLOR_GREEN]);
	close_single_led(&ret[COLOR_BLUE]);
	return false;
}

bool open_status_leds(struct status_handle *led) {
	// 1) rgb:status
	// 2) rgb:indicator
	led->type = LED_MULTICOLOR;
	for (int i = 0; types[i] != NULL; i++) {
		if (open_multicolor_led(types[i], &led->multicolor))
			return true;
	}

	// We check all the multicolor leds, then all the monocolor leds. It's
	// relatively safe to assume that monocolor leds with the same type, are
	// in fact the same device, but not guaranteed. Also when
	// leds-group-multicolor is in use, one device will have both monocolor
	// and multicolor files, but the monocolor ones will be read only.
	led->type = LED_GROUP;

	// NOTE: these might not be a single led, there's a good chance we'll
	// guess right, but we prefer multicolor leds because they don't have
	// this issue.
	// 3) {red,green,blue}:status
	// 4) {red,green,blue}:indicator
	for (int i = 0; types[i] != NULL; i++) {
		if (open_led_group(led, types[i], "red", "green", "blue", false))
			return true;
	}

	// 5) status-led:{red,green,blue} (Motorola Droid 4)
	if (open_led_group(led, "status-led", "red", "green", "blue", true))
		return true;

	// 6) lp5523:{r,g,b} (Nokia N900)
	if (open_led_group(led, "lp5523", "r", "g", "b", true))
		return true;

	return false;
}

int led_max_brightness(struct status_handle *led, enum color led_color) {
	if (led->type == LED_MULTICOLOR) {
		return led->multicolor.max_brightness;
	} else {
		return led->group[led_color].max_brightness;
	}
}

int led_pct_to_abs(struct status_handle *led, enum color led_color, double brightness_pct) {
	return ceil(brightness_pct * (led_max_brightness(led, led_color) / 100.0));
}

double led_abs_to_pct(struct status_handle *led, enum color led_color, int brightness_pct) {
	return brightness_pct * (100.0 / led_max_brightness(led, led_color));
}

led_state led_state_read(struct status_handle *led) {
	led_state state = {{ 0, 0, 0 }};

	if (led->type == LED_MULTICOLOR) {
		int colors[3];
		rewind(led->multicolor.multi_intensity);

		int ret;
		ret = fscanf(led->multicolor.multi_intensity, "%d %d %d", &colors[0], &colors[1], &colors[2]);
		if (ret != 3) {
			error("Failed to parse multi_intensity file");
			return state;
		}

		for (int i = 0; i < 3; i++) {
			state.colors[led->multicolor.color_ids[i]] =
				led_abs_to_pct(led, led->multicolor.color_ids[i], colors[i]);
		}

		// This isn't necessary, but it makes the output more consistent
		// for integration tests.
		rewind(led->multicolor.multi_intensity);
		rewind(led->multicolor.brightness);

		return state;
	} else if (led->type == LED_GROUP) {
		for (int color_id = 0; color_id < COLOR_MAX; color_id++) {
			int brightness;
			dreadint(led->group[color_id].brightness , &brightness);
			state.colors[color_id] = led_abs_to_pct(led, color_id, brightness);
		}

		return state;
	} else {
		error("unknown led type. This is a bug.");
		exit(1);
	}
}

void led_state_write(struct status_handle *led, led_state state, int color_mask) {
	if (led->type == LED_MULTICOLOR) {
		FILE *intensity = led->multicolor.multi_intensity;
		enum color *color_ids = led->multicolor.color_ids;

		int all_color_mask = (1<<COLOR_MAX) - 1;
		if (color_mask != all_color_mask) {
			info("state missing colors, reading them\n");
			led_state base_state = led_state_read(led);
			for (int i = 0; i < COLOR_MAX; i++) {
				if ((color_mask & BIT(i)) == 0)
					state.colors[i] = base_state.colors[i];
			}
		}

		info("setting colors: red: %.0f%%, green: %.0f%%, blue: %.0f%% (mask: 0x%x)\n",
			state.red, state.green, state.blue, color_mask);

		fprintf(intensity, "%d %d %d\n",
			// The max brightness for all multicolor leds is the
			// same, so we can hard code it
			led_pct_to_abs(led, COLOR_MAX, state.colors[color_ids[0]]),
			led_pct_to_abs(led, COLOR_MAX, state.colors[color_ids[1]]),
			led_pct_to_abs(led, COLOR_MAX, state.colors[color_ids[2]])
		);

		fprintf(led->multicolor.brightness, "%d", led->multicolor.max_brightness);

		fflush(intensity);
		fflush(led->multicolor.brightness);
	} else if (led->type == LED_GROUP) {
		info("setting colors: red: %.0f%%, green: %.0f%%, blue: %.0f%% (mask: 0x%x)\n",
			state.red, state.green, state.blue, color_mask);

		for (int color_id = 0; color_id < COLOR_MAX; color_id++) {
			if (BIT(color_id) & color_mask) {
				dprintf(
					led->group[color_id].brightness, "%d\n",
					led_pct_to_abs(led, color_id, state.colors[color_id])
				);
			}
		}
	} else {
		error("unknown led type. This is a bug.");
		exit(1);
	}
}

void blink_pattern(char *colors[], int argc, struct status_handle *led) {
	led_state new_state = {{ 0, 0, 0 }};
	led_state null_state = {{ 0, 0, 0 }};
	led_state old_state = led_state_read(led);
	int color_mask = BIT(COLOR_RED) | BIT(COLOR_BLUE) | BIT(COLOR_GREEN);

	for (int i=0; i<argc; i++) {
		if (strcmp("red", colors[i]) == 0) {
			new_state.red = 100;
		} else if (strcmp("green", colors[i]) == 0) {
			new_state.green = 100;
		} else if (strcmp("blue", colors[i]) == 0) {
			new_state.blue = 100;
		} else {
			error("expected color to be one of red, green, or blue. Found %s.", colors[i]);
			exit(1);
		}
	}

	led_state_write(led, null_state, color_mask);
	nanosleep(&delay_length, NULL);

	led_state_write(led, new_state, color_mask);
	nanosleep(&delay_length, NULL);

	led_state_write(led, null_state, color_mask);
	nanosleep(&delay_length, NULL);

	led_state_write(led, old_state, color_mask);
}

void set_usage(char *name) {
	printf("usage: %s: [-q] [-v] set <color> <value> [color value]...\n", name);
}

int set_main(struct status_handle *led, int argi, int argc, char *argv[]) {
	int args = argc - (argi);
	int color_mask = 0;
	led_state state;

	if (args % 2 != 0 || args < 2) {
		set_usage(argv[0]);
		return 1;
	}

	for (int i = argi; (i + 1) < argc; i += 2) {
		char *color_str = argv[i];
		char *value_str = argv[i + 1];
		char *end = NULL;
		enum color color_id;

		errno = 0;
		long value = strtol(value_str, &end, 10);

		if (end == NULL || *end != 0 || errno) {
			error("Unable to convert \"%s\" to a number", value_str);
			exit(1);
		}

		if (strcmp(color_str, "red") == 0) {
			color_id = COLOR_RED;
		} else if (strcmp(color_str, "green") == 0) {
			color_id = COLOR_GREEN;
		} else if (strcmp(color_str, "blue") == 0) {
			color_id = COLOR_BLUE;
		} else {
			error("Unknown color \"%s\", expected one of \"red\", \"green\", or \"blue\"", color_str);
		}

		info("setting color %s(%d) to %ld\n", color_str, color_id, value);

		state.colors[color_id] = value;
		color_mask |= BIT(color_id);
	}

	led_state_write(led, state, color_mask);

	return 0;
}

int cmd_main(int argc, char *argv[]) {
	int argi = 1;

	while (argi < argc) {
		char *arg = argv[argi];
		if (strcmp(arg, "-q") == 0) {
			quiet = true;
		} else if (strcmp(arg, "-v") == 0) {
			verbose = true;
			info("enabling verbose mode\n");
		} else if (strcmp(arg, "--debug-led-dir") == 0) {
			argi++;
			if (argi >= argc) {
				error("--debug-led-dir requires a path paraemter");
				exit(1);
			}

			led_dir = argv[argi];
		} else {
			break;
		}

		argi++;
	}

	struct status_handle led;
	if (!open_status_leds(&led)) {
		error("Unable to find suitable status led");
		exit(1);
	}

	info("found a suitable status led\n");
	for (int i = argi; i < argc; i++) {
		if (strcmp("set", argv[i]) == 0) {
			return set_main(&led, i + 1, argc, argv);
		} else if (strcmp("blink", argv[i]) == 0) {
			blink_pattern(&argv[i+1], argc-i-1, &led);
			break;
		} else if (strcmp("check", argv[i]) == 0) {
			// status leds have already been successfully acquired
			return 0;
		} else {
			fprintf(stderr, "Error: expected command to be one of set, or blink. Found %s\n.", argv[i]);
		}
	}

	return 0;
}

bool parse_color_ids_str(char *input, enum color words[]) {
	return parse_color_ids(input, strlen(input), words);
}

#define assert_colors(zero, one, two) \
assert(words[0] == zero && words[1] == one && words[2] == two)

int test_main() {
	info("starting test suite\n");
	enum color words[3];
	bool ret;

	ret = parse_color_ids_str("red green blue", words);
	assert(ret);
	assert_colors(COLOR_RED, COLOR_GREEN, COLOR_BLUE);

	// it should handle newlines
	ret = parse_color_ids_str("blue green red\n", words);
	assert(ret);
	assert_colors(COLOR_BLUE, COLOR_GREEN, COLOR_RED);

	ret = parse_color_ids_str("green blue red", words);
	assert(ret);
	assert_colors(COLOR_GREEN, COLOR_BLUE, COLOR_RED);

	ret = parse_color_ids_str("green blue brown red", words);
	assert(!ret);

	ret = parse_color_ids_str("blue red brown", words);
	assert(!ret);

	ret = parse_color_ids_str("blue green", words);
	assert(!ret);

	return 0;
}

int main(int argc, char *argv[]) {
#ifdef TEST
	return test_main();
#else
	return cmd_main(argc, argv);
#endif
}
