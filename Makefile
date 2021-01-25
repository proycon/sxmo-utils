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
	cd configs && find . -type f -exec install -D -m 0644 "{}" "$(PREFIX)/usr/share/sxmo/{}" \; && cd ..

	# Configs
	install -D -m 0644 -t $(PREFIX)/etc/alsa/conf.d/ configs/alsa/alsa_sxmo_enable_dmix.conf

	install -D -m 0644 -t $(PREFIX)/etc/polkit-1/rules.d/ configs/polkit/*.rules

	install -D -m 0644 -t $(PREFIX)/etc/udev/rules.d/ configs/udev/*.rules

	install -D -m 0644 -t $(PREFIX)/usr/share/applications/ configs/xdg/mimeapps.list

	# Bin
	install -D -t $(PREFIX)/usr/bin scripts/*/*

	install -D -o root -m 4755 programs/sxmo_setpineled $(PREFIX)/usr/bin/

	install -D -o root -m 4755 programs/sxmo_setpinebacklight $(PREFIX)/usr/bin/

	install -D -o root -m 4755 programs/sxmo_screenlock $(PREFIX)/usr/bin/

	install -D programs/sxmo_megiaudioroute $(PREFIX)/usr/bin/
	install -D programs/sxmo_vibratepine $(PREFIX)/usr/bin/
