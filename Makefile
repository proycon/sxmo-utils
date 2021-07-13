PREFIX:=/usr

.PHONY: install shellcheck

PROGRAMS = \
	programs/sxmo_megiaudioroute \
	programs/sxmo_vibratepine

all: $(PROGRAMS)

test: shellcheck

shellcheck:
	shellcheck -x scripts/*/*

programs/sxmo_megiaudioroute: programs/sxmo_megiaudioroute.c
	gcc -o programs/sxmo_megiaudioroute programs/sxmo_megiaudioroute.c

programs/sxmo_vibratepine: programs/sxmo_vibratepine.c
	gcc -o programs/sxmo_vibratepine programs/sxmo_vibratepine.c

clean:
	rm -f programs/sxmo_megiaudioroute programs/sxmo_vibratepine

install: $(PROGRAMS)
	cd configs && find . -type f -exec install -D -m 0644 "{}" "$(DESTDIR)$(PREFIX)/share/sxmo/{}" \; && cd ..
	cd configs && find default_hooks -type f -exec install -D -m 0655 "{}" "$(DESTDIR)$(PREFIX)/share/sxmo/{}" \; && cd ..

	cd resources && find . -type f -exec install -D -m 0644 "{}" "$(DESTDIR)$(PREFIX)/share/sxmo/{}" \; && cd ..

	# Configs
	install -D -m 0755 -t $(DESTDIR)/etc/init.d configs/openrc/sxmo-setpermissions

	install -D -m 0644 -t $(DESTDIR)/etc/alsa/conf.d/ configs/alsa/alsa_sxmo_enable_dmix.conf

	install -D -m 0644 -t $(DESTDIR)/etc/udev/rules.d/ configs/udev/*.rules

	install -D -m 0700 -t $(DESTDIR)/etc/sudoers.d/ configs/sudo/*

	install -D -m 0644 -t $(DESTDIR)$(PREFIX)/share/applications/ configs/xdg/mimeapps.list
	install -D -m 0644 -t $(DESTDIR)$(PREFIX)/share/xsessions/ configs/applications/sxmo.desktop

	install -D -m 0644 -t $(DESTDIR)/etc/sudoers.d/ configs/sudo/poweroff

	install -D -m 0644 -T configs/xorg/monitor.conf $(DESTDIR)$(PREFIX)/share/X11/xorg.conf.d/90-monitor.conf

	mkdir -p $(DESTDIR)/etc/NetworkManager/dispatcher.d
	install -D -m 0755 -T configs/networkmanager/updatestatusbar.sh $(DESTDIR)/etc/NetworkManager/dispatcher.d/10-updatestatusbar.sh
	install -D -m 0755 -T configs/networkmanager/resetscaninterval.sh $(DESTDIR)/etc/NetworkManager/dispatcher.d/20-resetscaninterval.sh

	# Bin
	install -D -t $(DESTDIR)$(PREFIX)/bin scripts/*/*

	install -D programs/sxmo_megiaudioroute $(DESTDIR)$(PREFIX)/bin/
	install -D programs/sxmo_vibratepine $(DESTDIR)$(PREFIX)/bin/
	@echo "-------------------------------------------------------------------">&2
	@echo "NOTICE 1: Do not forget to add sxmo-setpermissions to your init system, e.g. for openrc: rc-update add sxmo-setpermissions default && rc-service sxmo-setpermissions start" >&2
	@echo "-------------------------------------------------------------------">&2
	@echo "NOTICE 2: It is recommended you interactively run sxmo_migrate.sh after an upgrade to check your configuration files and custom hooks against the defaults (it will not make any changes unless explicitly told to)" >&2
	@echo "-------------------------------------------------------------------">&2
