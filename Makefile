PREFIX:=/usr

.PHONY: install shellcheck

VERSION:=1.9.0

GITVERSION:=$(shell git describe --tags)

PROGRAMS = \
	programs/sxmo_vibrate \
	programs/sxmo_splitchar

all: $(PROGRAMS)

test: shellcheck

shellcheck:
	shellcheck -x scripts/*/*.sh

programs/sxmo_vibrate: programs/sxmo_vibrate.c
	gcc -o programs/sxmo_vibrate programs/sxmo_vibrate.c

programs/sxmo_splitchar: programs/sxmo_splitchar.c
	gcc -o programs/sxmo_splitchar programs/sxmo_splitchar.c

clean:
	rm -f programs/sxmo_vibrate programs/sxmo_splitchar

install: $(PROGRAMS)
	cd configs && find . -type f -exec install -D -m 0644 "{}" "$(DESTDIR)$(PREFIX)/share/sxmo/{}" \; && cd ..
	cd configs && find default_hooks -exec cp -rP "{}" "$(DESTDIR)$(PREFIX)/share/sxmo/{}" \; -exec chmod 0755 -R "$(DESTDIR)$(PREFIX)/share/sxmo/{}" \; && cd ..

	[ -n "$(GITVERSION)" ] && echo "$(GITVERSION)" > "$(DESTDIR)$(PREFIX)/share/sxmo/version" || echo "$(VERSION)" > "$(DESTDIR)$(PREFIX)/share/sxmo/version"

	cd resources && find . -type f -exec install -D -m 0644 "{}" "$(DESTDIR)$(PREFIX)/share/sxmo/{}" \; && cd ..

	# Configs
	install -D -m 0755 -t $(DESTDIR)/etc/init.d configs/openrc/sxmo-setpermissions

	install -D -m 0644 -t $(DESTDIR)/etc/udev/rules.d/ configs/udev/*.rules

	install -D -m 0644 -t $(DESTDIR)$(PREFIX)/share/applications/ configs/xdg/mimeapps.list
	install -D -m 0644 -t $(DESTDIR)$(PREFIX)/share/xsessions/ configs/applications/sxmo.desktop
	install -D -m 0644 -t $(DESTDIR)$(PREFIX)/share/wayland-sessions/ configs/applications/swmo.desktop

	install -D -m 0640 -t $(DESTDIR)/etc/doas.d/ configs/doas/sxmo.conf

	install -D -m 0644 -T configs/xorg/monitor.conf $(DESTDIR)$(PREFIX)/share/X11/xorg.conf.d/90-monitor.conf

	mkdir -p $(DESTDIR)/etc/NetworkManager/dispatcher.d

	install -D -m 0644 -T configs/appcfg/mpv_input.conf $(DESTDIR)/etc/mpv/input.conf

	install -D -m 0755 -T configs/profile.d/sxmo_init.sh $(DESTDIR)/etc/profile.d/sxmo_init.sh

	# Migrations
	install -D -t $(DESTDIR)$(PREFIX)/share/sxmo/migrations migrations/*

	# Bin
	install -D -t $(DESTDIR)$(PREFIX)/bin scripts/*/*

	install -D programs/sxmo_vibrate $(DESTDIR)$(PREFIX)/bin/
	install -D programs/sxmo_splitchar $(DESTDIR)$(PREFIX)/bin/

	find $(DESTDIR)$(PREFIX)/share/sxmo/default_hooks/ -type f -exec ./setup_config_version.sh "{}" \;
	find $(DESTDIR)$(PREFIX)/share/sxmo/appcfg/ -type f -exec ./setup_config_version.sh "{}" \;

	@echo "-------------------------------------------------------------------">&2
	@echo "NOTICE 1: Do not forget to add sxmo-setpermissions to your init system, e.g. for openrc: rc-update add sxmo-setpermissions default && rc-service sxmo-setpermissions start" >&2
	@echo "-------------------------------------------------------------------">&2
	@echo "NOTICE 2: After an upgrade, it is recommended you reboot and when prompted run sxmo_migrate.sh to check and upgrade your configuration files and custom hooks against the defaults (it will not make any changes unless explicitly told to)" >&2
	@echo "-------------------------------------------------------------------">&2
