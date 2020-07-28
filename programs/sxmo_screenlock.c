#include <dirent.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <X11/keysym.h>
#include <X11/XF86keysym.h>
#include <X11/XKBlib.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

// Types
enum State {
	StateNoInput,         // Screen on / input lock
	StateNoInputNoScreen, // Screen off / input lock
	StateSuspend,         // Deep sleep
	StateSuspendPending,  // Suspend 'woken up', must leave state in <5s, or kicks to StateSuspend
	StateDead             // Exit the appliation
};
enum Color {
	Red,
	Blue,
	Purple,
	Off
};

// Fn declarations
void configuresuspendsettingsandwakeupsources();
void die(const char *err, ...);
int getoldbrightness();
void lockscreen(Display *dpy, int screen);
void readinputloop(Display *dpy, int screen);
void setpineled(enum Color c);
void syncstate();
void updatestatusbar();
void writefile(char *filepath, char *str);

// Variables
Display *dpy;
enum State state = StateNoInput;
int suspendpendingsceenon = 0;
int suspendpendingtimeouts = 0;
KeySym lastkeysym = XK_Cancel;
int lastkeyn = 0;
char oldbrightness[10] = "200";
char * brightnessfile = "/sys/devices/platform/backlight/backlight/backlight/brightness";
char * powerstatefile = "/sys/power/state";

void
configuresuspendsettingsandwakeupsources()
{
	// Disable all wakeup sources
	struct dirent *wakeupsource;
	char wakeuppath[100];
	DIR *wakeupsources = opendir("/sys/class/wakeup");
	if (wakeupsources == NULL)
		die("Couldn't open directory /sys/class/wakeup\n");
	while ((wakeupsource = readdir(wakeupsources)) != NULL) {
		sprintf(
			wakeuppath, 
			"/sys/class/wakeup/%s/device/power/wakeup",
			wakeupsource->d_name
		);
		fprintf(stderr, "Disabling wakeup source: %s", wakeupsource->d_name);
		writefile(wakeuppath, "disabled");
		fprintf(stderr, ".. ok\n");
	}
	closedir(wakeupsources);

	// Enable powerbutton wakeup source
	fprintf(stderr, "Enable powerbutton wakeup source\n");
	writefile(
		"/sys/devices/platform/soc/1f03400.rsb/sunxi-rsb-3a3/axp221-pek/power/wakeup",
		"enabled"
	);

	// Enable rtc wakeup source
	fprintf(stderr, "Enable rtc wakeup source\n");
	writefile(
		"/sys/devices/platform/soc/1f00000.rtc/power/wakeup",
		"enabled"
	);

	// Temporary hack to disable USB driver that doesn't suspend
	fprintf(stderr, "Disabling buggy USB driver\n");
	writefile(
		"/sys/devices/platform/soc/1c19000.usb/driver/unbind",
		"1c19000.usb"
	);

	// Temporary hack to disable Bluetooth driver that crashes on suspend 1/5th the time
	fprintf(stderr, "Disabling buggy Bluetooth driver\n");
	writefile(
		"/sys/bus/serial/drivers/hci_uart_h5/unbind",
		"serial0-0"
	);

	// E.g. make sure we're using CRUST
	fprintf(stderr, "Flip mem_sleep setting to use crust\n");
	writefile("/sys/power/mem_sleep", "deep");
}

void
die(const char *err, ...)
{
	fprintf(stderr, "Error: %s", err);
	state = StateDead;
	syncstate();
	exit(1);
}

void
sigterm()
{
	state = StateDead;
	syncstate();
	exit(0);
}

int
getoldbrightness() {
	char * buffer = 0;
	long length;
	FILE * f = fopen(brightnessfile, "r");
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
		sprintf(oldbrightness, "%d", atoi(buffer));
	}
}


void
lockscreen(Display *dpy, int screen)
{
	// Loosely derived from suckless' slock's lockscreen binding logic but
	// alot more coarse, intentionally so can be triggered while grab_key
	// for dwm multikey path already holding..
	int i, ptgrab, kbgrab;
	Window root;
	root = RootWindow(dpy, screen);
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
}

void
readinputloop(Display *dpy, int screen) {
	KeySym keysym;
	XEvent ev;
	char buf[32];
	fd_set fdset;
	int xfd;
	int selectresult;
	struct timeval xeventtimeout = {1, 0};
	xfd = ConnectionNumber(dpy);

	for (;;) {
		FD_ZERO(&fdset);
		FD_SET(xfd, &fdset);
		if (state == StateSuspendPending)
			selectresult = select(FD_SETSIZE, &fdset, NULL, NULL, &xeventtimeout);
		else
			selectresult = select(FD_SETSIZE, &fdset, NULL, NULL, NULL);

		if (FD_ISSET(xfd, &fdset) && XPending(dpy)) {
			XNextEvent(dpy, &ev);
			if (ev.type == KeyRelease) {
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
				lastkeysym = XK_Cancel;
				switch (keysym) {
					case XF86XK_AudioRaiseVolume:
						suspendpendingsceenon = state == StateNoInput;
						suspendpendingtimeouts = 0;
						state = StateSuspend;
						break;
					case XF86XK_AudioLowerVolume:
						if (state == StateNoInput) state = StateNoInputNoScreen;
						else if (state == StateNoInputNoScreen) state = StateNoInput;
						else if (state == StateSuspendPending && suspendpendingsceenon) state = StateNoInputNoScreen;
						else state = StateNoInput;
						break;
					case XF86XK_PowerOff:
						state = StateDead;
						break;
				}
				syncstate();
			}
		} else if (state == StateSuspendPending) {
			suspendpendingtimeouts++;
			// # E.g. after 4s kick back into suspend
			if (suspendpendingtimeouts > 4) state = StateSuspend;
			syncstate();
		}

		if (state == StateDead) break;
	}
}

void
setpineled(enum Color c)
{
	if (c == Red) {
		writefile("/sys/class/leds/red:indicator/brightness", "1");
		writefile("/sys/class/leds/blue:indicator/brightness", "0");
	} else if (c == Blue) {
		writefile("/sys/class/leds/red:indicator/brightness", "0");
		writefile("/sys/class/leds/blue:indicator/brightness", "1");
	} else if (c == Purple) {
		writefile("/sys/class/leds/red:indicator/brightness", "1");
		writefile("/sys/class/leds/blue:indicator/brightness", "1");
	} else if (c == Off) {
		writefile("/sys/class/leds/red:indicator/brightness", "0");
		writefile("/sys/class/leds/blue:indicator/brightness", "0");
	}
}

void
syncstate()
{
	if (state == StateSuspend) {
		setpineled(Red);
		configuresuspendsettingsandwakeupsources();
		writefile(powerstatefile, "mem");
		// Just woke up
		updatestatusbar();
		state = StateSuspendPending;
		suspendpendingtimeouts = 0;
		syncstate();
	} else if (state == StateNoInput) {
		setpineled(Blue);
		writefile(brightnessfile, oldbrightness);
	} else if (state == StateNoInputNoScreen) {
		setpineled(Purple);
		writefile(brightnessfile, "0");
	} else if (state == StateSuspendPending) {
		writefile(brightnessfile, suspendpendingsceenon ? oldbrightness : "0");
		setpineled(Off);
		usleep(1000 * 100);
		setpineled(suspendpendingsceenon ? Blue : Purple);
	} else if (state == StateDead) {
		writefile(brightnessfile, oldbrightness);
		setpineled(Off);
	}
}

void
updatestatusbar()
{
	system("sxmo_statusbarupdate.sh");
}

void
writefile(char *filepath, char *str)
{
	int f;
	f = open(filepath, O_WRONLY);
	if (f != -1) {
		write(f, str, strlen(str));
		close(f);
	} else {
		fprintf(stderr, "Couldn't open filepath <%s>\n", filepath);
	}
}

void usage() {
	fprintf(stderr, "Usage: sxmo_screenlock [--screen-off] [--suspend]\n");
}

int
main(int argc, char **argv) {
	int screen;
	int i;
	enum State target = StateNoInput;

	signal(SIGTERM, sigterm);

	//parse command line arguments
	for (i = 1; i < argc; i++) {
		if(!strcmp(argv[i], "-h")) {
			usage();
			return 0;
		} else if(!strcmp(argv[i], "--screen-off")) {
			target = StateNoInputNoScreen;
		} else if(!strcmp(argv[i], "--suspend")) {
			target = StateSuspend;
		} else {
			fprintf(stderr, "Invalid argument: %s\n", argv[i]);
			return 2;
		}
	}

	if (setuid(0))
		die("setuid(0) failed\n");
	if (!(dpy = XOpenDisplay(NULL)))
		die("Cannot open display\n");

	XkbSetDetectableAutoRepeat(dpy, True, NULL);
	screen = XDefaultScreen(dpy);
	XSync(dpy, 0);
	getoldbrightness();
	syncstate();
	lockscreen(dpy, screen);
	if ((target == StateNoInputNoScreen) || (target == StateSuspend)) {
		state = StateNoInputNoScreen;
		syncstate();
	}
	if (target == StateSuspend) {
		state = StateSuspend;
		syncstate();
	}
	readinputloop(dpy, screen);
	return 0;
}
