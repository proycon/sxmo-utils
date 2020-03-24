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


void
updatescreen() {
        sprintf(
                screentogglecommand,
                "sh -c 'echo %d > /sys/devices/platform/backlight/backlight/backlight/brightness'",
                screenon ? oldbrightness : 0
        );
        if (screenon) {
          system("sh -c 'echo 1 > /sys/devices/platform/leds/leds/pinephone:blue:user/brightness'");
          system("sh -c 'echo 0 > /sys/devices/platform/leds/leds/pinephone:red:user/brightness'");
        } else {
          system("sh -c 'echo 0 > /sys/devices/platform/leds/leds/pinephone:blue:user/brightness'");
          system("sh -c 'echo 1 > /sys/devices/platform/leds/leds/pinephone:red:user/brightness'");
        }
        system(screentogglecommand);
}

void
cleanupscreen() {
    screenon = 1;
    updatescreen();
    system("sh -c 'echo 0 > /sys/devices/platform/leds/leds/pinephone:red:user/brightness'");
    system("sh -c 'echo 0 > /sys/devices/platform/leds/leds/pinephone:blue:user/brightness'");
}

static void die(const char *err, ...) {
        fprintf(stderr, "Error: %s", err);
        cleanupscreen();
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
                              screenon = !screenon;
                              updatescreen();

                                break;
                        case XF86XK_AudioLowerVolume:
                              screenon = !screenon;
                              updatescreen();
                                break;
                        case XF86XK_PowerOff:
                              cleanupscreen();
                              running = 0;
                              break;
                        }
                }
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

        updatescreen();
        screen = XDefaultScreen(dpy);
        XSync(dpy, 0);
        lockscreen(dpy, screen);
        XSync(dpy, 0);
        readinputloop(dpy, screen);
        return 0;
}
