#include <X11/XF86keysym.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <X11/keysym.h>
#include <X11/Xlib.h>

static int running = 1;
static int lastkeysym = NULL;
static int lastkeyn = 0;
static int oldbrightness = 10;
static int screenon = 1;
static char screentogglecommand[100];
static char pineledcommand[100];
static char * brightnessfile = "/sys/devices/platform/backlight/backlight/backlight/brightness";



void updatepineled(int red, int brightness) {
    sprintf(
      pineledcommand, 
      "sh -c 'echo %d > /sys/devices/platform/leds/leds/pinephone:%s:user/brightness'", 
      brightness, 
      red ? "red" : "blue"
    );
    system(pineledcommand);
}

void updatescreenon(int on) {
    int b = on ? oldbrightness : 0;
    sprintf(screentogglecommand, "sh -c 'echo %d > %s'", b, brightnessfile);
    system(screentogglecommand);
    updatepineled(0, b ? 1 : 0);
    updatepineled(1, b ? 0 : 1);
}

void cleanup() {
  updatescreenon(1);
  updatepineled(1, 0);
  updatepineled(0, 0);
}

static void die(const char *err, ...) {
        fprintf(stderr, "Error: %s", err);
        cleanup();
        exit(1);
}
static void usage(void) {
        die("usage: slock [-v] [cmd [arg ...]]\n");
}

// Loosely derived from suckless' slock's lockscreen binding logic but
// alot more coarse, intentionally so can be triggered while grab_key
// for dwm multikey path already holding..
void lockscreen(Display *dpy, int screen) {
  int i, ptgrab, kbgrab;
  //XSetWindowAttributes wa;
  Window root;
  //win,
  root = RootWindow(dpy, screen);
  //wa.override_redirect = 1;
  //win = XCreateWindow(dpy, root, 0, 0,
  //                          DisplayWidth(dpy, screen),
  //                          DisplayHeight(dpy, screen),
  //                          0, DefaultDepth(dpy, screen),
  //                          CopyFromParent,
  //                          DefaultVisual(dpy, screen),
  //                          CWOverrideRedirect | CWBackPixel, &wa);
  for (i = 0, ptgrab = kbgrab = -1; i < 9999999; i++) {
         if (ptgrab != GrabSuccess) {
                 ptgrab = XGrabPointer(dpy, root, False,
                                       ButtonPressMask | ButtonReleaseMask |
                                       PointerMotionMask, GrabModeAsync,
                                       GrabModeAsync, None, None, CurrentTime);
         }
         if (kbgrab != GrabSuccess) {
                 kbgrab = XGrabKeyboard(dpy, root, True,
                                        GrabModeAsync, GrabModeAsync, CurrentTime);
         }
          if (ptgrab == GrabSuccess && kbgrab == GrabSuccess) {
                  XSelectInput(dpy, root, SubstructureNotifyMask);
                  return;
          }
          usleep(100000);
  }
  return;
}


void
readinputloop(Display *dpy, int screen) {
        KeySym keysym;
        XEvent ev;
        char buf[32];

        while (running && !XNextEvent(dpy, &ev)) {
                if (ev.type == KeyPress) {
                        XLookupString(&ev.xkey, buf, sizeof(buf), &keysym, 0);
                        if (lastkeysym == keysym) {
                                lastkeyn++;
                        } else {
                                lastkeysym = keysym;
                                lastkeyn = 1;
                        }

                        if (lastkeyn < 3)
                                continue;

                        lastkeyn = 0;
                        lastkeysym = NULL;

                        switch (keysym) {
                        case XF86XK_AudioRaiseVolume:
                        case XF86XK_AudioLowerVolume:
                              screenon = !screenon;
                              updatescreenon(screenon);
                              break;
                        case XF86XK_PowerOff:
                              cleanup();
                              running = 0;
                              break;
                        }
                }
        }

}

int
getoldbrightness() {
  char * buffer = 0;
  long length;
  FILE * f = fopen(brightnessfile, "rb");
  if (f) {
    fseek(f, 0, SEEK_END);
    length = ftell(f);
    fseek(f, 0, SEEK_SET);
    buffer = malloc(length);
    if (buffer) {
      fread(buffer, 1, length, f);
    }
    fclose(f);
  }
  if (buffer) {
    oldbrightness = atoi(buffer);
  }
}

int
main(int argc, char **argv) {
        Display *dpy;
        Screen *screen;

        

        if (setuid(0))
                die("setuid(0) failed\n");
        if (!(dpy = XOpenDisplay(NULL)))
                die("Cannot open display\n");

        screen = XDefaultScreen(dpy);
        XSync(dpy, 0);
        getoldbrightness();
        updatescreenon(1);
        lockscreen(dpy, screen);
        XSync(dpy, 0);
        readinputloop(dpy, screen);
        return 0;
}
