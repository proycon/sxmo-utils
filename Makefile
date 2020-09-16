PREFIX:=/

.PHONY: install shellcheck

PROGRAMS = \
	programs/sxmo_setpineled \
	programs/sxmo_setpinebacklight \
	programs/sxmo_screenlock \
	programs/sxmo_megiaudioroute \
	programs/sxmo_vibratepine

all: shellcheck $(PROGRAMS)

shellcheck:
	shellcheck scripts/*/*

programs/sxmo_setpineled: programs/sxmo_setpineled.c
	gcc -o programs/sxmo_setpineled programs/sxmo_setpineled.c

programs/sxmo_setpinebacklight: programs/sxmo_setpinebacklight.c
	gcc -o programs/sxmo_setpinebacklight programs/sxmo_setpinebacklight.c

programs/sxmo_screenlock: programs/sxmo_screenlock.c
	gcc -o programs/sxmo_screenlock programs/sxmo_screenlock.c -lX11

programs/sxmo_megiaudioroute: programs/sxmo_megiaudioroute.c
	gcc -o programs/sxmo_megiaudioroute programs/sxmo_megiaudioroute.c

programs/sxmo_vibratepine: programs/sxmo_vibratepine.c
	gcc -o programs/sxmo_vibratepine programs/sxmo_vibratepine.c

clean:
	rm programs/sxmo_setpineled programs/sxmo_screenlock programs/sxmo_setpinebacklight programs/sxmo_megiaudioroute programs/sxmo_vibratepine

install: $(PROGRAMS)
	mkdir -p $(PREFIX)/usr/share/sxmo
	cp -r configs/* $(PREFIX)/usr/share/sxmo

	mkdir -p $(PREFIX)/etc/alsa/conf.d/
	cp configs/alsa/alsa_sxmo_enable_dmix.conf $(PREFIX)/etc/alsa/conf.d/

	mkdir -p $(PREFIX)/etc/polkit-1/rules.d
	cp configs/polkit/*.rules $(PREFIX)/etc/polkit-1/rules.d/

	mkdir -p $(PREFIX)/etc/udev/rules.d
	cp configs/udev/*.rules $(PREFIX)/etc/udev/rules.d/

	mkdir -p $(PREFIX)/usr/bin
	cp scripts/*/* $(PREFIX)/usr/bin

	chown root programs/sxmo_setpineled
	chmod u+s programs/sxmo_setpineled
	cp programs/sxmo_setpineled $(PREFIX)/usr/bin

	chown root programs/sxmo_setpinebacklight
	chmod u+s programs/sxmo_setpinebacklight
	cp programs/sxmo_setpinebacklight $(PREFIX)/usr/bin

	chown root programs/sxmo_screenlock
	chmod u+s programs/sxmo_screenlock
	cp programs/sxmo_screenlock $(PREFIX)/usr/bin

	cp programs/sxmo_megiaudioroute $(PREFIX)/usr/bin
	cp programs/sxmo_vibratepine $(PREFIX)/usr/bin
