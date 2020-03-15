#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void usage() {
  fprintf(stderr, "Usage: setpineled [red|green|blue] [0-255]\n");
}

int main(int argc, char *argv[]) {
  int brightness;
  char * color;
  char * command;

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
  if (strcmp(color, "red") && strcmp(color, "blue") && strcmp(color, "green")) {
    usage();
    return 1;
  }

  command = malloc(80);
  sprintf(
    command,
    "sh -c 'echo %d > /sys/devices/platform/leds/leds/pinephone:%s:user/brightness'",
    brightness,
    color
  );
  if (setuid(0)) {
    fprintf(stderr, "setuid(0) failed\n");
  } else {
    return system(command);
  }
}
