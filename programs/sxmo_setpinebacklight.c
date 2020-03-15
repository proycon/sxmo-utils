#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void usage() {
  fprintf(stderr, "Usage: setpinebacklight [0-10]\n");
}

int main(int argc, char *argv[]) {
  char * command;
  int brightness;

  if (argc < 2) {
    usage();
    return 1;
  }
  argc--;
  brightness = atoi(argv[argc--]);

  if (brightness < 0 || brightness > 10) {
    usage();
    return 1;
  }

  command = malloc(100);
  sprintf(
    command,
    "sh -c 'echo %d > /sys/devices/platform/backlight/backlight/backlight/brightness'",
    brightness
  );
  if (setuid(0)) {
    fprintf(stderr, "setuid(0) failed\n");
  } else {
    return system(command);
  }
}
