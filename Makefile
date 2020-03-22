PREFIX:=/usr

programs/sxmo_setpineled:
	gcc -o programs/sxmo_setpineled programs/sxmo_setpineled.c

programs/sxmo_setpinebacklight:
	gcc -o programs/sxmo_setpinebacklight programs/sxmo_setpinebacklight.c

install: programs/sxmo_setpineled programs/sxmo_setpinebacklight
	mkdir -p $(PREFIX)/share/sxmo
	cp configs/* $(PREFIX)/share/sxmo
	cp configs/asound.conf /etc/

	mkdir -p $(PREFIX)/bin
	cp scripts/* $(PREFIX)/bin

	chown root programs/sxmo_setpineled
	chmod u+s programs/sxmo_setpineled
	cp programs/sxmo_setpineled $(PREFIX)/bin

	chown root programs/sxmo_setpinebacklight
	chmod u+s programs/sxmo_setpinebacklight
	cp programs/sxmo_setpinebacklight $(PREFIX)/bin
