PREFIX:=/

programs/sxmo_setpineled:
	gcc -o programs/sxmo_setpineled programs/sxmo_setpineled.c

programs/sxmo_setpinebacklight:
	gcc -o programs/sxmo_setpinebacklight programs/sxmo_setpinebacklight.c

programs/sxmo_screenlock:
	gcc -o programs/sxmo_screenlock programs/sxmo_screenlock.c -lX11

install: programs/sxmo_setpineled programs/sxmo_setpinebacklight programs/sxmo_screenlock
	mkdir -p $(PREFIX)/usr/share/sxmo
	cp configs/* $(PREFIX)/usr/share/sxmo

	mkdir -p $(PREFIX)/etc/alsa/conf.d/
	cp configs/alsa_sxmo_enable_dmix.conf $(PREFIX)/etc/alsa/conf.d/

	mkdir -p $(PREFIX)/usr/bin
	cp scripts/* $(PREFIX)/usr/bin

	chown root programs/sxmo_setpineled
	chmod u+s programs/sxmo_setpineled
	cp programs/sxmo_setpineled $(PREFIX)/usr/bin

	chown root programs/sxmo_setpinebacklight
	chmod u+s programs/sxmo_setpinebacklight
	cp programs/sxmo_setpinebacklight $(PREFIX)/usr/bin

	chown root programs/sxmo_screenlock
	chmod u+s programs/sxmo_screenlock
	cp programs/sxmo_screenlock $(PREFIX)/usr/bin
