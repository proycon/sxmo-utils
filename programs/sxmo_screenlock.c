#include <dirent.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <X11/keysym.h>
#include <X11/XF86keysym.h>
#include <X11/XKBlib.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <sys/types.h>
#include <linux/rtc.h>

// Types
enum State {
	StateNoInput,		 // Screen on / input lock
	StateNoInputNoScreen, // Screen off / input lock
	StateSuspend,		 // Deep sleep
	StateSuspendPending,  // Suspend 'woken up', must leave state in <5s, or kicks to StateSuspend
	StateDead			 // Exit the appliation
};
enum Color {
	Red,
	Blue,
	Purple,
	Off
};

// Fn declarations
int checkrtcwake();
void configuresuspendsettingsandwakeupsources();
time_t convert_rtc_time(struct rtc_time * rtc);
void die(const char *err, ...);
int getoldbrightness();
void init_rtc();
void lockscreen(Display *dpy, int screen);
void readinputloop(Display *dpy, int screen);
int presuspend();
void postwake();
void setpineled(enum Color c);
int setup_rtc_wakeup();
void sigterm();
void syncstate();
void usage();
void writefile(char *filepath, char *str);

// Variables
Display *dpy;
enum State state = StateNoInput;
int suspendtimeouts = 35;
int suspendpendingsceenon = 0;
int suspendpendingtimeouts = 0;
KeySym lastkeysym = XK_Cancel;
int lastkeyn = 0;
char oldbrightness[10] = "200";
char * brightnessfile = "/sys/devices/platform/backlight/backlight/backlight/brightness";
char * powerstatefile = "/sys/power/state";
int rtc_fd = 0; //file descriptor
time_t wakeinterval = 0; //wake every x seconds
time_t waketime = 0; //next wakeup time according to the RTC clock

#define RTC_DEVICE	  "/dev/rtc0"

time_t
convert_rtc_time(struct rtc_time * rtc) {
	struct tm		 tm;
	memset(&tm, 0, sizeof tm);
	tm.tm_sec = rtc->tm_sec;
	tm.tm_min = rtc->tm_min;
	tm.tm_hour = rtc->tm_hour;
	tm.tm_mday = rtc->tm_mday;
	tm.tm_mon = rtc->tm_mon;
	tm.tm_year = rtc->tm_year;
	tm.tm_isdst = -1;  /* assume the system knows better than the RTC */
	return mktime(&tm);
}

int setup_rtc_wakeup() {
	//(code adapted from util-linux's rtcwake)
	struct tm		 *tm;
	struct rtc_wkalrm	wake;
	struct rtc_time now_rtc;

	if (ioctl(rtc_fd, RTC_RD_TIME, &now_rtc) < 0) {
		fprintf(stderr, "Error reading rtc time\n");
	}
	const time_t now = convert_rtc_time(&now_rtc);
	waketime = now + wakeinterval;

	tm = localtime(&waketime);

	wake.time.tm_sec = tm->tm_sec;
	wake.time.tm_min = tm->tm_min;
	wake.time.tm_hour = tm->tm_hour;
	wake.time.tm_mday = tm->tm_mday;
	wake.time.tm_mon = tm->tm_mon;
	wake.time.tm_year = tm->tm_year;
	/* wday, yday, and isdst fields are unused by Linux */
	wake.time.tm_wday = -1;
	wake.time.tm_yday = -1;
	wake.time.tm_isdst = -1;

	fprintf(stderr, "Setting RTC wakeup to %ld: (UTC) %s", waketime, asctime(tm));

	if (ioctl(rtc_fd, RTC_ALM_SET, &wake.time) < 0) {
		fprintf(stderr, "error setting rtc alarm\n");
		return -1;
	}
	if (ioctl(rtc_fd, RTC_AIE_ON, 0) < 0) {
		fprintf(stderr, "error enabling rtc alarm\n");
		return -1;
	}
	return 0;
}

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
			"/sys/class/wakeup/%.50s/device/power/wakeup",
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

	// Enable IRQ wakeup source (incoming call) 5.8
	fprintf(stderr, "Enable 5.8 IRQ wakeup source\n");
	writefile(
		"/sys/devices/platform/gpio-keys/power/wakeup",
		"enabled"
	 );

	 // Enable IRQ wakeup source (incoming call) 5.9
	fprintf(stderr, "Enable 5.9 IRQ wakeup source\n");
	writefile(
		"/sys/devices/platform/soc/1c28c00.serial/serial1/serial1-0/power/wakeup",
		"enabled"
	 );

	// Enable rtc wakeup source
	fprintf(stderr, "Enable rtc wakeup source\n");
	writefile(
		"/sys/devices/platform/soc/1f00000.rtc/power/wakeup",
		"enabled"
	);

	//set RTC wake
	if (wakeinterval > 0) setup_rtc_wakeup();

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
	if (wakeinterval) close(rtc_fd);
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
						waketime = 0;
						state = StateDead;
						break;
				}
				syncstate();
			}
		} else if (state == StateSuspendPending) {
			suspendpendingtimeouts++;
			// # E.g. after suspendtimeouts seconds kick back into suspend
			if (suspendpendingtimeouts > suspendtimeouts) state = StateSuspend;
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

int
presuspend() {
	//called prior to suspension, a non-zero return value cancels suspension
	return system("sxmo_presuspend.sh");
}

void
postwake() {
	//called after fully waking up (not used for temporary rtc wakeups)
	system("sxmo_postwake.sh");
}

int
checkrtcwake()
{
	struct rtc_time now;
	if (ioctl(rtc_fd, RTC_RD_TIME, &now) < 0) {
		fprintf(stderr, "Error reading rtc time\n");
		return -1;
	}

	const long int timediff = convert_rtc_time(&now) - waketime;
	fprintf(stderr, "Checking rtc wake? timediff=%ld\n", timediff);
	if (timediff >= 0 && timediff <= 3) {
		fprintf(stderr, "Calling RTC wake script\n");
		setpineled(Blue);
		return system("sxmo_rtcwake.sh");
	}
	return 0;
}

void
syncstate()
{
	int rtcresult;
	if (state == StateSuspend) {
		if (presuspend() != 0) {
			state = StateDead;
		} else {
			setpineled(Red);
			configuresuspendsettingsandwakeupsources();
			writefile(powerstatefile, "mem");
			//---- program blocks here due to sleep ----- //
			// Just woke up again
			fprintf(stderr, "Resetting usb connection to the modem\n");
			writefile("/sys/bus/usb/drivers/usb/unbind", "3-1");
			writefile("/sys/bus/usb/drivers/usb/bind", "3-1");
			fprintf(stderr, "Woke up\n");
			if (waketime > 0) {
				rtcresult = checkrtcwake();
			} else {
				rtcresult = 0;
			}
			if (rtcresult == 0) {
				state = StateSuspendPending;
				suspendpendingtimeouts = 0;
			} else {
				postwake();
				state = StateDead;
			}
		}
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
	fprintf(stderr, "Usage: sxmo_screenlock [--screen-off] [--suspend] [--wake-interval n]\n");
}


void init_rtc() {
	rtc_fd = open(RTC_DEVICE, O_RDONLY);
	if (rtc_fd < 0) {
		die("Unable to open rtc device");
		exit(EXIT_FAILURE);
	}
}

int
main(int argc, char **argv) {
	int screen;
	int i;
	enum State target = StateNoInput;

	signal(SIGTERM, sigterm);

	const char* suspendtimeouts_str = getenv("SXMO_SUSPENDTIMEOUTS");
	if (suspendtimeouts_str != NULL) suspendtimeouts = atoi(suspendtimeouts_str);

	const char* rtcwakeinterval = getenv("SXMO_RTCWAKEINTERVAL");
	if (rtcwakeinterval != NULL) wakeinterval = atoi(rtcwakeinterval);

	const char* screen_off = getenv("SXMO_LOCK_SCREEN_OFF");
	if (screen_off != NULL && atoi(screen_off)) target = StateNoInputNoScreen;

	const char* suspend = getenv("SXMO_LOCK_SUSPEND");
	if (suspend != NULL && atoi(suspend)) target = StateSuspend;

	//parse command line arguments
	for (i = 1; i < argc; i++) {
		if(!strcmp(argv[i], "-h")) {
			usage();
			return 0;
		} else if(!strcmp(argv[i], "--screen-off")) {
			target = StateNoInputNoScreen;
		} else if(!strcmp(argv[i], "--suspend")) {
			target = StateSuspend;
		} else if(!strcmp(argv[i], "--wake-interval")) {
			wakeinterval = (time_t) atoi(argv[++i]);
		} else {
			fprintf(stderr, "Invalid argument: %s\n", argv[i]);
			return 2;
		}
	}

	if (setuid(0))
		die("setuid(0) failed\n");
	if (!(dpy = XOpenDisplay(NULL)))
		die("Cannot open display\n");

	if (wakeinterval) init_rtc();

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
	if (wakeinterval) {
		ioctl(rtc_fd, RTC_AIE_OFF, 0);
		close(rtc_fd);
	}
	return 0;
}
