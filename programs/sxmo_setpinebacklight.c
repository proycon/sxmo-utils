#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

char * pbpScreen = "/sys/class/backlight/edp-backlight/brightness";
char * ppScreen = "/sys/devices/platform/backlight/backlight/backlight/brightness";

void usage() {
  fprintf(stderr, "Usage: sxmo_setpinebacklight [number]\n");
}

void writeFile(char *filepath, int brightness) {
  FILE *f;
  f = fopen(filepath, "w+");
  fprintf(f, "%d\n", brightness);
  fclose(f);
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

  if (setuid(0)) {
    fprintf(stderr, "setuid(0) failed\n");
    return 1;
  }

  if (access(pbpScreen, F_OK) != -1) {
    writeFile(pbpScreen, brightness);
    fprintf(stderr, "Set PBP brightness to %d\n", brightness);
  } else if (access(ppScreen, F_OK) != -1) {
    writeFile(ppScreen, brightness);
    fprintf(stderr, "Set PP brightness to %d\n", brightness);
  } else {
    fprintf(stderr, "Neither PP or PBP Screen found!\n");
  }
}
